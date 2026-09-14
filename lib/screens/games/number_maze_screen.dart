// number_maze_screen.dart — Number Maze Brain Game
// A scrambled grid of numbers. Tap 1, 2, 3... in ascending order as fast as possible.
// Timer counts up. Mistakes add a +1s penalty. Beat your best time.
// Grid size grows with difficulty tier.

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../providers/player_progress_provider.dart';
import '../../features/streak/models/daily_task.dart';


// ── Difficulty ────────────────────────────────────────────────────────────────

enum _Diff { easy, medium, hard }

extension _DiffX on _Diff {
  String get label => ['Easy (4×4)', 'Medium (5×5)', 'Hard (6×6)'][index];
  int get gridSize => [4, 5, 6][index];
  int get totalCells => gridSize * gridSize;
  String get bestKey => 'number_maze_best_${name}';
  Color get color => [
    const Color(0xFF22C55E),
    const Color(0xFF3B82F6),
    const Color(0xFFEF4444),
  ][index];
}

// ── Screen ────────────────────────────────────────────────────────────────────

class NumberMazeScreen extends StatefulWidget {
  const NumberMazeScreen({super.key});

  @override
  State<NumberMazeScreen> createState() => _NumberMazeScreenState();
}

class _NumberMazeScreenState extends State<NumberMazeScreen>
    with SingleTickerProviderStateMixin {
  final _rng = Random();

  _Diff _diff = _Diff.easy;

  // Grid
  late List<int> _numbers;     // shuffled 1..N in flat index
  late List<bool> _tapped;
  int _nextExpected = 1;

  // Timer
  bool _running = false;
  bool _finished = false;
  int _elapsedMs = 0;
  Timer? _timer;

  // Feedback
  int? _lastWrongIdx;
  double _penaltyFlash = 0.0;

  // Best times per difficulty (ms, 0 = unset)
  final Map<_Diff, int> _bests = {
    _Diff.easy:   0,
    _Diff.medium: 0,
    _Diff.hard:   0,
  };

  // Animation for wrong tap shake
  late AnimationController _shakeCtrl;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _loadBests();
    _buildGrid();
  }

  Future<void> _loadBests() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      for (final d in _Diff.values) {
        _bests[d] = prefs.getInt(d.bestKey) ?? 0;
      }
    });
  }

  Future<void> _saveBest() async {
    final prev = _bests[_diff]!;
    if (prev == 0 || _elapsedMs < prev) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_diff.bestKey, _elapsedMs);
      setState(() => _bests[_diff] = _elapsedMs);
    }
  }

  void _buildGrid() {
    final n = _diff.totalCells;
    _numbers = List.generate(n, (i) => i + 1)..shuffle(_rng);
    _tapped = List.filled(n, false);
    _nextExpected = 1;
  }

  void _startGame() {
    _buildGrid();
    setState(() {
      _running = true;
      _finished = false;
      _elapsedMs = 0;
      _lastWrongIdx = null;
      _penaltyFlash = 0;
    });
    _timer = Timer.periodic(const Duration(milliseconds: 33), (_) {
      setState(() => _elapsedMs += 33);
    });
  }

  void _endGame() {
    _timer?.cancel();
    _saveBest();
    context.read<PlayerProgressProvider>().markGameComplete(TaskType.slidingPuzzle);

    setState(() {
      _running = false;
      _finished = true;
    });
  }

  void _onTap(int index) {
    if (!_running) return;
    final val = _numbers[index];

    if (val == _nextExpected) {
      HapticFeedback.lightImpact();
      setState(() {
        _tapped[index] = true;
        _nextExpected++;
        _lastWrongIdx = null;
      });
      if (_nextExpected > _diff.totalCells) _endGame();
    } else {
      HapticFeedback.heavyImpact();
      setState(() {
        _lastWrongIdx = index;
        _elapsedMs += 1000; // +1s penalty
        _penaltyFlash = 1.0;
      });
      _shakeCtrl.forward(from: 0).then((_) => _shakeCtrl.reset());
      // Fade penalty flash
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) setState(() => _penaltyFlash = 0.0);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _shakeCtrl.dispose();
    super.dispose();
  }

  String _formatTime(int ms) {
    final s = ms ~/ 1000;
    final ds = (ms % 1000) ~/ 100;
    return '$s.${ds}s';
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF0A0A0F);
    final accent = _diff.color;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white70),
          onPressed: () { _timer?.cancel(); Navigator.pop(context); },
        ),
        title: Text('Number Maze',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w800, color: Colors.white, fontSize: 18)),
        actions: [
          // Difficulty picker (only when not running)
          if (!_running)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: PopupMenuButton<_Diff>(
                color: const Color(0xFF1A1A22),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                icon: const Icon(Icons.tune_rounded, color: Colors.white70),
                onSelected: (d) {
                  setState(() { _diff = d; _buildGrid(); _finished = false; });
                },
                itemBuilder: (_) => _Diff.values.map((d) => PopupMenuItem(
                  value: d,
                  child: Text(d.label,
                      style: GoogleFonts.poppins(
                          color: d == _diff ? d.color : Colors.white70,
                          fontWeight: d == _diff ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 13)),
                )).toList(),
              ),
            ),
        ],
      ),
      body: _finished
          ? _buildResults(accent)
          : _running
              ? _buildGame(accent)
              : _buildIntro(accent),
    );
  }

  // ── Intro ──────────────────────────────────────────────────────────────────

  Widget _buildIntro(Color accent) {
    final best = _bests[_diff]!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🔢', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 20),
            Text('Number Maze',
                style: GoogleFonts.poppins(
                    fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white)),
            const SizedBox(height: 12),
            Text(
              'Numbers are scattered across the grid.\n'
              'Tap them in order: 1, 2, 3…\n'
              'Each mistake adds +1s penalty.\n'
              'Try to beat your best time!',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  fontSize: 14, color: Colors.white54, height: 1.6),
            ),
            const SizedBox(height: 20),
            // Difficulty selection
            Row(
              children: _Diff.values.map((d) => Expanded(
                child: GestureDetector(
                  onTap: () => setState(() { _diff = d; _buildGrid(); }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _diff == d ? d.color.withAlpha(30) : Colors.white.withAlpha(5),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _diff == d ? d.color.withAlpha(180) : Colors.white.withAlpha(18),
                        width: _diff == d ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          d.label.split(' ')[0],
                          style: GoogleFonts.poppins(
                            color: _diff == d ? d.color : Colors.white38,
                            fontWeight: FontWeight.w700, fontSize: 12,
                          ),
                        ),
                        Text(
                          d.label.split(' ').last,
                          style: GoogleFonts.poppins(
                            color: _diff == d ? d.color : Colors.white24,
                            fontWeight: FontWeight.w600, fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )).toList(),
            ),
            if (best > 0) ...[
              const SizedBox(height: 16),
              Text('⏱ Best: ${_formatTime(best)}',
                  style: GoogleFonts.poppins(
                      color: Colors.amber, fontWeight: FontWeight.w700, fontSize: 14)),
            ],
            const SizedBox(height: 36),
            _PrimaryBtn(label: 'Start', color: accent, onTap: _startGame),
          ],
        ),
      ),
    );
  }

  // ── Game ───────────────────────────────────────────────────────────────────

  Widget _buildGame(Color accent) {
    final gs = _diff.gridSize;
    final progress = (_nextExpected - 1) / _diff.totalCells;

    return SafeArea(
      child: Column(
        children: [
          // Timer + progress
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _penaltyFlash > 0
                        ? Colors.red.withAlpha(40)
                        : Colors.white.withAlpha(8),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _penaltyFlash > 0 ? Colors.red.withAlpha(160) : Colors.white24,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Text('⏱', style: TextStyle(fontSize: 13)),
                      const SizedBox(width: 4),
                      Text(
                        _formatTime(_elapsedMs),
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          color: _penaltyFlash > 0 ? Colors.red : Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  '${_nextExpected - 1} / ${_diff.totalCells}',
                  style: GoogleFonts.poppins(
                      color: accent, fontWeight: FontWeight.w800, fontSize: 15),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.white12,
                color: accent,
                minHeight: 4,
              ),
            ),
          ),

          // Next number hint
          Text(
            'Find: $_nextExpected',
            style: GoogleFonts.poppins(
              color: Colors.white38,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),

          // Grid
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: gs,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                ),
                itemCount: _diff.totalCells,
                itemBuilder: (context, index) {
                  final val = _numbers[index];
                  final done = _tapped[index];
                  final isWrong = _lastWrongIdx == index;
                  final isNext = val == _nextExpected;

                  return GestureDetector(
                    onTap: () => _onTap(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      decoration: BoxDecoration(
                        color: done
                            ? accent.withAlpha(22)
                            : isWrong
                                ? Colors.red.withAlpha(30)
                                : isNext
                                    ? accent.withAlpha(12)
                                    : Colors.white.withAlpha(5),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: done
                              ? accent.withAlpha(80)
                              : isWrong
                                  ? Colors.red.withAlpha(150)
                                  : isNext
                                      ? accent.withAlpha(120)
                                      : Colors.white.withAlpha(14),
                          width: isNext || isWrong ? 2 : 1,
                        ),
                        boxShadow: done
                            ? [BoxShadow(color: accent.withAlpha(30), blurRadius: 10)]
                            : isNext
                                ? [BoxShadow(color: accent.withAlpha(50), blurRadius: 14)]
                                : null,
                      ),
                      child: Center(
                        child: Text(
                          done ? '✓' : '$val',
                          style: GoogleFonts.poppins(
                            fontSize: gs == 6 ? 16 : 20,
                            fontWeight: FontWeight.w900,
                            color: done
                                ? accent.withAlpha(140)
                                : isWrong
                                    ? Colors.red
                                    : isNext
                                        ? accent
                                        : Colors.white54,
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
      ),
    );
  }

  // ── Results ────────────────────────────────────────────────────────────────

  Widget _buildResults(Color accent) {
    final best = _bests[_diff]!;
    final isNewBest = best == _elapsedMs || (best != 0 && _elapsedMs <= best);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(isNewBest ? '🏆' : '🔢', style: const TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text(
              isNewBest ? 'New Best!' : 'Completed!',
              style: GoogleFonts.poppins(
                  fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white),
            ),
            const SizedBox(height: 24),
            _ResultRow(label: 'Your Time',  value: _formatTime(_elapsedMs), accent: accent),
            const SizedBox(height: 8),
            _ResultRow(label: 'Best Time',  value: best > 0 ? _formatTime(best) : '—', accent: Colors.amber),
            const SizedBox(height: 8),
            _ResultRow(label: 'Difficulty', value: _diff.label.split(' ')[0], accent: _diff.color),
            const SizedBox(height: 36),
            _PrimaryBtn(label: 'Play Again', color: accent, onTap: _startGame),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Back to Hub',
                  style: GoogleFonts.poppins(color: Colors.white38, fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Small shared widgets ──────────────────────────────────────────────────────

class _PrimaryBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _PrimaryBtn({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(color: color.withAlpha(100), blurRadius: 24, offset: const Offset(0, 8)),
          ],
        ),
        child: Center(
          child: Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
        ),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;
  const _ResultRow({required this.label, required this.value, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withAlpha(12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.poppins(
                  color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w500)),
          Text(value,
              style: GoogleFonts.poppins(
                  color: accent, fontSize: 16, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
