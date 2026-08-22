// lib/services/auth_service.dart
import 'dart:io' show Platform;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Centralized wrapper around Firebase Auth + Firestore user profiles.
/// - Auto-creates / fixes /users/{uid} on first sign-up or sign-in
/// - Enforces role-locked sign-in
/// - Provides helpers used by AuthGate (getCurrentUserRole)
/// - Optional lightweight client event logger (recordClientEvent)
class AuthService {
  AuthService._internal();
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const String usersCollection = 'users';
  static const String logsSubcollection = 'logs';

  // -------- Streams & user --------
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  Stream<User?> get idTokenChanges => _auth.idTokenChanges();
  User? get currentUser => _auth.currentUser;

  // -------- Shortcuts --------
  DocumentReference<Map<String, dynamic>> _userRef(String uid) =>
      _db.collection(usersCollection).doc(uid);

  CollectionReference<Map<String, dynamic>> _userLogsRef(String uid) =>
      _db.collection(usersCollection).doc(uid).collection(logsSubcollection);

  // ======================================================================
  // Public API
  // ======================================================================

  /// Create a new account, then create the Firestore profile.
  /// Writes only the fields allowed by your rules.
  Future<User> signUp({
    required String email,
    required String password,
    required String fullName,
    required String role, // 'Student' | 'Club Lead' | 'Faculty' | 'Admin'
    bool sendEmailVerification = false,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = cred.user!;

    // Keep Auth profile displayName in sync
    if (fullName.trim().isNotEmpty) {
      await user.updateDisplayName(fullName.trim());
    }

    // Create the profile (must match rules' createKeysOnly)
    await _createOrFixProfile(
      uid: user.uid,
      email: email.trim(),
      fullName: fullName.trim(),
      role: role,
      isFirstTime: true,
    );

    // Optional verification email
    if (sendEmailVerification && !user.emailVerified) {
      await user.sendEmailVerification();
    }

    // Optional lightweight signup log
    await recordClientEvent('signup');

    return user;
  }

  /// Sign in, ensure the profile exists/is valid, enforce role lock.
  Future<User> signIn({
    required String email,
    required String password,
    required String role,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = cred.user!;

    // If user doc missing or incomplete, create/fix it now.
    await _createOrFixProfile(
      uid: user.uid,
      email: user.email ?? email.trim(),
      fullName: user.displayName ?? '',
      role: role,
      isFirstTime: false,
    );

    // Re-read to enforce role-locked sign in
    final snap = await _userRef(user.uid).get();
    final data = snap.data() ?? {};
    final savedRole = data['role'] as String?;
    if (savedRole == null) {
      await _auth.signOut();
      throw FirebaseAuthException(
        code: 'profile-incomplete',
        message: 'Profile incomplete. Contact support.',
      );
    }
    if (savedRole != role) {
      await _auth.signOut();
      throw FirebaseAuthException(
        code: 'role-mismatch',
        message:
            'This account is registered as "$savedRole". Please sign in with that role.',
      );
    }

    // Sync displayName from Firestore if missing in Auth
    final fullName = (data['fullName'] as String?)?.trim() ?? '';
    if ((user.displayName == null || user.displayName!.isEmpty) &&
        fullName.isNotEmpty) {
      await user.updateDisplayName(fullName);
    }

    // Allowed by rules (owner update without changing role)
    await _userRef(user.uid).set({
      'updatedAt': FieldValue.serverTimestamp(),
      'lastLoginAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // Optional lightweight signin log
    await recordClientEvent('signin');

    return user;
  }

  Future<void> signOut() => _auth.signOut();

  Future<void> resetPassword(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  /// Update display name across Auth & Firestore (allowed by rules).
  Future<void> updateDisplayName(String fullName) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final name = fullName.trim();
    if (name.isEmpty) return;

    await user.updateDisplayName(name);
    await _userRef(user.uid).set({
      'fullName': name,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Return role for given uid (used by AuthGate).
  Future<String?> getUserRole(String uid) async {
    final snap = await _userRef(uid).get();
    return (snap.data() ?? const {})['role'] as String?;
  }

  /// Return role of the currently signed-in user (used by AuthGate).
  Future<String?> getCurrentUserRole() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    return getUserRole(uid);
  }

  /// Optional tiny logger to /users/{uid}/logs
  Future<void> recordClientEvent(
    String type, {
    Map<String, dynamic>? extra,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _userLogsRef(uid).add({
      'type': type,
      'ts': FieldValue.serverTimestamp(),
      'platform': _platformString,
      if (extra != null) ...extra,
    });
  }

  // ======================================================================
  // Internal helpers
  // ======================================================================

  /// Creates the profile if missing; if it exists but role is missing,
  /// sets the role (allowed by your rules when previous role was null).
  /// On CREATE we only write fields allowed by your rules:
  ///   uid, email, fullName, role, createdAt, lastLoginAt, status
  Future<void> _createOrFixProfile({
    required String uid,
    required String email,
    required String fullName,
    required String role,
    required bool isFirstTime,
  }) async {
    final ref = _userRef(uid);
    final snap = await ref.get();

    if (!snap.exists) {
      await ref.set({
        'uid': uid,
        'email': email,
        'fullName': fullName,
        'role': role, // must be one of the allowed roles
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: false));
      return;
    }

    final data = snap.data() ?? {};
    final savedRole = data['role'];

    // If role missing (null or empty), set it once.
    if (savedRole == null || (savedRole is String && savedRole.isEmpty)) {
      await ref.set({
        'role': role,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    // other timestamps are handled by callers
    if (!isFirstTime) {
      // no-op here
    }
  }

  String get _platformString {
    try {
      if (Platform.isAndroid) return 'android';
      if (Platform.isIOS) return 'ios';
      if (Platform.isMacOS) return 'macos';
      if (Platform.isWindows) return 'windows';
      if (Platform.isLinux) return 'linux';
    } catch (_) {}
    return 'unknown';
  }
}
