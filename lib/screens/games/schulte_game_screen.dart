import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/game_provider.dart';
import '../../providers/settings_provider.dart';

class SchulteGameScreen extends StatefulWidget {
  const SchulteGameScreen({super.key});

  @override
  State<SchulteGameScreen> createState() => _SchulteGameScreenState();
}

class _SchulteGameScreenState extends State<SchulteGameScreen>
    with SingleTickerProviderStateMixin {
  bool _started = false;
  int _selectedLevel = 1;
  bool _hardMode = false;

  @override
  void dispose() {
    context.read<GameProvider>().stopSchulte();
    super.dispose();
  }

  void _start(int level) {
    setState(() {
      _selectedLevel = level;
      _started = true;
    });
    context.read<GameProvider>().startSchulteGame(level: level);
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final settings = context.watch<SettingsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? const Color(0xFF00E5FF) : const Color(0xFF00BCD4);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            const Text('Schulte Table'),
            if (_started)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Grid ${game.schulteGridSize}×${game.schulteGridSize}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (!_hardMode) ...[
                    Text(
                      '  •  Next: ${game.schulteNext}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ] else ...[
                    Text(
                      '  •  HARD',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.red.shade400,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
          ],
        ),
        actions: [
          _HighScoreBadge(
            label: game.schulteHighScore == 0
                ? '–'
                : '${game.schulteHighScore}s',
            isNew: game.newSchulteRecord,
            color: accent,
          ),
          if (_started)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    '⏱ ${game.schulteTimeElapsed}s',
                    key: ValueKey(game.schulteTimeElapsed),
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: accent,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: !_started
          ? _buildStart(accent, settings)
          : game.state == GameState.roundComplete
          ? _buildComplete(game, accent)
          : _buildGame(game, accent),
    );
  }

  Widget _buildStart(Color accent, SettingsProvider settings) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '🔢',
              style: const TextStyle(fontSize: 72),
            ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
            const SizedBox(height: 16),
            Text(
              'Schulte Table',
              style: GoogleFonts.poppins(
                fontSize: 30,
                fontWeight: FontWeight.w900,
              ),
            ).animate(delay: 100.ms).fadeIn(),
            const SizedBox(height: 8),
            Text(
              'Tap numbers 1, 2, 3… in order\nas fast as possible!',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 15,
                color: Colors.grey.shade600,
              ),
            ).animate(delay: 150.ms).fadeIn(),
            const SizedBox(height: 24),

            // Hard Mode Toggle
            Container(
              decoration: BoxDecoration(
                color: _hardMode ? Colors.red.shade50 : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _hardMode ? Colors.red.shade300 : Colors.grey.shade200,
                  width: 1.5,
                ),
              ),
              child: SwitchListTile.adaptive(
                value: _hardMode,
                onChanged: (v) {
                  setState(() => _hardMode = v);
                  settings.setSchulteHardMode(v);
                },
                activeTrackColor: Colors.red.shade400,
                activeThumbColor: Colors.red.shade200,
                title: Row(
                  children: [
                    Icon(
                      _hardMode
                          ? Icons.whatshot_rounded
                          : Icons.whatshot_outlined,
                      color: _hardMode ? Colors.red.shade400 : Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Hard Mode',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: _hardMode
                            ? Colors.red.shade700
                            : Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
                subtitle: Text(
                  _hardMode
                      ? 'No hints — find numbers on your own!'
                      : 'Numbers are highlighted for guidance',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: _hardMode ? Colors.red.shade400 : Colors.grey,
                  ),
                ),
              ),
            ).animate(delay: 175.ms).fadeIn(),
            const SizedBox(height: 20),

            Text(
              'Choose Grid Size',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _DiffBtn(
                  label: '3×3',
                  sub: 'Easy',
                  color: const Color(0xFF20BC68),
                  onTap: () => _start(1),
                ),
                const SizedBox(width: 12),
                _DiffBtn(
                  label: '4×4',
                  sub: 'Medium',
                  color: accent,
                  onTap: () => _start(2),
                ),
                const SizedBox(width: 12),
                _DiffBtn(
                  label: '5×5',
                  sub: 'Large',
                  color: Colors.red.shade400,
                  onTap: () => _start(3),
                ),
              ],
            ).animate(delay: 200.ms).fadeIn(),
          ],
        ),
      ),
    );
  }

  Widget _buildGame(GameProvider game, Color accent) {
    final size = game.schulteGridSize;
    return Column(
      children: [
        // Progress indicator (only in Easy mode show the number)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _hardMode
                  ? Text(
                      'Hard Mode 🔥',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.red.shade400,
                      ),
                    )
                  : Text(
                      'Find: ${game.schulteNext}',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: accent,
                      ),
                    ),
              Text(
                '${game.schulteNext - 1} / ${game.schulteTotal}',
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
        LinearProgressIndicator(
          value: (game.schulteNext - 1) / game.schulteTotal,
          backgroundColor: Colors.grey.shade200,
          valueColor: AlwaysStoppedAnimation<Color>(
            _hardMode ? Colors.red.shade400 : accent,
          ),
          minHeight: 6,
        ),
        const SizedBox(height: 20),

        // Grid
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: size,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: game.schulteGrid.length,
              itemBuilder: (ctx, i) {
                final number = game.schulteGrid[i];
                final isFound = number < game.schulteNext;
                final isNext = number == game.schulteNext;

                // In hard mode: no highlighting or color distinction for "next"
                final showHighlight = !_hardMode && isNext;
                final showFound = !_hardMode && isFound;

                return GestureDetector(
                  onTap: () => game.tapSchulteCell(number),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: showFound
                          ? accent.withAlpha(40)
                          : Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: showHighlight
                            ? accent
                            : showFound
                            ? Colors.transparent
                            : Colors.grey.withAlpha(40),
                        width: showHighlight ? 2.5 : 1,
                      ),
                      boxShadow: showHighlight
                          ? [
                              BoxShadow(
                                color: accent.withAlpha(80),
                                blurRadius: 12,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        '$number',
                        style: GoogleFonts.poppins(
                          fontSize: size == 5 ? 18 : 24,
                          fontWeight: FontWeight.w800,
                          color: showFound
                              ? accent.withAlpha(120)
                              : showHighlight
                              ? accent
                              : null,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildComplete(GameProvider game, Color accent) {
    final pts = max(10, 200 - game.schulteTimeElapsed);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '🎉',
              style: const TextStyle(fontSize: 72),
            ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
            const SizedBox(height: 16),
            if (game.newSchulteRecord)
              Text(
                '🏆 New Best Time!',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFFFFB300),
                ),
              ).animate().shimmer(duration: 1200.ms),
            Text(
              _hardMode ? 'Hard Mode Complete!' : 'Completed!',
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            ).animate(delay: 100.ms).fadeIn(),
            if (_hardMode)
              Text(
                'Impressive! You did it without hints 🔥',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.red.shade400,
                  fontWeight: FontWeight.w600,
                ),
              ).animate(delay: 150.ms).fadeIn(),
            const SizedBox(height: 20),
            _ResultRow(
              label: 'Time',
              value: '${game.schulteTimeElapsed}s',
              accent: accent,
            ),
            _ResultRow(
              label: 'Best Time',
              value: game.schulteHighScore == 0
                  ? '–'
                  : '${game.schulteHighScore}s',
              accent: accent,
            ),
            _ResultRow(label: 'Points earned', value: '+$pts', accent: accent),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _started = false),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: accent, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      minimumSize: const Size(0, 50),
                    ),
                    child: Text(
                      'Change Level',
                      style: GoogleFonts.poppins(
                        color: accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () => _start(_selectedLevel),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('PLAY AGAIN'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      minimumSize: const Size(0, 50),
                    ),
                  ),
                ),
              ],
            ).animate(delay: 300.ms).fadeIn(),
          ],
        ),
      ),
    );
  }
}

class _DiffBtn extends StatelessWidget {
  final String label;
  final String sub;
  final Color color;
  final VoidCallback onTap;

  const _DiffBtn({
    required this.label,
    required this.sub,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 95,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color, width: 2),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: color,
              ),
            ),
            Text(sub, style: GoogleFonts.poppins(fontSize: 11, color: color)),
          ],
        ),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;
  const _ResultRow({
    required this.label,
    required this.value,
    required this.accent,
  });

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
              fontWeight: FontWeight.w800,
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
  final String label;
  final bool isNew;
  final Color color;
  const _HighScoreBadge({
    required this.label,
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
                Icons.timer_outlined,
                size: 14,
                color: isNew ? const Color(0xFFFFB300) : color,
              ),
              const SizedBox(width: 4),
              Text(
                label,
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
