import 'dart:math';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:untitled/core/services/session_storage.dart';
import 'package:untitled/features/auth/log_in/view/LoginPage.dart';
import 'package:untitled/features/shell/view/shell_page.dart';
import '../../../core/theme/app_colors.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with TickerProviderStateMixin {
  // ── Reveal state ─────────────────────────────────────────────────────────────
  bool _logoVisible = false;
  bool _titleVisible = false;
  bool _subtitleVisible = false;
  double _logoSize = 70.0;

  // ── Continuous animation controllers ─────────────────────────────────────────
  late final AnimationController _starController;
  late final AnimationController _floatController;
  late final Animation<double> _floatAnim;

  @override
  void initState() {
    super.initState();

    _starController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );

    _floatAnim = CurvedAnimation(
      parent: _floatController,
      curve: Curves.easeInOut,
    );

    _runSequence();
  }

  Future<void> _runSequence() async {
    // Check session concurrently with the animation so there's no extra delay.
    final sessionFuture = _resolveDestination();

    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    setState(() {
      _logoVisible = true;
      _logoSize = 110.0;
    });

    await Future.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;
    setState(() => _titleVisible = true);

    await Future.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;
    setState(() => _subtitleVisible = true);

    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    _floatController.repeat(reverse: true);

    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    final goToShell = await sessionFuture;
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => goToShell ? const ShellPage() : LoginPage(),
      ),
    );
  }

  /// Returns true when Supabase has an active session whose token hash
  /// matches the value stored in SharedPreferences.
  Future<bool> _resolveDestination() async {
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) {
        await SessionStorage.clear(); // remove any stale hash
        return false;
      }
      return await SessionStorage.verify(session.accessToken);
    } catch (_) {
      return false;
    }
  }

  @override
  void dispose() {
    _starController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
      isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Animated star field ─────────────────────────────────────────────
          AnimatedBuilder(
            animation: _starController,
            builder: (_, _) => CustomPaint(
              painter: _StarPainter(_starController.value),
            ),
          ),

          // ── Center content ──────────────────────────────────────────────────
          Center(
            child: AnimatedBuilder(
              animation: _floatAnim,
              builder: (_, child) => Transform.translate(
                offset: Offset(0, (_floatAnim.value - 0.5) * 10),
                child: child,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Logo ───────────────────────────────────────────────────
                  AnimatedBuilder(
                    animation: _floatAnim,
                    builder: (_, child) => DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(26),
                        boxShadow: _logoVisible
                            ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(
                              alpha: 0.12 + _floatAnim.value * 0.18,
                            ),
                            blurRadius: 28 + _floatAnim.value * 16,
                            spreadRadius: 2 + _floatAnim.value * 4,
                          ),
                        ]
                            : const [],
                      ),
                      child: child!,
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.easeOutBack,
                      width: _logoSize,
                      height: _logoSize,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurface
                            : AppColors.lightSurface,
                        borderRadius:
                        BorderRadius.circular(_logoVisible ? 26 : 14),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.25),
                          width: 1,
                        ),
                      ),
                      padding: const EdgeInsets.all(14),
                      child: AnimatedOpacity(
                        opacity: _logoVisible ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 700),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.logoGradientStart,
                                AppColors.logoGradientEnd,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 36),

                  // ── Title ──────────────────────────────────────────────────
                  AnimatedOpacity(
                    opacity: _titleVisible ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 700),
                    child: AnimatedSlide(
                      offset:
                      _titleVisible ? Offset.zero : const Offset(0, 0.25),
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.easeOut,
                      child: Text(
                        'A U R A',
                        style: Theme.of(context).textTheme.displayLarge,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Bottom tagline ─────────────────────────────────────────────────
          Positioned(
            bottom: 64,
            left: 0,
            right: 0,
            child: AnimatedOpacity(
              opacity: _subtitleVisible ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 900),
              child: Text(
                'DESIGNED FOR THE FUTURE',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Star painter ──────────────────────────────────────────────────────────────

class _StarPainter extends CustomPainter {
  const _StarPainter(this.animValue);

  final double animValue;

  static const List<(double, double)> _positions = [
    (0.10, 0.12),
    (0.88, 0.07),
    (0.05, 0.38),
    (0.93, 0.28),
    (0.18, 0.62),
    (0.82, 0.52),
    (0.28, 0.04),
    (0.72, 0.10),
    (0.22, 0.82),
    (0.78, 0.77),
    (0.48, 0.03),
    (0.62, 0.92),
    (0.52, 0.18),
    (0.38, 0.70),
    (0.74, 0.42),
    (0.06, 0.53),
    (0.94, 0.60),
    (0.57, 0.88),
    (0.24, 0.33),
    (0.66, 0.22),
    (0.42, 0.95),
    (0.15, 0.47),
    (0.85, 0.85),
    (0.33, 0.15),
    (0.50, 0.50),
    (0.70, 0.65),
    (0.12, 0.90),
    (0.90, 0.45),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < _positions.length; i++) {
      final (x, y) = _positions[i];

      final phase = i * 0.65;
      final amplitude = 2.0 + (i % 3) * 1.5;
      final radius = 0.8 + (i % 3) * 0.3;
      final opacity = 0.20 + (i % 4) * 0.07;

      final offsetY = sin(animValue * 2 * pi + phase) * amplitude;

      canvas.drawCircle(
        Offset(x * size.width, y * size.height + offsetY),
        radius,
        Paint()..color = Colors.white.withValues(alpha: opacity),
      );
    }
  }

  @override
  bool shouldRepaint(_StarPainter oldDelegate) {
    return oldDelegate.animValue != animValue;
  }
}