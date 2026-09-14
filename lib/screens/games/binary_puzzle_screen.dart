// binary_puzzle_screen.dart
// Ported from sidhant947/puzzle — Binary Puzzle (Takuzu)
// Rules: fill grid with 0s & 1s; no 3 consecutive same value in row/col;
// equal count of 0s and 1s per row/col; no two identical rows or columns.

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'brain_game_shared.dart';

class BinaryPuzzleScreen extends StatefulWidget {
  const BinaryPuzzleScreen({super.key});
  @override
  State<BinaryPuzzleScreen> createState() => _BinaryPuzzleScreenState();
}

class _BinaryPuzzleScreenState extends State<BinaryPuzzleScreen> {
  // ignore: unused_field
  static const _gameId = 'binary_puzzle';

  BrainDifficulty? _difficulty;
  bool _countdownDone = false;

  late int _size;
  late List<List<int>> _solution;  // 0 or 1
  late List<List<int>> _board;     // -1=empty, 0, 1
  late List<List<bool>> _given;    // locked cells

  bool _solved = false;
  int _moves = 0;
  int? _bestMoves;

  // ── GENERATION ──────────────────────────────────────────────────────────────

  bool _isValidAt(List<List<int>> b, int r, int c, int v) {
    final n = b.length;
    // no 3 in a row horizontally
    if (c >= 2 && b[r][c-1] == v && b[r][c-2] == v) return false;
    if (c <= n-3 && b[r][c+1] == v && b[r][c+2] == v) return false;
    if (c >= 1 && c <= n-2 && b[r][c-1] == v && b[r][c+1] == v) return false;
    // no 3 in a row vertically
    if (r >= 2 && b[r-1][c] == v && b[r-2][c] == v) return false;
    if (r <= n-3 && b[r+1][c] == v && b[r+2][c] == v) return false;
    if (r >= 1 && r <= n-2 && b[r-1][c] == v && b[r+1][c] == v) return false;
    // count per row/col
    final rowCount = b[r].where((x) => x == v).length;
    if (rowCount >= n ~/ 2) return false;
    final colCount = List.generate(n, (i) => b[i][c]).where((x) => x == v).length;
    if (colCount >= n ~/ 2) return false;
    return true;
  }

  bool _solve(List<List<int>> b) {
    final n = b.length;
    for (int r = 0; r < n; r++) {
      for (int c = 0; c < n; c++) {
        if (b[r][c] == -1) {
          for (int v in [0, 1]) {
            if (_isValidAt(b, r, c, v)) {
              b[r][c] = v;
              if (_solve(b)) return true;
              b[r][c] = -1;
            }
          }
          return false;
        }
      }
    }
    return true;
  }

  void _generatePuzzle() {
    final rng = Random();
    final n = _size;

    // Build a solved grid
    List<List<int>> sol;
    int attempts = 0;
    do {
      sol = List.generate(n, (_) => List.filled(n, -1));
      attempts++;
      if (attempts > 50) { attempts = 0; }
    } while (!_solve(sol));

    _solution = sol;
    _board = List.generate(n, (r) => List.generate(n, (c) => sol[r][c]));
    _given = List.generate(n, (_) => List.filled(n, false));

    // Punch holes based on difficulty
    final keepRatio = switch (_difficulty!) {
      BrainDifficulty.easy   => 0.55,
      BrainDifficulty.medium => 0.40,
      BrainDifficulty.hard   => 0.28,
    };

    final cells = List.generate(n * n, (i) => i)..shuffle(rng);
    final keep = (n * n * keepRatio).round();
    for (int i = 0; i < cells.length; i++) {
      final r = cells[i] ~/ n;
      final c = cells[i] % n;
      if (i < keep) {
        _given[r][c] = true;
      } else {
        _board[r][c] = -1;
      }
    }
  }

  void _start(BrainDifficulty d) {
    _difficulty = d;
    _size = switch (d) {
      BrainDifficulty.easy   => 6,
      BrainDifficulty.medium => 8,
      BrainDifficulty.hard   => 10,
    };
    _solved = false;
    _moves = 0;
    _loadBest().then((_) {});
    _generatePuzzle();
    setState(() {});
  }

  Future<void> _loadBest() async {
    _bestMoves = await BrainScoreRepository.instance.bestScore(
      'binary_puzzle_${_difficulty!.name}', lowerIsBetter: true);
    if (mounted) setState(() {});
  }

  // ── INTERACTION ─────────────────────────────────────────────────────────────

  void _tapCell(int r, int c) {
    if (_given[r][c] || _solved) return;
    HapticFeedback.lightImpact();
    setState(() {
      _board[r][c] = _board[r][c] == -1 ? 0 : _board[r][c] == 0 ? 1 : -1;
      _moves++;
      _checkSolved();
    });
  }

  void _checkSolved() {
    for (int r = 0; r < _size; r++) {
      for (int c = 0; c < _size; c++) {
        if (_board[r][c] != _solution[r][c]) return;
      }
    }
    _solved = true;
    HapticFeedback.heavyImpact();
    _saveResult();
  }

  Future<void> _saveResult() async {
    final result = BrainGameResult(
      gameId: 'binary_puzzle_${_difficulty!.name}',
      score: _moves,
      accuracy: 100,
      difficulty: _difficulty!,
      playedAt: DateTime.now(),
    );
    await BrainScoreRepository.instance.save(result);
    await _loadBest();
  }

  // ── BUILD ────────────────────────────────────────────────────────────────────

  Color get _accent => const Color(0xFF3B82F6);

  @override
  Widget build(BuildContext context) {
    if (_difficulty == null) {
      return BrainDifficultySelector(
        gameTitle: 'Binary Puzzle',
        description: 'Fill the grid with 0s and 1s.\nNo three consecutive same values in any row or column.\nEach row and column must have equal 0s and 1s.',
        onSelected: _start,
      );
    }
    if (!_countdownDone) {
      return BrainCountdownOverlay(onDone: () => setState(() => _countdownDone = true));
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: Column(
        children: [
          BrainGameHUD(
            score: _moves,
            onExit: () => Navigator.of(context).pop(),
            difficultyLabel: _difficulty!.label,
            accentColor: _accent,
          ),
          const SizedBox(height: 12),
          if (_bestMoves != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.emoji_events_rounded, size: 14, color: Colors.amber.shade400),
                  const SizedBox(width: 4),
                  Text('Best: $_bestMoves moves',
                    style: GoogleFonts.poppins(fontSize: 12, color: Colors.white38)),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _buildGrid(),
              ),
            ),
          ),
          _buildLegend(),
          const SizedBox(height: 24),
          if (_solved) _buildSolvedBanner(),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _accent.withValues(alpha: 0.3), width: 1.5),
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          children: List.generate(_size, (r) => Expanded(
            child: Row(
              children: List.generate(_size, (c) => Expanded(
                child: _BinaryCell(
                  value: _board[r][c],
                  isGiven: _given[r][c],
                  accent: _accent,
                  onTap: () => _tapCell(r, c),
                ),
              )),
            ),
          )),
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _legendDot(Colors.cyan, '0'),
          const SizedBox(width: 16),
          _legendDot(Colors.amber, '1'),
          const SizedBox(width: 16),
          Text('Tap cell to cycle: empty → 0 → 1',
            style: GoogleFonts.poppins(fontSize: 10, color: Colors.white30)),
        ],
      ),
    );
  }

  Widget _legendDot(Color c, String label) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 12, height: 12, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text(label, style: GoogleFonts.poppins(fontSize: 11, color: Colors.white54)),
    ]);
  }

  Widget _buildSolvedBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [_accent, _accent.withValues(alpha: 0.7)]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: _accent.withValues(alpha: 0.4), blurRadius: 20)],
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text('🎉', style: TextStyle(fontSize: 24)),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Puzzle Solved!', style: GoogleFonts.poppins(
            fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
          Text('$_moves moves${_bestMoves != null && _moves <= _bestMoves! ? '  🏆 New Best!' : ''}',
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.white70)),
        ]),
        const Spacer(),
        GestureDetector(
          onTap: () => setState(() {
            _countdownDone = false;
            _solved = false;
            _moves = 0;
            _generatePuzzle();
          }),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('New', style: GoogleFonts.poppins(
              fontSize: 13, fontWeight: FontWeight.w800, color: _accent)),
          ),
        ),
      ]),
    );
  }
}

class _BinaryCell extends StatelessWidget {
  final int value;  // -1, 0, or 1
  final bool isGiven;
  final Color accent;
  final VoidCallback onTap;

  const _BinaryCell({
    required this.value,
    required this.isGiven,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isEmpty = value == -1;
    final isZero = value == 0;
    final cellColor = isGiven
        ? (isZero ? Colors.cyan.withValues(alpha: 0.25) : Colors.amber.withValues(alpha: 0.25))
        : isEmpty
            ? Colors.white.withValues(alpha: 0.03)
            : isZero
                ? Colors.cyan.withValues(alpha: 0.15)
                : Colors.amber.withValues(alpha: 0.15);

    final textColor = isGiven
        ? (isZero ? Colors.cyan : Colors.amber)
        : isEmpty
            ? Colors.transparent
            : isZero
                ? Colors.cyan.shade300
                : Colors.amber.shade300;

    return GestureDetector(
      onTap: isGiven ? null : onTap,
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: cellColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isGiven
                ? (isZero ? Colors.cyan.withValues(alpha: 0.5) : Colors.amber.withValues(alpha: 0.5))
                : Colors.white.withValues(alpha: 0.06),
            width: isGiven ? 1.5 : 0.8,
          ),
        ),
        child: Center(
          child: Text(
            isEmpty ? '' : value.toString(),
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: isGiven ? FontWeight.w900 : FontWeight.w700,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}
