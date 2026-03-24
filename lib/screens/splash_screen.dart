import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateAfterAnimation();
  }

  Future<void> _navigateAfterAnimation() async {
    // Always let the animation play for at least 2.8 seconds
    await Future.delayed(const Duration(milliseconds: 2800));
    if (!mounted) return;

    final userProvider = context.read<UserProvider>();

    // Wait for provider to finish initialising (usually instant, but guard it)
    if (!userProvider.isInitialized) {
      await Future.doWhile(() async {
        await Future.delayed(const Duration(milliseconds: 50));
        return !userProvider.isInitialized;
      });
    }

    if (!mounted) return;

    if (userProvider.isLoggedIn) {
      context.go('/home');
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Adaptive sizing — all dimensions derived from screen size
    final size = MediaQuery.sizeOf(context);
    final shortSide = size.shortestSide;

    // Logo box: 28% of shortest screen side, clamped between 100–160dp
    final logoSize = (shortSide * 0.28).clamp(100.0, 160.0);
    // Corner radius proportional to logo size
    final radius = logoSize * 0.25;
    // Font sizes relative to the shortest screen dimension
    final titleFontSize = (shortSide * 0.090).clamp(28.0, 48.0);
    final subtitleFontSize = (shortSide * 0.038).clamp(13.0, 20.0);

    final settings = context.watch<SettingsProvider>();
    final splashBg = settings.appSeedColor;

    return Scaffold(
      backgroundColor: splashBg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Spacer(flex: 3),

                // ── Logo ────────────────────────────────────────────────
                Center(
                  child:
                      Container(
                            width: logoSize,
                            height: logoSize,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(radius),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.25),
                                  blurRadius: logoSize * 0.25,
                                  offset: Offset(0, logoSize * 0.08),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                'GB',
                                style: GoogleFonts.poppins(
                                  fontSize: logoSize * 0.38,
                                  fontWeight: FontWeight.w900,
                                  color: splashBg,
                                ),
                              ),
                            ),
                          )
                          .animate()
                          .scale(duration: 600.ms, curve: Curves.elasticOut)
                          .fadeIn(duration: 400.ms),
                ),

                SizedBox(height: logoSize * 0.22),

                // ── App name ────────────────────────────────────────────
                Text(
                      'G-Bytes',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    )
                    .animate(delay: 300.ms)
                    .slideY(begin: 0.3, end: 0, duration: 500.ms)
                    .fadeIn(),

                SizedBox(height: logoSize * 0.08),

                // ── Tagline ─────────────────────────────────────────────
                Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: constraints.maxWidth * 0.12,
                      ),
                      child: Text(
                        'Fuel your brain\nwhile you fuel your gains',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: subtitleFontSize,
                          color: Colors.white.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w400,
                          height: 1.6,
                        ),
                      ),
                    )
                    .animate(delay: 500.ms)
                    .slideY(begin: 0.3, end: 0, duration: 500.ms)
                    .fadeIn(),

                const Spacer(flex: 3),

                // ── Loading indicator ────────────────────────────────────
                Padding(
                  padding: EdgeInsets.only(bottom: size.height * 0.06),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      ),
                      SizedBox(height: size.height * 0.015),
                      Text(
                        'Loading...',
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: subtitleFontSize * 0.85,
                        ),
                      ),
                    ],
                  ).animate(delay: 700.ms).fadeIn(duration: 400.ms),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
