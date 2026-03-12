import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/game_provider.dart';

class LogicGameScreen extends StatefulWidget {
  const LogicGameScreen({super.key});

  @override
  State<LogicGameScreen> createState() => _LogicGameScreenState();
}

class _LogicGameScreenState extends State<LogicGameScreen> {
  int? _selectedAnswer;
  bool _answered = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GameProvider>().startLogicGame();
    });
  }

  void _answer(int val) {
    if (_answered) return;
    setState(() {
      _selectedAnswer = val;
      _answered = true;
    });
    context.read<GameProvider>().answerLogic(val);
  }

  void _nextRound() {
    setState(() {
      _selectedAnswer = null;
      _answered = false;
    });
    context.read<GameProvider>().nextLogicRound();
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final purple = isDark
        ? Colors.deepPurpleAccent
        : Colors.deepPurple; // primary action color
    final orange = isDark ? Colors.orangeAccent : Colors.orange;
    final green = isDark ? Colors.lightGreenAccent : Colors.green;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            const Text('Logic Game'),
            Text(
              'Q${game.logicQuestionsAnswered + 1}  •  Session: ${game.logicSessionScore} pts',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          _HighScoreBadge(
            highScore: game.logicHighScore,
            isNew: game.newLogicRecord,
            color: purple,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '+20 pts',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: purple,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'What comes next in the sequence?',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),

            // Sequence display
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(15),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: game.logicPattern.asMap().entries.map((e) {
                  final isMissing = e.key == game.logicMissingIndex;
                  return _SeqTile(
                    value: isMissing ? '?' : '${e.value}',
                    label: '${e.key + 1}',
                    color: isMissing ? orange : purple,
                    delay: e.key * 100,
                    isQuestion: isMissing,
                    answer: isMissing && _answered
                        ? '${game.logicAnswer}'
                        : null,
                    isCorrect:
                        isMissing &&
                        _answered &&
                        _selectedAnswer == game.logicAnswer,
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 24),

            // Answer choices grid
            Text(
              'Select your answer:',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),

            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.5,
              children: game.logicChoices.asMap().entries.map((e) {
                final val = e.value;
                final isSelected = _selectedAnswer == val;
                final isCorrect = val == game.logicAnswer;
                Color btnColor = Theme.of(context).cardColor;
                Color textColor =
                    Theme.of(context).textTheme.bodyLarge?.color ??
                    Colors.black;

                if (_answered && isSelected) {
                  btnColor = isCorrect ? green : Colors.red.shade400;
                  textColor = Colors.white;
                } else if (_answered && isCorrect) {
                  btnColor = green;
                  textColor = Colors.white;
                }

                return GestureDetector(
                      onTap: () => _answer(val),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: btnColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? Colors.transparent
                                : Colors.grey.withAlpha(50),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(15),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            '$val',
                            style: GoogleFonts.poppins(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: textColor,
                            ),
                          ),
                        ),
                      ),
                    )
                    .animate(delay: (e.key * 80).ms)
                    .fadeIn()
                    .scale(duration: 300.ms, curve: Curves.easeOut);
              }).toList(),
            ),

            const SizedBox(height: 28),

            // Result section
            if (_answered) ...[
              // Pattern type hint
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: purple.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: purple.withAlpha(60)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb_outline, color: purple, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '💡 ${game.logicSeriesName}',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: purple,
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms),

              const SizedBox(height: 14),

              if (game.newLogicRecord)
                Text(
                      '🏆 New High Score: ${game.logicHighScore}!',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFFFFB300),
                      ),
                    )
                    .animate()
                    .scale(duration: 500.ms, curve: Curves.elasticOut)
                    .then()
                    .shimmer(duration: 1200.ms),

              Text(
                _selectedAnswer == game.logicAnswer
                    ? '✅ Correct! +20 pts'
                    : '❌ Wrong! The answer was ${game.logicAnswer}',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _selectedAnswer == game.logicAnswer
                      ? green
                      : Colors.red,
                ),
              ).animate().scale(duration: 300.ms, curve: Curves.elasticOut),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: Color(0xFF6C63FF),
                          width: 2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        minimumSize: const Size(0, 50),
                      ),
                      child: Text(
                        'Leave',
                        style: GoogleFonts.poppins(
                          color: purple,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _nextRound,
                      icon: const Icon(Icons.arrow_forward_rounded),
                      label: const Text('NEXT QUESTION'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: purple,
                        minimumSize: const Size(0, 50),
                      ),
                    ),
                  ),
                ],
              ).animate(delay: 100.ms).fadeIn(),
            ],
          ],
        ),
      ),
    );
  }
}

class _SeqTile extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final int delay;
  final bool isQuestion;
  final String? answer;
  final bool isCorrect;

  const _SeqTile({
    required this.value,
    required this.label,
    required this.color,
    required this.delay,
    this.isQuestion = false,
    this.answer,
    this.isCorrect = false,
  });

  @override
  Widget build(BuildContext context) {
    final displayValue = (isQuestion && answer != null) ? answer! : value;
    final bgColor = isQuestion
        ? (answer != null
              ? (isCorrect
                    ? const Color(0xFF20BC68).withAlpha(30)
                    : Colors.red.withAlpha(30))
              : color.withAlpha(30))
        : color.withAlpha(30);
    final textColor = isQuestion
        ? (answer != null
              ? (isCorrect ? const Color(0xFF20BC68) : Colors.red)
              : color)
        : color;

    return Column(
      children: [
        Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(14),
                border: isQuestion && answer == null
                    ? Border.all(color: color, width: 2)
                    : null,
              ),
              child: Center(
                child: Text(
                  displayValue,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
              ),
            )
            .animate(delay: delay.ms)
            .scale(duration: 300.ms, curve: Curves.elasticOut),
        const SizedBox(height: 6),
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade400),
        ),
      ],
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
