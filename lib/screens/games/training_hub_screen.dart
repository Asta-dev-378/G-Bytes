import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/game_provider.dart';

import 'memory_game_screen.dart';
import 'logic_game_screen.dart';
import 'math_sprint_screen.dart';
import 'schulte_game_screen.dart';
import 'stroop_game_screen.dart';

class TrainingHubScreen extends StatelessWidget {
  const TrainingHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Brain Training')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress overview
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: isDark
                    ? const LinearGradient(
                        colors: [Color(0xFF6C63FF), Color(0xFF20BC68)],
                      )
                    : const LinearGradient(
                        colors: [Color(0xFFFF8C00), Color(0xFFFFB347)],
                      ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Daily Training',
                          style: GoogleFonts.poppins(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          'Level ${game.level} / ${game.totalLevels}',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: game.level / game.totalLevels,
                            backgroundColor: Colors.white30,
                            valueColor: const AlwaysStoppedAnimation(
                              Colors.white,
                            ),
                            minHeight: 8,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    children: [
                      Text(
                        '${game.totalPoints}',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        'Points',
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn().slideY(begin: 0.2),
            const SizedBox(height: 28),
            Text(
              'Choose Game',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            _GameCard(
              icon: '🧠',
              title: 'Memory Game',
              description: 'Memorize blinking tiles — levels get harder!',
              color: isDark ? Colors.orangeAccent : const Color(0xFFFF8C00),
              delay: 100,
              badge: game.memoryHighScore > 0
                  ? '🏆 ${game.memoryHighScore}'
                  : null,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MemoryGameScreen()),
              ),
            ),
            const SizedBox(height: 14),
            _GameCard(
              icon: '🔷',
              title: 'Logic Game',
              description: '7 series types — arithmetic, Fibonacci, primes…',
              color: isDark ? const Color(0xFF6C63FF) : const Color(0xFF6C63FF),
              delay: 200,
              badge: game.logicHighScore > 0
                  ? '🏆 ${game.logicHighScore}'
                  : null,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LogicGameScreen()),
              ),
            ),
            const SizedBox(height: 14),
            _GameCard(
              icon: '⚡',
              title: 'Math Sprint',
              description: 'Solve equations as fast as you can in 60s!',
              color: isDark ? const Color(0xFF20BC68) : const Color(0xFF20BC68),
              delay: 300,
              badge: game.mathHighScore > 0 ? '🏆 ${game.mathHighScore}' : null,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MathSprintScreen()),
              ),
            ),
            const SizedBox(height: 14),
            _GameCard(
              icon: '🔢',
              title: 'Schulte Table',
              description: 'Find numbers 1→N in order as fast as possible',
              color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF00BCD4),
              delay: 400,
              badge: game.schulteHighScore > 0
                  ? '⏱ ${game.schulteHighScore}s'
                  : null,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SchulteGameScreen()),
              ),
            ),
            const SizedBox(height: 14),
            _GameCard(
              icon: '🎨',
              title: 'Stroop Effect',
              description: 'Tap the INK color, not what the word says!',
              color: isDark ? const Color(0xFFD500F9) : const Color(0xFF8E24AA),
              delay: 500,
              badge: game.stroopHighScore > 0
                  ? '🏆 ${game.stroopHighScore}'
                  : null,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StroopGameScreen()),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  final String icon;
  final String title;
  final String description;
  final Color color;
  final int delay;
  final VoidCallback onTap;
  final String? badge;

  const _GameCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.delay,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: color.withAlpha(30),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: color.withAlpha(30),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Center(
                    child: Text(icon, style: const TextStyle(fontSize: 26)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          if (badge != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: color.withAlpha(25),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                badge!,
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: color,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        description,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.play_circle_filled_rounded, color: color, size: 34),
              ],
            ),
          ),
        )
        .animate(delay: delay.ms)
        .fadeIn(duration: 400.ms)
        .slideX(begin: 0.1, end: 0);
  }
}
