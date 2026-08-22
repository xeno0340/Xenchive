// lib/features/auth/presentation/signup_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _fullName = TextEditingController();

  bool _obscure1 = true;
  bool _obscure2 = true;
  bool _accepted = false;
  bool _loading = false;

  final List<String> _roles = const [
    'Student',
    'Club Lead',
    'Faculty',
    'Admin',
  ];
  String? _selectedRole;

  // Keep last attempted payload for debugging inside catch
  Map<String, dynamic>? _lastSignupPayload;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    _fullName.dispose();
    super.dispose();
  }

  void _toast(String msg, {bool isError = false}) {
    final cs = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? cs.error : cs.primary,
      ),
    );
  }

  void _goToRoleHome(String role) {
    switch (role) {
      case 'Student':
        Navigator.pushReplacementNamed(context, '/studentDashboard');
        return;
      case 'Club Lead':
        Navigator.pushReplacementNamed(context, '/clubDashboard');
        return;
      case 'Faculty':
        Navigator.pushReplacementNamed(context, '/facultyDashboard');
        return;
      case 'Admin':
        Navigator.pushReplacementNamed(context, '/adminDashboard');
        return;
      default:
        Navigator.pop(context);
    }
  }

  Future<void> _createAccount() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_selectedRole == null) {
      _toast('Please select your role.', isError: true);
      return;
    }
    if (!_accepted) {
      _toast('Please accept Terms & Privacy to continue.', isError: true);
      return;
    }

    setState(() => _loading = true);
    try {
      // 1) Create Firebase Auth user
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _email.text.trim(),
        password: _password.text,
      );

      final uid = cred.user!.uid;
      final now = FieldValue.serverTimestamp();

      // 2) EXACT profile payload (must match Firestore rules)
      final profile = <String, dynamic>{
        'uid': uid,
        'email': _email.text.trim(),
        'fullName': _fullName.text.trim(), // optional but allowed on create
        'role': _selectedRole!, // locked by rules after creation
        'status': 'active',
        'createdAt': now,
        'lastLoginAt': now,
      };
      _lastSignupPayload = Map<String, dynamic>.from(profile);

      // 3) Write /users/{uid} with NO extra keys and NO merge
      final userDoc = FirebaseFirestore.instance.collection('users').doc(uid);
      await userDoc.set(profile, SetOptions(merge: false));

      // 4) Lightweight signup log
      await userDoc.collection('logs').add({
        'type': 'signup',
        'at': now,
        'client': 'flutter',
      });

      // 5) Already signed in → route by role
      if (!mounted) return;
      _toast('Account created successfully');
      _goToRoleHome(_selectedRole!);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String msg;
      switch (e.code) {
        case 'email-already-in-use':
          msg = 'That email is already in use.';
          break;
        case 'invalid-email':
          msg = 'Please enter a valid email address.';
          break;
        case 'weak-password':
          msg = 'Password is too weak (min 6 characters).';
          break;
        case 'network-request-failed':
          msg = 'Network error. Check connection and try again.';
          break;
        default:
          msg = e.message ?? e.code;
      }
      _toast(msg, isError: true);
    } on FirebaseException catch (e) {
      // Common: permission-denied if keys mismatch rules
      if (!mounted) return;
      _toast(
        e.message ?? 'Firestore write failed (check rules & keys).',
        isError: true,
      );
      // Debug tip
      // ignore: avoid_print
      print('Signup profile payload => ${_lastSignupPayload ?? {}}');
    } catch (e) {
      if (!mounted) return;
      _toast('Unexpected error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: (isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
          .copyWith(
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: Colors.transparent,
            systemNavigationBarDividerColor: Colors.transparent,
            systemNavigationBarContrastEnforced: false,
          ),
      child: Scaffold(
        extendBody: true,
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text('Create Account'), centerTitle: true),
        body: Stack(
          children: [
            // Background
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? const [Color(0xFF0B1A30), Color(0xFF0A0F16)]
                        : const [Color(0xFFEFF2F6), Colors.white],
                  ),
                ),
              ),
            ),
            // Glow orbs
            Positioned(
              top: -120,
              right: -70,
              child: _GlowOrb(
                size: 260,
                color: isDark
                    ? const Color(0xFF3F8CFF).withOpacity(0.25)
                    : const Color(0xFFCBA135).withOpacity(0.18),
              ),
            ),
            Positioned(
              bottom: -160,
              left: -90,
              child: _GlowOrb(
                size: 320,
                color: isDark
                    ? const Color(0xFFCBA135).withOpacity(0.22)
                    : const Color(0xFF3F8CFF).withOpacity(0.18),
              ),
            ),

            SafeArea(
              top: true,
              bottom: false,
              child: Stack(
                children: [
                  SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          children: [
                            _LogoCircle(isDark: isDark),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Let’s get started",
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.5,
                                        ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    "Create your XENCHIVE account using institutional email",
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color:
                                              (isDark
                                                      ? Colors.white70
                                                      : Colors.black87)
                                                  .withOpacity(0.75),
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),

                        // Form card
                        _GlassCard(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                            child: Form(
                              key: _formKey,
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              child: Column(
                                children: [
                                  _filledField(
                                    context: context,
                                    controller: _fullName,
                                    label: 'Full name (optional)',
                                    icon: Icons.person_outline_rounded,
                                    next: true,
                                    enabled: !_loading,
                                  ),
                                  const SizedBox(height: 14),
                                  _filledField(
                                    context: context,
                                    controller: _email,
                                    label: 'Institution Email',
                                    icon: Icons.email_outlined,
                                    keyboard: TextInputType.emailAddress,
                                    next: true,
                                    enabled: !_loading,
                                    validator: (v) {
                                      if (v == null || v.isEmpty)
                                        return 'Email is required';
                                      if (!v.contains('@'))
                                        return 'Enter a valid email';
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 14),
                                  _filledField(
                                    context: context,
                                    controller: _password,
                                    label: 'Password',
                                    icon: Icons.lock_outline,
                                    obscure: _obscure1,
                                    toggle: () =>
                                        setState(() => _obscure1 = !_obscure1),
                                    next: true,
                                    enabled: !_loading,
                                    validator: (v) {
                                      if (v == null || v.isEmpty)
                                        return 'Password is required';
                                      if (v.length < 6)
                                        return 'Minimum 6 characters';
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 14),
                                  _filledField(
                                    context: context,
                                    controller: _confirm,
                                    label: 'Confirm password',
                                    icon: Icons.lock_outline,
                                    obscure: _obscure2,
                                    toggle: () =>
                                        setState(() => _obscure2 = !_obscure2),
                                    enabled: !_loading,
                                    validator: (v) {
                                      if (v == null || v.isEmpty)
                                        return 'Confirm your password';
                                      if (v != _password.text)
                                        return 'Passwords do not match';
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 14),
                                  _roleDropdown(context),
                                  const SizedBox(height: 8),

                                  // Terms
                                  Row(
                                    children: [
                                      Checkbox(
                                        value: _accepted,
                                        onChanged: _loading
                                            ? null
                                            : (v) => setState(
                                                () => _accepted = v ?? false,
                                              ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          'I agree to the Terms & Privacy Policy',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodySmall,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),

                                  // Create account button
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: _loading
                                          ? null
                                          : _createAccount,
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 14,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                        elevation: 0,
                                      ),
                                      child: _loading
                                          ? const SizedBox(
                                              height: 20,
                                              width: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation(
                                                      Colors.white,
                                                    ),
                                              ),
                                            )
                                          : const Text('Create account'),
                                    ),
                                  ),
                                  const SizedBox(height: 10),

                                  // Back
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton(
                                      onPressed: _loading
                                          ? null
                                          : () => Navigator.pop(context),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 14,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                      ),
                                      child: const Text('Back to Sign in'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Footer
                  Positioned(
                    bottom: 20,
                    left: 0,
                    right: 0,
                    child: IgnorePointer(
                      ignoring: true,
                      child: Center(
                        child: Text(
                          'We never share your data with third parties.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).textTheme.bodySmall?.color?.withOpacity(0.7),
                              ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _roleDropdown(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DropdownButtonFormField<String>(
      value: _selectedRole,
      items: _roles
          .map((r) => DropdownMenuItem<String>(value: r, child: Text(r)))
          .toList(),
      onChanged: _loading ? null : (v) => setState(() => _selectedRole = v),
      validator: (v) => v == null ? 'Please select your role' : null,
      decoration: InputDecoration(
        labelText: 'Select Role',
        prefixIcon: const Icon(Icons.badge_outlined),
        filled: true,
        fillColor: isDark
            ? Colors.white.withOpacity(0.03)
            : Colors.white.withOpacity(0.85),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dropdownColor: isDark ? const Color(0xFF0F1622) : Colors.white,
    );
  }

  Widget _filledField({
    required BuildContext context,
    required TextEditingController controller, // ✅ fixed type
    required String label,
    required IconData icon,
    TextInputType? keyboard,
    String? Function(String?)? validator,
    bool next = false,
    bool obscure = false,
    VoidCallback? toggle,
    bool enabled = true,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboard,
      textInputAction: next ? TextInputAction.next : TextInputAction.done,
      obscureText: obscure,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixIcon: toggle == null
            ? null
            : IconButton(
                tooltip: obscure ? 'Show' : 'Hide',
                onPressed: toggle,
                icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
              ),
        filled: true,
        fillColor: isDark
            ? Colors.white.withOpacity(0.03)
            : Colors.white.withOpacity(0.85),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

// --- Shared small widgets ---
class _GlowOrb extends StatelessWidget {
  final double size;
  final Color color;
  const _GlowOrb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withOpacity(0.0)]),
      ),
    );
  }
}

class _LogoCircle extends StatelessWidget {
  final bool isDark;
  const _LogoCircle({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final border = isDark ? Colors.white24 : Colors.black12;
    final fill = isDark ? const Color(0xFF0F1622) : Colors.white;
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: border),
        color: fill.withOpacity(0.8),
      ),
      child: const Center(child: Icon(Icons.school_rounded)),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: isDark ? Colors.white10 : Colors.white.withOpacity(0.7),
            border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.35 : 0.08),
                blurRadius: 20,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
