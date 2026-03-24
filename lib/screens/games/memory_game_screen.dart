import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/game_provider.dart';

class MemoryGameScreen extends StatefulWidget {
  const MemoryGameScreen({super.key});

  @override
  State<MemoryGameScreen> createState() => _MemoryGameScreenState();
}

class _MemoryGameScreenState extends State<MemoryGameScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _celebrateCtrl;

  @override
  void initState() {
    super.initState();
    _celebrateCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GameProvider>().startMemoryGame();
    });
  }

  @override
  void dispose() {
    _celebrateCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isRoundComplete = game.state == GameState.roundComplete;
    final isFailed = game.state == GameState.finished;
    final orange = isDark ? Colors.orange.shade300 : Colors.orange.shade700;
    final green = isDark ? Colors.lightGreen.shade300 : Colors.green.shade700;

    if (isRoundComplete && !_celebrateCtrl.isAnimating) {
      _celebrateCtrl.forward(from: 0);
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            const Text('Memory Game'),
            Text(
              'Level ${game.memoryLevel}  •  ${game.memoryGridCols}×${game.memoryGridCols} grid',
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
            highScore: game.memoryHighScore,
            isNew: game.newMemoryRecord,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '⭐ ${game.score}',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: orange,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Phase banner
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: game.showingPattern
                        ? orange.withAlpha(26)
                        : (isRoundComplete
                              ? green.withAlpha(26)
                              : Colors.grey.withAlpha(20)),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        game.showingPattern
                            ? Icons.remove_red_eye_outlined
                            : (isRoundComplete
                                  ? Icons.check_circle_outline
                                  : Icons.touch_app_outlined),
                        color: game.showingPattern
                            ? orange
                            : (isRoundComplete ? green : Colors.grey),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          game.showingPattern
                              ? '👁️ Watch and memorize — Level ${game.memoryLevel}!'
                              : (isRoundComplete
                                    ? '🎉 Correct! Ready for the next level?'
                                    : '👆 Tap all the highlighted tiles!'),
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: game.showingPattern
                                ? orange
                                : (isRoundComplete ? green : Colors.grey),
                          ),
                        ),
                      ),
                      // Level points badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: orange.withAlpha(30),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '+20 pts',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: orange,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Grid
                Expanded(
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: game.memoryGridCols,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: game.memorySize,
                    itemBuilder: (ctx, i) {
                      final isActive =
                          i < game.memoryPattern.length &&
                          game.memoryPattern[i];
                      final playerTap = i < game.playerPattern.length
                          ? game.playerPattern[i]
                          : null;
                      final isHighlighted = game.highlightedIndex == i;

                      Color color =
                          Theme.of(context).brightness == Brightness.dark
                          ? Colors.white12
                          : Colors.grey.shade200;

                      if (game.showingPattern && isHighlighted) {
                        color = orange;
                      } else if (playerTap == true) {
                        color = green;
                      } else if (playerTap == false) {
                        color = Colors.red.shade300;
                      } else if (isRoundComplete && isActive) {
                        color = green.withAlpha(80);
                      }

                      return GestureDetector(
                            onTap: () => game.tapMemoryCell(i),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  if (color != Colors.grey.shade200 &&
                                      color != Colors.white12)
                                    BoxShadow(
                                      color: color.withAlpha(100),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                ],
                              ),
                            ),
                          )
                          .animate(delay: (i * 30).ms)
                          .scale(duration: 250.ms, curve: Curves.easeOut);
                    },
                  ),
                ),

                // Failure banner
                if (isFailed)
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Column(
                      children: [
                        Text(
                          '❌ Oops! Wrong tile. Game over!',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.red,
                          ),
                        ).animate().scale(
                          duration: 300.ms,
                          curve: Curves.elasticOut,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'You reached Level ${game.memoryLevel} with ${game.score} pts',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => game.startMemoryGame(),
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('TRY AGAIN'),
                        ).animate(delay: 100.ms).fadeIn(),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Round Complete Overlay
          if (isRoundComplete)
            Positioned.fill(
              child: Container(
                color: Colors.black.withAlpha(120),
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 32),
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(38),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🎉', style: TextStyle(fontSize: 52))
                            .animate()
                            .scale(duration: 500.ms, curve: Curves.elasticOut),
                        const SizedBox(height: 12),
                        if (game.newMemoryRecord)
                          Text(
                            '🏆 New High Score!',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFFFFB300),
                            ),
                          ).animate().shimmer(duration: 1200.ms),
                        Text(
                          'Level ${game.memoryLevel} Complete!',
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ).animate(delay: 100.ms).fadeIn().slideY(begin: 0.1),
                        Text(
                          '+20 pts  •  Total: ${game.score}',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: orange,
                            fontWeight: FontWeight.w600,
                          ),
                        ).animate(delay: 150.ms).fadeIn(),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                    color: Color(0xFFFF8C00),
                                    width: 2,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  minimumSize: const Size(0, 48),
                                ),
                                child: Text(
                                  'Leave',
                                  style: GoogleFonts.poppins(
                                    color: orange,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton.icon(
                                onPressed: () => game.nextMemoryRound(),
                                icon: const Icon(Icons.arrow_forward_rounded),
                                label: Text(
                                  'Next Level ${game.memoryLevel + 1}',
                                ),
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size(0, 48),
                                ),
                              ),
                            ),
                          ],
                        ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.2),
                      ],
                    ),
                  ),
                ),
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

  const _HighScoreBadge({required this.highScore, required this.isNew});

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
