// splash_screen.dart
// Thunder splash: hexagon + thunder web + bolt icon.
// On tap → slides up revealing the app (or name-entry for first-timers).

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/settings_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Hexagon draw-in
  late AnimationController _hexCtrl;
  late Animation<double>   _hexDraw;

  // Thunder web fade
  late AnimationController _webCtrl;
  late Animation<double>   _webAlpha;

  // Icon reveal
  late AnimationController _iconCtrl;
  late Animation<double>   _iconScale;
  late Animation<double>   _iconOpacity;

  // "Tap to enter" pulse
  late AnimationController _tapCtrl;

  // Slide-up on tap
  late AnimationController _slideCtrl;
  late Animation<Offset>   _slideOffset;
  late Animation<double>   _slideFade;

  bool _readyToNavigate = false;
  bool _tapped          = false;

  @override
  void initState() {
    super.initState();

    _hexCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
    _hexDraw = CurvedAnimation(parent: _hexCtrl, curve: Curves.easeInOut);

    _webCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _webAlpha = CurvedAnimation(parent: _webCtrl, curve: Curves.easeOut);

    _iconCtrl    = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _iconScale   = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _iconCtrl, curve: Curves.elasticOut));
    _iconOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _iconCtrl, curve: Curves.easeOut));

    _tapCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))
      ..repeat(reverse: true);

    _slideCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _slideOffset = Tween<Offset>(begin: Offset.zero, end: const Offset(0, -1.0))
        .animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeInCubic));
    _slideFade   = Tween<double>(begin: 1.0, end: 0.0)
        .animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeIn));

    _runSequence();
  }

  Future<void> _runSequence() async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    await _hexCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 150));
    if (!mounted) return;
    _webCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    await _iconCtrl.forward();
    if (!mounted) return;
    setState(() => _readyToNavigate = true);
  }

  Future<void> _onTap() async {
    if (!_readyToNavigate || _tapped) return;
    setState(() => _tapped = true);
    HapticFeedback.lightImpact();

    final user = context.read<UserProvider>();

    // Slide the splash up
    await _slideCtrl.forward();
    if (!mounted) return;

    // First-timer: go to name entry; returning user: go home or login
    if (!user.isInitialized) {
      await Future.doWhile(() async {
        await Future.delayed(const Duration(milliseconds: 50));
        return !user.isInitialized;
      });
    }
    if (!mounted) return;

    if (user.isLoggedIn) {
      context.go('/home');
    } else {
      context.go('/login');
    }
  }

  @override
  void dispose() {
    _hexCtrl.dispose();
    _webCtrl.dispose();
    _iconCtrl.dispose();
    _tapCtrl.dispose();
    _slideCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = context.watch<SettingsProvider>().appSeedColor;
    final size   = MediaQuery.sizeOf(context);

    return GestureDetector(
      onTap: _onTap,
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0A0A),
        body: AnimatedBuilder(
          animation: Listenable.merge([
            _hexDraw, _webAlpha, _iconScale, _tapCtrl, _slideCtrl,
          ]),
          builder: (context, _) {
            return SlideTransition(
              position: _slideOffset,
              child: FadeTransition(
                opacity: _slideFade,
                child: Stack(
                  children: [
                    // ── Hexagon + web + icon (centred) ──────────────
                    Center(
                      child: SizedBox(
                        width: 260,
                        height: 260,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Hex outline
                            CustomPaint(
                              size: const Size(260, 260),
                              painter: _HexOutlinePainter(
                                drawProgress: _hexDraw.value,
                                accent: accent,
                              ),
                            ),
                            // Thunder web
                            Opacity(
                              opacity: _webAlpha.value,
                              child: CustomPaint(
                                size: const Size(260, 260),
                                painter: _ThunderWebPainter(accent: accent),
                              ),
                            ),
                            // Bolt icon
                            Opacity(
                              opacity: _iconOpacity.value,
                              child: Transform.scale(
                                scale: _iconScale.value,
                                child: Container(
                                  width: 82, height: 82,
                                  decoration: BoxDecoration(
                                    color: accent,
                                    borderRadius: BorderRadius.circular(22),
                                    boxShadow: [
                                      BoxShadow(
                                        color: accent.withAlpha(130),
                                        blurRadius: 36,
                                        spreadRadius: 4,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.bolt_rounded,
                                    color: Colors.white,
                                    size: 48,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ── App name ────────────────────────────────────
                    Positioned(
                      bottom: size.height * 0.2,
                      left: 0, right: 0,
                      child: Opacity(
                        opacity: _iconOpacity.value,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.bolt_rounded, color: accent, size: 26),
                            const SizedBox(width: 4),
                            Text(
                              'G-Bytes',
                              style: GoogleFonts.poppins(
                                fontSize: 30,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ── "Tap to enter" pulse ─────────────────────────
                    if (_readyToNavigate && !_tapped)
                      Positioned(
                        bottom: size.height * 0.10,
                        left: 0, right: 0,
                        child: Opacity(
                          opacity: 0.45 + _tapCtrl.value * 0.55,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.touch_app_rounded, color: accent, size: 17),
                              const SizedBox(width: 8),
                              Text(
                                'TAP TO ENTER',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: accent,
                                  letterSpacing: 2.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HEXAGON OUTLINE — lightning-drawn edges
// ─────────────────────────────────────────────────────────────────────────────

class _HexOutlinePainter extends CustomPainter {
  final double drawProgress;
  final Color  accent;

  const _HexOutlinePainter({required this.drawProgress, required this.accent});

  static List<Offset> _hexCorners(Offset center, double r) {
    return List.generate(6, (i) {
      final angle = -math.pi / 2 + i * math.pi / 3;
      return Offset(center.dx + r * math.cos(angle),
                    center.dy + r * math.sin(angle));
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center  = Offset(size.width / 2, size.height / 2);
    final corners = _hexCorners(center, 118);
    const nSides  = 6;

    for (int s = 0; s < nSides; s++) {
      final segStart = s / nSides;
      final segEnd   = (s + 1) / nSides;
      final frac = ((drawProgress - segStart) / (segEnd - segStart)).clamp(0.0, 1.0);
      if (frac <= 0) continue;

      final from = corners[s];
      final to   = corners[(s + 1) % nSides];
      final tip  = Offset.lerp(from, to, frac)!;

      // Glow
      canvas.drawLine(from, tip, Paint()
        ..color = accent.withAlpha(55)
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));

      // Core
      canvas.drawLine(from, tip, Paint()
        ..color = Colors.white.withAlpha((200 * frac).round())
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round);

      // Tip spark
      canvas.drawCircle(tip, 5.5 * frac, Paint()
        ..color = Colors.white.withAlpha((220 * frac).round())
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
    }
  }

  @override
  bool shouldRepaint(_HexOutlinePainter old) =>
      old.drawProgress != drawProgress;
}

// ─────────────────────────────────────────────────────────────────────────────
// THUNDER WEB — interconnected nodes inside the hexagon
// ─────────────────────────────────────────────────────────────────────────────

class _ThunderWebPainter extends CustomPainter {
  final Color accent;
  const _ThunderWebPainter({required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    final nodes = <Offset>[
      Offset(cx, cy),
      ...List.generate(6, (i) {
        final angle = -math.pi / 2 + i * math.pi / 3;
        return Offset(cx + 58 * math.cos(angle), cy + 58 * math.sin(angle));
      }),
      ...List.generate(6, (i) {
        final angle = -math.pi / 2 + (i + 0.5) * math.pi / 3;
        return Offset(cx + 90 * math.cos(angle), cy + 90 * math.sin(angle));
      }),
    ];

    final edges = [
      [0,1],[0,2],[0,3],[0,4],[0,5],[0,6],
      [1,7],[2,8],[3,9],[4,10],[5,11],[6,12],
      [1,2],[2,3],[3,4],[4,5],[5,6],[6,1],
    ];

    for (final e in edges) {
      final a = nodes[e[0]];
      final b = nodes[e[1]];
      canvas.drawLine(a, b, Paint()
        ..color = accent.withAlpha(28)
        ..strokeWidth = 5
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
      canvas.drawLine(a, b, Paint()
        ..color = accent.withAlpha(70)
        ..strokeWidth = 0.9
        ..strokeCap = StrokeCap.round);
    }

    for (int i = 0; i < nodes.length; i++) {
      final r = i == 0 ? 5.0 : 3.0;
      canvas.drawCircle(nodes[i], r, Paint()
        ..color = accent.withAlpha(150)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
      canvas.drawCircle(nodes[i], r * 0.5,
        Paint()..color = Colors.white.withAlpha(200));
    }
  }

  @override
  bool shouldRepaint(_ThunderWebPainter old) => false;
}
