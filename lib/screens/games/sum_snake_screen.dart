// sum_snake_screen.dart
// Ported from sidhant947/puzzle — Sum Snake
// Draw a connected path through grid cells; path sum must equal target.

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'brain_game_shared.dart';

class SumSnakeScreen extends StatefulWidget {
  const SumSnakeScreen({super.key});
  @override
  State<SumSnakeScreen> createState() => _SumSnakeScreenState();
}

class _SumSnakeScreenState extends State<SumSnakeScreen> {
  // ignore: unused_field
  static const _gameId = 'sum_snake';

  BrainDifficulty? _difficulty;
  bool _countdownDone = false;

  late int _size;
  late int _targetSum;
  late List<List<int>> _grid;
  final List<_Pt> _path = [];
  bool _solved = false;
  int _gamesWon = 0;

  Color get _accent => const Color(0xFF10B981);

  void _start(BrainDifficulty d) {
    _difficulty = d;
    _size = switch (d) {
      BrainDifficulty.easy   => 4,
      BrainDifficulty.medium => 5,
      BrainDifficulty.hard   => 6,
    };
    _generatePuzzle();
    setState(() {});
  }

  void _generatePuzzle() {
    final rng = Random();
    _grid = List.generate(
      _size, (_) => List.generate(_size, (_) {
        final maxVal = switch (_difficulty!) {
          BrainDifficulty.easy   => 9,
          BrainDifficulty.medium => 15,
          BrainDifficulty.hard   => 20,
        };
        return rng.nextInt(maxVal) + 1;
      }));

    // Choose a random valid path and set target = its sum
    _path.clear();
    final solution = _randomPath(rng);
    _targetSum = solution.fold(0, (s, p) => s + _grid[p.r][p.c]);
    _solved = false;
  }

  List<_Pt> _randomPath(Random rng) {
    final visited = List.generate(_size, (_) => List.filled(_size, false));
    final start = _Pt(rng.nextInt(_size), rng.nextInt(_size));
    final path = [start];
    visited[start.r][start.c] = true;
    final minLen = switch (_difficulty!) {
      BrainDifficulty.easy   => 4,
      BrainDifficulty.medium => 6,
      BrainDifficulty.hard   => 8,
    };
    for (int step = 0; step < _size * _size * 2; step++) {
      final cur = path.last;
      final neighbors = [
        _Pt(cur.r - 1, cur.c), _Pt(cur.r + 1, cur.c),
        _Pt(cur.r, cur.c - 1), _Pt(cur.r, cur.c + 1),
      ].where((p) => p.r >= 0 && p.r < _size && p.c >= 0 && p.c < _size && !visited[p.r][p.c]).toList();
      if (neighbors.isEmpty) break;
      final next = neighbors[rng.nextInt(neighbors.length)];
      path.add(next);
      visited[next.r][next.c] = true;
      if (path.length >= minLen && rng.nextDouble() < 0.3) break;
    }
    return path;
  }

  bool _isInPath(_Pt p) => _path.any((q) => q.r == p.r && q.c == p.c);

  bool _isAdjacent(_Pt a, _Pt b) =>
      (a.r == b.r && (a.c - b.c).abs() == 1) ||
      (a.c == b.c && (a.r - b.r).abs() == 1);

  void _tapCell(int r, int c) {
    if (_solved) return;
    HapticFeedback.lightImpact();
    final pt = _Pt(r, c);
    setState(() {
      if (_path.isEmpty) {
        _path.add(pt);
      } else if (_path.last.r == r && _path.last.c == c) {
        // tap last → remove it
        _path.removeLast();
      } else if (_isInPath(pt)) {
        // tap earlier → truncate path there
        while (_path.last.r != r || _path.last.c != c) {
          _path.removeLast();
        }
      } else if (_isAdjacent(_path.last, pt)) {
        _path.add(pt);
        _checkSolved();
      }
    });
  }

  int get _currentSum => _path.fold(0, (s, p) => s + _grid[p.r][p.c]);

  void _checkSolved() {
    if (_currentSum == _targetSum && _path.length >= 3) {
      HapticFeedback.heavyImpact();
      _solved = true;
      _gamesWon++;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_difficulty == null) {
      return BrainDifficultySelector(
        gameTitle: 'Sum Snake',
        description: 'Draw a connected path through the grid.\nYour path\'s total must equal the target sum.\nTap cells in sequence to draw your snake!',
        onSelected: _start,
      );
    }
    if (!_countdownDone) {
      return BrainCountdownOverlay(onDone: () => setState(() => _countdownDone = true));
    }

    final sum = _currentSum;
    final diff = _targetSum - sum;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: Column(
        children: [
          BrainGameHUD(
            score: _gamesWon,
            onExit: () => Navigator.of(context).pop(),
            difficultyLabel: _difficulty!.label,
            accentColor: _accent,
          ),
          const SizedBox(height: 20),
          // Target & current sum
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _accent.withValues(alpha: 0.25)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statPill('Target', '$_targetSum', Colors.white),
                Container(width: 1, height: 32, color: Colors.white12),
                _statPill('Current', '$sum',
                    sum == _targetSum ? _accent : Colors.white60),
                Container(width: 1, height: 32, color: Colors.white12),
                _statPill('Need', diff == 0 ? '✓' : (diff > 0 ? '+$diff' : '$diff'),
                    diff == 0 ? _accent : Colors.orange),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: _buildGrid(),
                ),
              ),
            ),
          ),
          if (_solved) _buildSolvedBanner(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _statPill(String label, String val, Color valColor) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Text(label, style: GoogleFonts.poppins(fontSize: 10, color: Colors.white38)),
      const SizedBox(height: 2),
      Text(val, style: GoogleFonts.poppins(
        fontSize: 22, fontWeight: FontWeight.w900, color: valColor)),
    ]);
  }

  Widget _buildGrid() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _accent.withValues(alpha: 0.2), width: 1.5),
        color: Colors.white.withValues(alpha: 0.02),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        children: List.generate(_size, (r) => Expanded(
          child: Row(
            children: List.generate(_size, (c) {
              // ignore: unused_local_variable
              final idx = _path.indexWhere((p) => p.r == r && p.c == c);
              final inPath = idx >= 0;
              final isHead = _path.isNotEmpty && _path.last.r == r && _path.last.c == c;
              return Expanded(
                child: GestureDetector(
                  onTap: () => _tapCell(r, c),
                  child: Container(
                    margin: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: inPath
                          ? _accent.withValues(alpha: isHead ? 0.7 : 0.25)
                          : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: inPath
                            ? _accent.withValues(alpha: 0.8)
                            : Colors.white.withValues(alpha: 0.08),
                        width: inPath ? 1.5 : 0.8,
                      ),
                      boxShadow: isHead ? [BoxShadow(
                        color: _accent.withValues(alpha: 0.5),
                        blurRadius: 12,
                      )] : null,
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Text(
                          '${_grid[r][c]}',
                          style: GoogleFonts.poppins(
                            fontSize: 15, fontWeight: FontWeight.w800,
                            color: inPath ? Colors.white : Colors.white54),
                        ),
                        if (inPath && idx < _path.length - 1)
                          Positioned(
                            bottom: 2, right: 2,
                            child: Text('${idx + 1}',
                              style: GoogleFonts.poppins(
                                fontSize: 8, color: Colors.white60)),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        )),
      ),
    );
  }

  Widget _buildSolvedBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [_accent, _accent.withValues(alpha: 0.7)]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: _accent.withValues(alpha: 0.4), blurRadius: 20)],
      ),
      child: Row(children: [
        const Text('🐍', style: TextStyle(fontSize: 28)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Sum Matched!', style: GoogleFonts.poppins(
            fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
          Text('Path sum = $_targetSum  ·  $_gamesWon solved',
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70)),
        ])),
        GestureDetector(
          onTap: () => setState(() {
            _path.clear();
            _generatePuzzle();
          }),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: Text('Next', style: GoogleFonts.poppins(
              fontSize: 13, fontWeight: FontWeight.w800, color: _accent)),
          ),
        ),
      ]),
    );
  }
}

class _Pt {
  final int r, c;
  const _Pt(this.r, this.c);
}

