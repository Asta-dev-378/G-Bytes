import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/game_provider.dart';
import '../../features/streak/models/daily_task.dart';

class StroopGameScreen extends StatefulWidget {
  const StroopGameScreen({super.key});

  @override
  State<StroopGameScreen> createState() => _StroopGameScreenState();
}

class _StroopGameScreenState extends State<StroopGameScreen> {
  bool _started = false;
  bool _sessionCompleted = false; // guard: award task XP only once

  @override
  void dispose() {
    context.read<GameProvider>().stopStroop();
    super.dispose();
  }

  void _start() {
    context.read<GameProvider>().startStroopGame();
    setState(() => _started = true);
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? const Color(0xFFD500F9) : const Color(0xFF8E24AA);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            const Text('Stroop Effect'),
            if (_started && game.state == GameState.playing)
              Text(
                'Tap the INK COLOR — not the word!',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        actions: [
          _HighScoreBadge(
            highScore: game.stroopHighScore,
            isNew: game.newStroopRecord,
            color: accent,
          ),
          if (_started)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '${game.stroopScore}/${game.stroopTotal}',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: accent,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: game.state == GameState.finished
            ? _buildResult(game, accent)
            : !_started
            ? _buildStart(accent)
            : _buildGame(game, accent),
      ),
    );
  }

  Widget _buildStart(Color accent) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '🎨',
            style: const TextStyle(fontSize: 72),
          ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
          const SizedBox(height: 16),
          Text(
            'Stroop Effect',
            style: GoogleFonts.poppins(
              fontSize: 30,
              fontWeight: FontWeight.w900,
            ),
          ).animate(delay: 100.ms).fadeIn(),
          const SizedBox(height: 10),
          // Mini demo
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.withAlpha(40)),
            ),
            child: Column(
              children: [
                Text(
                  'BLUE',
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '← tap "Red" (the ink color)',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ).animate(delay: 150.ms).fadeIn(),
          const SizedBox(height: 16),
          Text(
            '60 seconds  •  +10 pts per correct\nDifficulty increases with streak!',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.grey.shade600,
              height: 1.6,
            ),
          ).animate(delay: 200.ms).fadeIn(),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _start,
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('START GAME'),
            style: ElevatedButton.styleFrom(backgroundColor: accent),
          ).animate(delay: 250.ms).fadeIn().slideY(begin: 0.2),
        ],
      ),
    );
  }

  Widget _buildGame(GameProvider game, Color accent) {
    final progress = game.stroopTimeLeft / 60.0;
    final isCritical = game.stroopTimeLeft <= 15;

    return Column(
      children: [
        // Timer bar
        Container(
          height: 10,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(5)),
          clipBehavior: Clip.antiAlias,
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(
              progress > 0.5
                  ? accent
                  : progress > 0.25
                  ? Colors.orange
                  : Colors.red,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${game.stroopTimeLeft}s',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: isCritical ? Colors.red : accent,
              ),
            ).animate(target: isCritical ? 1 : 0).shake(hz: 2),
            if (game.stroopStreak >= 3)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade300),
                ),
                child: Text(
                  game.stroopStreak >= 5 
                      ? '🔥 On Fire! (+5/ans)' 
                      : '🔥 ${game.stroopStreak} streak!',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.red.shade600,
                  ),
                ),
              ).animate().scale(duration: 200.ms),
            Text(
              'Score: ${game.stroopScore}',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const Spacer(),

        // Word card
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Container(
            key: ValueKey(game.stroopWord + game.stroopInkName),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: game.stroopInkColor.withAlpha(40),
                  blurRadius: 30,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  game.stroopWord,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.russoOne(
                    fontSize: 52,
                    fontWeight: FontWeight.bold,
                    color: game.stroopInkColor,
                    letterSpacing: 4,
                    shadows: [
                      Shadow(
                        color: game.stroopInkColor.withAlpha(100),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Feedback flash
                if (game.stroopAnswered)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: game.stroopLastCorrect
                          ? Colors.green.withAlpha(30)
                          : Colors.red.withAlpha(30),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      game.stroopLastCorrect ? '✅ Correct!' : '❌ Wrong!',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: game.stroopLastCorrect
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 8),
        Text(
          '👆 What color is the text?',
          style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade500),
        ),
        const Spacer(),

        // Color choice buttons
        GridView.count(
          shrinkWrap: true,
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 2.6,
          children: game.stroopColorOptions.map((colorName) {
            final col = game.stroopColorMap[colorName]!;
            return GestureDetector(
              onTap: () => game.answerStroop(colorName),
              child: Container(
                decoration: BoxDecoration(
                  color: col.withAlpha(25),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: col, width: 2),
                ),
                child: Center(
                  child: Text(
                    colorName,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: col,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildResult(GameProvider game, Color accent) {
    // Award task XP once when Stroop session ends
    if (!_sessionCompleted) {
      _sessionCompleted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<GameProvider>().markGameComplete(TaskType.stroop);
      });
    }

    final accuracy = game.stroopTotal > 0
        ? (game.stroopCorrectCount / game.stroopTotal * 100).round()
        : 0;

    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              accuracy >= 80
                  ? '🏆'
                  : accuracy >= 50
                  ? '👍'
                  : '💪',
              style: const TextStyle(fontSize: 72),
            ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
            const SizedBox(height: 16),
            Text(
              'Game Over!',
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            ).animate(delay: 100.ms).fadeIn(),
            if (game.stroopMaxStreak >= 3) ...[
              const SizedBox(height: 6),
              Text(
                '🔥 Best streak: ${game.stroopMaxStreak}!',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.red.shade600,
                ),
              ).animate(delay: 150.ms).fadeIn(),
            ],
            const SizedBox(height: 16),
            if (game.newStroopRecord)
              Text(
                '🏆 New High Score: ${game.stroopHighScore}!',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFFFFB300),
                ),
              ).animate().shimmer(duration: 1200.ms),
            _StatRow('Points Earned', '${game.stroopScore} 📈', accent),
            _StatRow('Correct', '${game.stroopCorrectCount}', accent),
            _StatRow('Attempted', '${game.stroopTotal}', accent),
            _StatRow('Accuracy', '$accuracy%', accent),
            _StatRow('Best Streak', '${game.stroopMaxStreak} 🔥', accent),
            _StatRow('High Score', '${game.stroopHighScore}', accent),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _started = false;
                  _sessionCompleted = false; // allow re-award on next game
                });
                _start();
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('PLAY AGAIN'),
              style: ElevatedButton.styleFrom(backgroundColor: accent),
            ).animate(delay: 300.ms).fadeIn(),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;
  const _StatRow(this.label, this.value, this.accent);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              color: Colors.grey.shade600,
              fontSize: 15,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _HighScoreBadge extends StatelessWidget {
  final int highScore;
  final bool isNew;
  final Color color;
  const _HighScoreBadge({
    required this.highScore,
    required this.isNew,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isNew
                ? const Color(0xFFFFB300).withAlpha(50)
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isNew ? const Color(0xFFFFB300) : Colors.grey.shade300,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.emoji_events_rounded,
                size: 14,
                color: isNew ? const Color(0xFFFFB300) : color,
              ),
              const SizedBox(width: 4),
              Text(
                '$highScore',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: isNew ? const Color(0xFFFFB300) : color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
