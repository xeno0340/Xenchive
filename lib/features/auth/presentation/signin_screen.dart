// lib/features/auth/presentation/signin_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _obscure = true;
  bool _loading = false;

  final List<String> _roles = const [
    'Student',
    'Club Lead',
    'Faculty',
    'Admin',
  ];
  String? _selectedRole;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _toast(String msg, {bool error = false}) {
    final cs = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? cs.error : cs.primary,
      ),
    );
  }

  void _navigateToDashboard(String role) {
    switch (role) {
      case 'Student':
        Navigator.pushReplacementNamed(context, '/studentDashboard');
        break;
      case 'Club Lead':
        Navigator.pushReplacementNamed(context, '/clubDashboard');
        break;
      case 'Faculty':
        Navigator.pushReplacementNamed(context, '/facultyDashboard');
        break;
      case 'Admin':
        Navigator.pushReplacementNamed(context, '/adminDashboard');
        break;
      default:
        Navigator.pop(context);
    }
  }

  Future<void> _forgotPassword() async {
    final email = _email.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _toast('Enter a valid email first.', error: true);
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      _toast('Password reset link sent to your email.');
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      _toast(e.message ?? 'Failed to send reset link', error: true);
    }
  }

  Future<void> _handleSignIn() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedRole == null) {
      _toast('Please select your role.', error: true);
      return;
    }

    setState(() => _loading = true);
    try {
      // 1) Firebase Auth sign-in
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _email.text.trim(),
        password: _password.text,
      );

      final uid = cred.user!.uid;
      final userDoc = FirebaseFirestore.instance.collection('users').doc(uid);

      // 2) Ensure profile exists (auto-create with allowed create keys only)
      var snap = await userDoc.get();
      final now = FieldValue.serverTimestamp();

      if (!snap.exists) {
        // Create with EXACT allowed keys from your rules:
        // uid, email, fullName, role, status, createdAt, lastLoginAt
        await userDoc.set({
          'uid': uid,
          'email': _email.text.trim(),
          'fullName': '', // optional but allowed on create
          'role': _selectedRole!, // role locks after creation
          'status': 'active',
          'createdAt': now,
          'lastLoginAt': now,
        }, SetOptions(merge: false));

        // Refresh snap to read stored role
        snap = await userDoc.get();
      }

      final data = snap.data()!;
      final storedRole = (data['role'] ?? '') as String;

      // 3) Enforce role-lock (deny if mismatch)
      if (storedRole != _selectedRole) {
        await FirebaseAuth.instance.signOut();
        _toast(
          'Role mismatch: this account is "$storedRole". Choose the correct role.',
          error: true,
        );
        return;
      }

      // 4) Update timestamps (updateAllowedKeys includes updatedAt & lastLoginAt) + add signin log
      await userDoc.update({'lastLoginAt': now, 'updatedAt': now});

      await userDoc.collection('logs').add({
        'type': 'signin',
        'at': now,
        'client': 'flutter',
      });

      // 5) Navigate by role
      if (!mounted) return;
      _navigateToDashboard(storedRole);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String msg;
      switch (e.code) {
        case 'user-not-found':
          msg = 'No account found for this email.';
          break;
        case 'wrong-password':
          msg = 'Incorrect password.';
          break;
        case 'invalid-email':
          msg = 'Enter a valid email address.';
          break;
        case 'network-request-failed':
          msg = 'Network error. Please try again.';
          break;
        default:
          msg = e.message ?? 'Sign in failed.';
      }
      _toast(msg, error: true);
    } on FirebaseException catch (e) {
      if (!mounted) return;
      _toast(e.message ?? 'Firestore error.', error: true);
    } catch (e) {
      if (!mounted) return;
      _toast(e.toString(), error: true);
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
        appBar: AppBar(title: const Text('Sign in'), centerTitle: true),
        body: Stack(
          children: [
            // Background gradient
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

            // Content
            SafeArea(
              top: true,
              bottom: false,
              child: Stack(
                children: [
                  SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
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
                                    'Welcome back to XENCHIVE',
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
                                    'Sign in with your institutional email',
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

                        // Form
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
                                    controller: _email,
                                    label: 'Institution Email',
                                    icon: Icons.email_outlined,
                                    keyboard: TextInputType.emailAddress,
                                    next: true,
                                    validator: (v) {
                                      if (v == null || v.isEmpty) {
                                        return 'Email is required';
                                      }
                                      if (!v.contains('@')) {
                                        return 'Enter a valid email';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 14),
                                  _filledField(
                                    context: context,
                                    controller: _password,
                                    label: 'Password',
                                    icon: Icons.lock_outline,
                                    obscure: _obscure,
                                    toggle: () =>
                                        setState(() => _obscure = !_obscure),
                                    validator: (v) {
                                      if (v == null || v.isEmpty) {
                                        return 'Password is required';
                                      }
                                      if (v.length < 6) {
                                        return 'Minimum 6 characters';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 14),
                                  _roleDropdown(context),

                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: _loading
                                          ? null
                                          : _forgotPassword,
                                      child: const Text('Forgot password?'),
                                    ),
                                  ),
                                  const SizedBox(height: 4),

                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: _loading
                                          ? null
                                          : _handleSignIn,
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
                                              height: 22,
                                              width: 22,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.4,
                                              ),
                                            )
                                          : const Text('Sign in'),
                                    ),
                                  ),
                                  const SizedBox(height: 10),

                                  Row(
                                    children: [
                                      Expanded(
                                        child: Divider(
                                          color:
                                              (isDark
                                                      ? Colors.white24
                                                      : Colors.black12)
                                                  .withOpacity(0.7),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'or',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.labelMedium,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Divider(
                                          color:
                                              (isDark
                                                      ? Colors.white24
                                                      : Colors.black12)
                                                  .withOpacity(0.7),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),

                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton(
                                      onPressed: _loading
                                          ? null
                                          : () => Navigator.pushNamed(
                                              context,
                                              '/signup',
                                            ),
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
                                      child: const Text('Create new account'),
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
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: IgnorePointer(
                      ignoring: true,
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 0),
                          child: Text(
                            'By continuing, you accept our Terms & Privacy.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.color
                                      ?.withOpacity(0.7),
                                ),
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
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboard,
    String? Function(String?)? validator,
    bool next = false,
    bool obscure = false,
    VoidCallback? toggle,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      textInputAction: next ? TextInputAction.next : TextInputAction.done,
      obscureText: obscure,
      validator: validator,
      onFieldSubmitted: next ? (_) => FocusScope.of(context).nextFocus() : null,
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
      enabled: !_loading,
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
