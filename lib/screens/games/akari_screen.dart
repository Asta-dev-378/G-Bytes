// akari_screen.dart
// Ported from sidhant947/puzzle — Akari (Light Up)
// Place light bulbs in white cells. Light shines in 4 directions until blocked.
// All white cells must be lit. Numbered black cells must have exactly N adjacent bulbs.

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'brain_game_shared.dart';

// Cell types
const int _kEmpty   = 0; // white cell, no bulb
const int _kBulb    = 1; // bulb placed by player
const int _kBlack   = 2; // black wall, no constraint
const int _kW0      = 3; // black wall with 0 adjacent bulbs required
// _kW0..7 represent walls requiring 0..4 adjacent bulbs respectively

class AkariScreen extends StatefulWidget {
  const AkariScreen({super.key});
  @override
  State<AkariScreen> createState() => _AkariScreenState();
}

class _AkariScreenState extends State<AkariScreen> {
  // ignore: unused_field
  static const _gameId = 'akari';

  BrainDifficulty? _difficulty;
  bool _countdownDone = false;

  late int _size;
  late List<List<int>> _grid;
  bool _solved = false;
  int _gamesWon = 0;

  Color get _accent => const Color(0xFFF59E0B);

  void _start(BrainDifficulty d) {
    _difficulty = d;
    _size = switch (d) {
      BrainDifficulty.easy   => 5,
      BrainDifficulty.medium => 7,
      BrainDifficulty.hard   => 9,
    };
    _generatePuzzle();
    setState(() {});
  }

  // ── PUZZLE GENERATION ────────────────────────────────────────────────────────

  void _generatePuzzle() {
    final rng = Random();
    final n = _size;

    // Start with a valid solved puzzle then remove the bulbs to create the question
    // Step 1: Create grid — some black walls, rest white
    _grid = List.generate(n, (_) => List.filled(n, _kEmpty));
    final numBlack = switch (_difficulty!) {
      BrainDifficulty.easy   => n * n ~/ 5,
      BrainDifficulty.medium => n * n ~/ 4,
      BrainDifficulty.hard   => n * n ~/ 3,
    };
    final positions = List.generate(n * n, (i) => i)..shuffle(rng);
    for (int i = 0; i < numBlack; i++) {
      final r = positions[i] ~/ n;
      final c = positions[i] % n;
      _grid[r][c] = _kBlack;
    }

    // Step 2: Place bulbs in white cells to illuminate everything
    final solution = List.generate(n, (r) => List.generate(n, (c) => _grid[r][c]));
    _placeBulbsSolve(solution, rng);

    // Step 3: Add numbered walls based on adjacent bulbs
    for (int r = 0; r < n; r++) {
      for (int c = 0; c < n; c++) {
        if (_grid[r][c] == _kBlack && rng.nextDouble() < 0.5) {
          int count = 0;
          for (final d in [[-1,0],[1,0],[0,-1],[0,1]]) {
            final nr = r + d[0]; final nc = c + d[1];
            if (nr >= 0 && nr < n && nc >= 0 && nc < n && solution[nr][nc] == _kBulb) count++;
          }
          _grid[r][c] = _kW0 + count;
        }
      }
    }

    // Player sees the grid without bulbs
    _solved = false;
  }

  void _placeBulbsSolve(List<List<int>> b, Random rng) {
    final n = b.length;
    final white = <List<int>>[];
    for (int r = 0; r < n; r++) {
      for (int c = 0; c < n; c++) {
        if (b[r][c] == _kEmpty) white.add([r, c]);
      }
    }
    white.shuffle(rng);
    for (final pos in white) {
      final r = pos[0]; final c = pos[1];
      if (!_isLit(b, r, c)) {
        b[r][c] = _kBulb;
      }
    }
  }

  bool _isLit(List<List<int>> b, int r, int c) {
    final n = b.length;
    if (b[r][c] == _kBulb) return true;
    // check 4 directions for a bulb
    for (final dir in [[-1,0],[1,0],[0,-1],[0,1]]) {
      int nr = r + dir[0]; int nc = c + dir[1];
      while (nr >= 0 && nr < n && nc >= 0 && nc < n) {
        if (b[nr][nc] >= _kBlack) break;
        if (b[nr][nc] == _kBulb) return true;
        nr += dir[0]; nc += dir[1];
      }
    }
    return false;
  }

  bool _isBlack(int v) => v >= _kBlack;

  // ── INTERACTION ──────────────────────────────────────────────────────────────

  void _tapCell(int r, int c) {
    if (_isBlack(_grid[r][c]) || _solved) return;
    HapticFeedback.lightImpact();
    setState(() {
      _grid[r][c] = _grid[r][c] == _kBulb ? _kEmpty : _kBulb;
      _checkSolved();
    });
  }

  // ── GAME LOGIC ───────────────────────────────────────────────────────────────

  Set<String> _litCells() {
    final n = _size;
    final lit = <String>{};
    for (int r = 0; r < n; r++) {
      for (int c = 0; c < n; c++) {
        if (_grid[r][c] == _kBulb) {
          lit.add('$r,$c');
          for (final dir in [[-1,0],[1,0],[0,-1],[0,1]]) {
            int nr = r + dir[0]; int nc = c + dir[1];
            while (nr >= 0 && nr < n && nc >= 0 && nc < n) {
              if (_isBlack(_grid[nr][nc])) break;
              lit.add('$nr,$nc');
              nr += dir[0]; nc += dir[1];
            }
          }
        }
      }
    }
    return lit;
  }

  bool _bulbConflict(int r, int c) {
    final n = _size;
    for (final dir in [[-1,0],[1,0],[0,-1],[0,1]]) {
      int nr = r + dir[0]; int nc = c + dir[1];
      while (nr >= 0 && nr < n && nc >= 0 && nc < n) {
        if (_isBlack(_grid[nr][nc])) break;
        if (_grid[nr][nc] == _kBulb) return true;
        nr += dir[0]; nc += dir[1];
      }
    }
    return false;
  }

  int _adjacentBulbs(int r, int c) {
    int count = 0;
    final n = _size;
    for (final d in [[-1,0],[1,0],[0,-1],[0,1]]) {
      final nr = r + d[0]; final nc = c + d[1];
      if (nr >= 0 && nr < n && nc >= 0 && nc < n && _grid[nr][nc] == _kBulb) count++;
    }
    return count;
  }

  bool _wallSatisfied(int r, int c) {
    final v = _grid[r][c];
    if (v < _kW0) return false;
    final req = v - _kW0;
    return _adjacentBulbs(r, c) == req;
  }

  void _checkSolved() {
    final n = _size;
    final lit = _litCells();

    // All white cells must be lit
    for (int r = 0; r < n; r++) {
      for (int c = 0; c < n; c++) {
        if (!_isBlack(_grid[r][c]) && !lit.contains('$r,$c')) return;
        if (_grid[r][c] == _kBulb && _bulbConflict(r, c)) return;
      }
    }
    // All numbered walls satisfied
    for (int r = 0; r < n; r++) {
      for (int c = 0; c < n; c++) {
        if (_grid[r][c] >= _kW0 && !_wallSatisfied(r, c)) return;
      }
    }

    _solved = true;
    _gamesWon++;
    HapticFeedback.heavyImpact();
  }

  // ── BUILD ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_difficulty == null) {
      return BrainDifficultySelector(
        gameTitle: 'Akari · Light Up',
        description: 'Place light bulbs in white cells.\nEvery cell must be illuminated.\nNumbered black cells must have exactly that many adjacent bulbs.',
        onSelected: _start,
      );
    }
    if (!_countdownDone) {
      return BrainCountdownOverlay(onDone: () => setState(() => _countdownDone = true));
    }

    final lit = _litCells();

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
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('💡', style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text('Tap to place / remove bulbs',
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.white38)),
            ]),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: _buildGrid(lit),
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

  Widget _buildGrid(Set<String> lit) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: Column(
          children: List.generate(_size, (r) => Expanded(
            child: Row(
              children: List.generate(_size, (c) {
                final v = _grid[r][c];
                final isBlack = _isBlack(v);
                final isBulb = v == _kBulb;
                final isLit = lit.contains('$r,$c');
                final conflict = isBulb && _bulbConflict(r, c);
                final wallOk = isBlack && v >= _kW0 && _wallSatisfied(r, c);
                final wallFail = isBlack && v >= _kW0 && _adjacentBulbs(r, c) > v - _kW0;

                Color bg;
                if (isBlack) {
                  bg = wallFail ? Colors.red.withValues(alpha: 0.4)
                      : wallOk ? Colors.green.withValues(alpha: 0.2)
                      : const Color(0xFF1C1C28);
                } else if (conflict) {
                  bg = Colors.red.withValues(alpha: 0.3);
                } else if (isLit) {
                  bg = _accent.withValues(alpha: isBulb ? 0.5 : 0.15);
                } else {
                  bg = Colors.white.withValues(alpha: 0.04);
                }

                return Expanded(
                  child: GestureDetector(
                    onTap: () => _tapCell(r, c),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.all(1),
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: isBlack ? Colors.transparent : Colors.white.withValues(alpha: 0.06)),
                        boxShadow: isBulb && !conflict ? [
                          BoxShadow(color: _accent.withValues(alpha: 0.6), blurRadius: 8)
                        ] : null,
                      ),
                      child: Center(child: _cellContent(v, wallOk, wallFail)),
                    ),
                  ),
                );
              }),
            ),
          )),
        ),
      ),
    );
  }

  Widget _cellContent(int v, bool wallOk, bool wallFail) {
    if (v == _kBulb) {
      return Text('💡', style: TextStyle(fontSize: _size <= 5 ? 20 : _size <= 7 ? 16 : 12));
    }
    if (v >= _kW0) {
      return Text('${v - _kW0}',
        style: GoogleFonts.poppins(
          fontSize: _size <= 5 ? 16 : 13,
          fontWeight: FontWeight.w900,
          color: wallFail ? Colors.red.shade300 : wallOk ? Colors.green.shade300 : Colors.white60));
    }
    return const SizedBox.shrink();
  }

  Widget _buildSolvedBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [_accent, _accent.withValues(alpha: 0.7)]),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: _accent.withValues(alpha: 0.4), blurRadius: 20)],
      ),
      child: Row(children: [
        const Text('✨', style: TextStyle(fontSize: 26)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Illuminated!', style: GoogleFonts.poppins(
            fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
          Text('$_gamesWon puzzle${_gamesWon == 1 ? '' : 's'} solved',
            style: GoogleFonts.poppins(fontSize: 11, color: Colors.white70)),
        ])),
        GestureDetector(
          onTap: () => setState(() {
            _solved = false;
            _generatePuzzle();
          }),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
            child: Text('Next', style: GoogleFonts.poppins(
              fontSize: 12, fontWeight: FontWeight.w800, color: _accent)),
          ),
        ),
      ]),
    );
  }
}
