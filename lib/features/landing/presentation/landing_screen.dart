import 'dart:ui';
import 'package:flutter/material.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic);
    _anim.forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      extendBody: true, // draw under system nav
      extendBodyBehindAppBar: true, // draw under status bar
      appBar: AppBar(
        title: Text(
          'XENCHIVE',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Info',
            onPressed: () {},
            icon: const Icon(Icons.info_outline),
          ),
        ],
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Gradient backdrop
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [const Color(0xFF0B1A30), const Color(0xFF0A0F16)]
                      : [const Color(0xFFEFF2F6), Colors.white],
                ),
              ),
            ),
          ),

          // Subtle glow orbs
          Positioned(
            top: -120,
            right: -60,
            child: _GlowOrb(
              color: isDark
                  ? const Color(0xFF3F8CFF).withOpacity(0.25)
                  : const Color(0xFFCBA135).withOpacity(0.18),
              size: 260,
            ),
          ),
          Positioned(
            bottom: -140,
            left: -80,
            child: _GlowOrb(
              color: isDark
                  ? const Color(0xFFCBA135).withOpacity(0.22)
                  : const Color(0xFF3F8CFF).withOpacity(0.18),
              size: 320,
            ),
          ),

          // Content
          SafeArea(
            top: true,
            bottom: false, // let us pad manually to avoid black gap
            child: FadeTransition(
              opacity: _fade,
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20, 12, 20, 24 + bottomInset),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),

                    // Brand Row
                    Row(
                      children: [
                        _LogoCircle(isDark: isDark),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'XENCHIVE',
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.6,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Xperience Next-Gen Centralized Higher-Institution Vault & Evidence',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      height: 1.25,
                                      color:
                                          (isDark
                                                  ? Colors.white
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

                    // Hero glass card
                    _GlassCard(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Verified portfolios. Zero chaos.',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Centralize records, verify evidence, and issue certificates with a single click.',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          height: 1.35,
                                          color: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.color
                                              ?.withOpacity(0.85),
                                        ),
                                  ),
                                  const SizedBox(height: 14),
                                  const Wrap(
                                    spacing: 10,
                                    runSpacing: 10,
                                    children: [
                                      _TagChip(
                                        icon: Icons.verified,
                                        label: 'Faculty verification',
                                      ),
                                      _TagChip(
                                        icon: Icons.photo,
                                        label: 'CSV-first uploads',
                                      ),
                                      _TagChip(
                                        icon: Icons.key,
                                        label: 'Tokenized certificates',
                                      ),
                                      _TagChip(
                                        icon: Icons.lock_clock,
                                        label: 'Audit-ready',
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.dashboard_customize_rounded,
                              size: 56,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Features carousel (scrollable)
                    SizedBox(
                      height: 152,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        children: const [
                          _FeatureCard(
                            title: 'Student Vault',
                            subtitle: 'View records • Raise tickets',
                            icon: Icons.folder_shared_rounded,
                          ),
                          _FeatureCard(
                            title: 'Leads & Faculties',
                            subtitle: 'CSV uploads • Attest claims',
                            icon: Icons.badge_rounded,
                          ),
                          _FeatureCard(
                            title: 'AI Assist',
                            subtitle: 'Auto-check & summarize',
                            icon: Icons.auto_awesome_rounded,
                          ),
                          _FeatureCard(
                            title: 'Certificates',
                            subtitle: 'Institute templates • QR verify',
                            icon: Icons.verified_rounded,
                          ),
                          _FeatureCard(
                            title: 'Audit & Logs',
                            subtitle: 'Every action, every IP',
                            icon: Icons.fact_check_rounded,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // CTA buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              backgroundColor: isDark
                                  ? const Color(0xFFCBA135) // gold
                                  : const Color(0xFF0B1A30), // midnight
                              foregroundColor: isDark
                                  ? Colors.black
                                  : Colors.white,
                              elevation: 0,
                            ),
                            onPressed: () =>
                                Navigator.of(context).pushNamed('/signup'),
                            icon: const Icon(Icons.lock_open_rounded),
                            label: const Text('Create account'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              side: BorderSide(
                                color:
                                    (isDark ? Colors.white70 : Colors.black54)
                                        .withOpacity(0.28),
                              ),
                            ),
                            onPressed: () =>
                                Navigator.of(context).pushNamed('/signin'),
                            icon: const Icon(Icons.login_rounded),
                            label: const Text('Sign in'),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Tiny footer
                    Center(
                      child: Text(
                        'By continuing, you accept our Terms & Privacy.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(
                            context,
                          ).textTheme.bodySmall?.color?.withOpacity(0.7),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ======= Mini UI pieces =======

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

class _FeatureCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  const _FeatureCard({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 240,
      margin: const EdgeInsets.only(right: 12),
      child: _GlassCard(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [const Color(0xFFCBA135), const Color(0xFF8F6C22)]
                        : [const Color(0xFF0B1A30), const Color(0xFF24324A)],
                  ),
                ),
                child: const Icon(Icons.auto_awesome, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        height: 1.25,
                        color: Theme.of(
                          context,
                        ).textTheme.bodySmall?.color?.withOpacity(0.85),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                icon,
                size: 20,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _TagChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white24 : Colors.black12),
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.white.withOpacity(0.7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text(label, style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }
}
