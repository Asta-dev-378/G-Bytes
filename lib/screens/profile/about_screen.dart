import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _particleCtrl;

  @override
  void initState() {
    super.initState();
    _particleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _particleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'About G-Bytes',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // ── Background animated particles ──
          AnimatedBuilder(
            animation: _particleCtrl,
            builder: (context2, child) => CustomPaint(
              painter: _AboutParticlePainter(_particleCtrl.value),
              size: MediaQuery.sizeOf(context),
            ),
          ),

          // ── Content ──
          SingleChildScrollView(
            padding: const EdgeInsets.only(
              top: 100,
              left: 24,
              right: 24,
              bottom: 40,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Logo / Icon
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      colors: [Color(0xFFFF8C00), Color(0xFFFFB347)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF8C00).withValues(alpha: 0.5),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      'G',
                      style: GoogleFonts.russoOne(
                        fontSize: 52,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),

                const SizedBox(height: 20),

                // App Name
                Text(
                  'G-Bytes',
                  style: GoogleFonts.russoOne(
                    fontSize: 36,
                    color: Colors.white,
                    letterSpacing: 3,
                    shadows: [
                      Shadow(
                        color: const Color(0xFFFF8C00).withValues(alpha: 0.8),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                ).animate(delay: 100.ms).fadeIn().slideY(begin: 0.2),

                const SizedBox(height: 6),

                // Version
                Text(
                  'Version 1.0.0 — Build 2026',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.white38,
                    letterSpacing: 0.5,
                  ),
                ).animate(delay: 150.ms).fadeIn(),

                const SizedBox(height: 36),

                // Description Card
                const _GlassCard(
                  icon: Icons.bolt_rounded,
                  iconColor: Color(0xFFFF8C00),
                  title: 'What is G-Bytes?',
                  body:
                      'G-Bytes is your ultimate cognitive growth companion, designed to sharpen your mind through scientifically-backed brain games, focused interval training, and a curated knowledge system.\n\nEach session is crafted to challenge your memory, logic, reaction time, and emotional resilience — all in a distraction-free, beautifully designed experience.',
                ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.15),

                const SizedBox(height: 16),

                // Core Features
                const _GlassCard(
                  icon: Icons.star_rounded,
                  iconColor: Color(0xFF00E5FF),
                  title: 'Core Features',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FeatureRow(
                        '🧠',
                        'Brain Games',
                        'Memory, Schulte, Stroop, Logic & Math',
                      ),
                      _FeatureRow(
                        '⏱️',
                        'G-Timer',
                        'Work/Rest rounds with immersive animations',
                      ),
                      _FeatureRow(
                        '🎵',
                        'G-Tunes',
                        'Your personal focus music library',
                      ),
                      _FeatureRow(
                        '💡',
                        'Did You Know?',
                        'Daily knowledge push from the universe',
                      ),
                      _FeatureRow(
                        '🏆',
                        'League System',
                        'Earn points and climb the ranks',
                      ),
                    ],
                  ),
                ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.15),

                const SizedBox(height: 16),

                // Future Improvements
                const _GlassCard(
                  icon: Icons.rocket_launch_rounded,
                  iconColor: Color(0xFFFF4081),
                  title: 'Coming Soon ✨',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FutureRow(
                        '📊',
                        'Advanced Progress Analytics',
                        'Track cognitive growth over weeks and months',
                      ),
                      _FutureRow(
                        '🌐',
                        'Social Leagues',
                        'Compete with friends and global players in real-time',
                      ),
                      _FutureRow(
                        '🔤',
                        'Vocabulary Builder',
                        'Expand your language with daily word challenges',
                      ),
                      _FutureRow(
                        '🧩',
                        'Spatial Reasoning Game',
                        'Test and improve 3D thinking skills',
                      ),
                      _FutureRow(
                        '🤖',
                        'AI-Driven Plans',
                        'Personalized cognitive workout routines powered by AI',
                      ),
                      _FutureRow(
                        '🌙',
                        'Wind-Down Mode',
                        'Relaxation routines with guided breathing',
                      ),
                    ],
                  ),
                ).animate(delay: 400.ms).fadeIn().slideY(begin: 0.15),

                const SizedBox(height: 16),

                // Credits
                const _GlassCard(
                  icon: Icons.favorite_rounded,
                  iconColor: Color(0xFFFF4081),
                  title: 'Made With ❤️',
                  body:
                      'G-Bytes is built with Flutter and powered by a passion for human potential. Every feature is designed to make your mind stronger, one byte at a time.',
                ).animate(delay: 500.ms).fadeIn().slideY(begin: 0.15),

                const SizedBox(height: 32),

                Text(
                  '© 2026 G-Bytes. All rights reserved.',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.white24,
                  ),
                ).animate(delay: 600.ms).fadeIn(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Glass Card Widget ──────────────────────────────────────────────
class _GlassCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? body;
  final Widget? child;

  const _GlassCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.body,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: Colors.white.withValues(alpha: 0.05),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: iconColor.withValues(alpha: 0.15),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (body != null)
            Text(
              body!,
              style: GoogleFonts.poppins(
                fontSize: 13.5,
                color: Colors.white60,
                height: 1.7,
              ),
            ),
          ?child,
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;

  const _FeatureRow(this.emoji, this.title, this.subtitle);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.white54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FutureRow extends StatelessWidget {
  final String emoji;
  final String title;
  final String desc;

  const _FutureRow(this.emoji, this.title, this.desc);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.white.withValues(alpha: 0.07),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 17)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    color: Colors.white.withValues(alpha: 0.4),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Particle Background Painter ─────────────────────────────────
class _AboutParticlePainter extends CustomPainter {
  final double progress;
  _AboutParticlePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(12);
    const count = 50;
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < count; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final r = 0.5 + rng.nextDouble() * 2;
      final twinkle = (sin(progress * pi * 2 + i * 0.7) + 1) / 2;
      final opacity = 0.05 + twinkle * 0.2;
      paint.color = const Color(
        0xFFFF8C00,
      ).withValues(alpha: opacity * (rng.nextDouble() * 0.5 + 0.5));
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _AboutParticlePainter old) =>
      old.progress != progress;
}
