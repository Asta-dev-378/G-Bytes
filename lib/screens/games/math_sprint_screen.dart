import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/game_provider.dart';

class MathSprintScreen extends StatefulWidget {
  const MathSprintScreen({super.key});

  @override
  State<MathSprintScreen> createState() => _MathSprintScreenState();
}

class _MathSprintScreenState extends State<MathSprintScreen> {
  bool _started = false;

  void _startGame() {
    context.read<GameProvider>().startMathSprint();
    setState(() => _started = true);
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final green = isDark ? Colors.lightGreenAccent : Colors.green;

    if (game.state == GameState.finished && !_started) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() => _started = true);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Math Sprint'),
        actions: [
          _HighScoreBadge(
            highScore: game.mathHighScore,
            isNew: game.newMathRecord,
            color: green,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '${game.mathScore}/${game.mathTotal}',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: green,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: game.state == GameState.finished
            ? _buildResult(game)
            : !_started
            ? _buildStartScreen()
            : _buildGame(game),
      ),
    );
  }

  Widget _buildStartScreen() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final green = isDark ? Colors.lightGreenAccent : Colors.green;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            '⚡',
            style: TextStyle(fontSize: 72),
          ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
          const SizedBox(height: 16),
          Text(
            'Math Sprint',
            style: GoogleFonts.poppins(
              fontSize: 32,
              fontWeight: FontWeight.w900,
            ),
          ).animate(delay: 100.ms).fadeIn(),
          const SizedBox(height: 8),
          Text(
            'Solve as many equations\nas you can in 60 seconds!',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 15,
              color: Colors.grey.shade600,
            ),
          ).animate(delay: 200.ms).fadeIn(),
          const SizedBox(height: 40),
          ElevatedButton.icon(
            onPressed: _startGame,
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('START SPRINT'),
            style: ElevatedButton.styleFrom(
              backgroundColor: green,
              minimumSize: const Size(200, 56),
            ),
          ).animate(delay: 250.ms).fadeIn().slideY(begin: 0.2),
        ],
      ),
    );
  }

  Widget _buildGame(GameProvider game) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final green = isDark ? Colors.lightGreenAccent : Colors.green;
    final orange = isDark ? Colors.orangeAccent : Colors.orange;
    final progress = game.mathTimeLeft / 60.0;
    final isCritical = game.mathTimeLeft <= 15;

    return Column(
      children: [
        // Timer bar
        Container(
          height: 12,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(6)),
          clipBehavior: Clip.antiAlias,
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(
              progress > 0.5
                  ? green
                  : progress > 0.25
                  ? orange
                  : Colors.red,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${game.mathTimeLeft}s',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isCritical ? Colors.red : green,
              ),
            ).animate(target: isCritical ? 1 : 0).shake(hz: 2),
            // Streak badge
            if (game.mathStreak >= 3)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade300),
                ),
                child: Text(
                  '🔥 ${game.mathStreak} streak!',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.red.shade600,
                  ),
                ),
              ).animate().scale(duration: 200.ms),
            Text(
              'Score: ${game.mathScore}',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const Spacer(),

        // Equation card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(20),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Text(
            '${game.mathA} ${game.mathOp} ${game.mathB} = ?',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 38,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const Spacer(),

        // Answer choices with flash feedback
        GridView.count(
          shrinkWrap: true,
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 2.2,
          children: game.mathChoices.asMap().entries.map((entry) {
            final idx = entry.key;
            final val = entry.value;
            final isFlashCorrect = game.mathLastCorrect == idx;
            final isFlashWrong =
                game.mathLastCorrect == -2 && val == game.mathChoices[idx];

            Color bgColor = Theme.of(context).cardColor;
            if (isFlashCorrect) bgColor = green.withAlpha(80);
            if (isFlashWrong) bgColor = Colors.red.withAlpha(60);

            return GestureDetector(
              onTap: () => game.answerMath(val),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '$val',
                    style: GoogleFonts.poppins(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const Spacer(),
      ],
    );
  }

  Widget _buildResult(GameProvider game) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final green = isDark ? Colors.lightGreenAccent : Colors.green;
    final accuracy = game.mathTotal > 0
        ? (game.mathScore / game.mathTotal * 100).round()
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
            const SizedBox(height: 20),
            Text(
              'Sprint Complete!',
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            ).animate(delay: 100.ms).fadeIn(),
            const SizedBox(height: 8),
            if (game.mathMaxStreak >= 3)
              Text(
                '🔥 Best streak: ${game.mathMaxStreak}!',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.red.shade600,
                ),
              ).animate(delay: 150.ms).fadeIn(),
            const SizedBox(height: 16),
            if (game.newMathRecord) ...[
              Text(
                    '🏆 New High Score: ${game.mathHighScore}!',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFFFFB300),
                    ),
                  )
                  .animate()
                  .scale(duration: 500.ms, curve: Curves.elasticOut)
                  .then()
                  .shimmer(duration: 1200.ms),
              const SizedBox(height: 12),
            ],
            _statRow('Correct Answers', '${game.mathScore}'),
            _statRow('Total Attempted', '${game.mathTotal}'),
            _statRow('Accuracy', '$accuracy%'),
            _statRow('Best Streak', '${game.mathMaxStreak} 🔥'),
            _statRow('Best Score (all time)', '${game.mathHighScore}'),

            // Per-operator breakdown
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: green.withAlpha(15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: green.withAlpha(60)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Breakdown by Operation',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: green,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _opRow('Addition ＋', game.mathPlusScore),
                  _opRow('Subtraction −', game.mathMinusScore),
                  _opRow('Multiplication ×', game.mathMulScore),
                ],
              ),
            ).animate(delay: 300.ms).fadeIn(),

            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: () {
                setState(() => _started = false);
                _startGame();
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('PLAY AGAIN'),
              style: ElevatedButton.styleFrom(backgroundColor: green),
            ).animate(delay: 400.ms).fadeIn(),
          ],
        ),
      ),
    );
  }

  Widget _statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: const Color(0xFFFF8C00),
            ),
          ),
        ],
      ),
    );
  }

  Widget _opRow(String label, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.grey.shade700,
            ),
          ),
          Text(
            '$count correct',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              fontSize: 13,
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
          duration: const Duration(milliseconds: 400),
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
                color: isNew ? const Color(0xFFFFB300) : Colors.grey.shade500,
              ),
              const SizedBox(width: 4),
              Text(
                '$highScore',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: isNew ? const Color(0xFFFFB300) : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
