// countdown_math_screen.dart
// Ported from sidhant947/puzzle — Countdown Math
// Given 6 numbers, make the target using +, -, *, ÷ in 60 seconds.

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'brain_game_shared.dart';

class CountdownMathScreen extends StatefulWidget {
  const CountdownMathScreen({super.key});
  @override
  State<CountdownMathScreen> createState() => _CountdownMathScreenState();
}

class _CountdownMathScreenState extends State<CountdownMathScreen> {
  // ignore: unused_field
  static const _gameId = 'countdown_math';

  BrainDifficulty? _difficulty;
  bool _countdownDone = false;

  late int _target;
  late List<int> _numbers;
  List<int> _used = [];   // indices of used numbers
  List<String> _ops = []; // operators between numbers
  String _expression = '';
  int? _result;
  bool _correct = false;
  bool _gameOver = false;
  int _score = 0;
  int _round = 1;

  // Timer
  int _secondsLeft = 60;
  Timer? _timer;

  Color get _accent => const Color(0xFFF59E0B);

  void _start(BrainDifficulty d) {
    _difficulty = d;
    _secondsLeft = switch (d) {
      BrainDifficulty.easy   => 90,
      BrainDifficulty.medium => 60,
      BrainDifficulty.hard   => 45,
    };
    _generateRound();
    setState(() {});
    _startTimer();
  }

  void _generateRound() {
    final rng = Random();
    // Large numbers (25, 50, 75, 100) and small (1-10)
    final large = [25, 50, 75, 100];
    final numLarge = switch (_difficulty!) {
      BrainDifficulty.easy   => 1,
      BrainDifficulty.medium => 2,
      BrainDifficulty.hard   => 2,
    };
    final chosen = <int>[];
    final largeCopy = [...large]..shuffle(rng);
    chosen.addAll(largeCopy.take(numLarge));
    while (chosen.length < 6) {
      chosen.add(rng.nextInt(10) + 1);
    }
    chosen.shuffle(rng);
    _numbers = chosen;
    _target = switch (_difficulty!) {
      BrainDifficulty.easy   => rng.nextInt(100) + 100,   // 100-199
      BrainDifficulty.medium => rng.nextInt(500) + 200,   // 200-699
      BrainDifficulty.hard   => rng.nextInt(700) + 300,   // 300-999
    };
    _used = [];
    _ops = [];
    _expression = '';
    _result = null;
    _correct = false;
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        _secondsLeft--;
        if (_secondsLeft <= 0) {
          t.cancel();
          _gameOver = true;
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _tapNumber(int index) {
    if (_correct || _gameOver) return;
    if (_used.contains(index)) return;
    // need operator first if we already have numbers
    if (_used.isNotEmpty && _ops.length < _used.length) return;
    HapticFeedback.lightImpact();
    setState(() {
      _used.add(index);
      _expression += _numbers[index].toString();
      _evaluate();
    });
  }

  void _tapOp(String op) {
    if (_correct || _gameOver) return;
    if (_used.isEmpty) return;
    if (_ops.length >= _used.length) return; // already have pending op
    HapticFeedback.lightImpact();
    setState(() {
      _ops.add(op);
      _expression += ' $op ';
    });
  }

  void _evaluate() {
    try {
      // Build expression and eval
      final parts = _expression.trim().split(' ');
      if (parts.isEmpty) return;
      double val = double.parse(parts[0]);
      for (int i = 1; i < parts.length - 1; i += 2) {
        final op = parts[i];
        final n = double.parse(parts[i + 1]);
        if (op == '+') val += n;
        else if (op == '-') val -= n;
        else if (op == '×') val *= n;
        else if (op == '÷') { if (n == 0) return; val /= n; }
      }
      if (val == val.roundToDouble()) {
        _result = val.round();
        if (_result == _target) {
          _correct = true;
          _score++;
          HapticFeedback.heavyImpact();
        }
      }
    } catch (_) {}
  }

  void _undo() {
    if (_expression.isEmpty) return;
    setState(() {
      if (_ops.length < _used.length) {
        // last thing added was a number
        _used.removeLast();
        // remove number chars from expression
        final s = _expression.trimRight();
        final last = s.split(' ').last;
        _expression = s.substring(0, (s.length - last.length)).trimRight();
      } else {
        // last thing was an operator
        _ops.removeLast();
        _expression = _expression.trimRight();
        // remove ' OP'
        _expression = _expression.substring(0, _expression.lastIndexOf(' ')).trimRight();
      }
      _result = null;
      if (!_expression.isEmpty) _evaluate();
    });
  }

  void _clear() {
    setState(() {
      _used = [];
      _ops = [];
      _expression = '';
      _result = null;
    });
  }

  void _nextRound() {
    setState(() {
      _round++;
      _generateRound();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_difficulty == null) {
      return BrainDifficultySelector(
        gameTitle: 'Countdown Math',
        description: 'Use the given numbers and +, −, ×, ÷ to reach the target!\nTap numbers then operators to build your expression.',
        onSelected: _start,
      );
    }
    if (!_countdownDone) {
      return BrainCountdownOverlay(onDone: () => setState(() => _countdownDone = true));
    }

    final pct = _secondsLeft / switch (_difficulty!) {
      BrainDifficulty.easy   => 90.0,
      BrainDifficulty.medium => 60.0,
      BrainDifficulty.hard   => 45.0,
    };

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: Column(
        children: [
          BrainGameHUD(
            score: _score,
            timerText: '${_secondsLeft}s',
            progress: pct.clamp(0.0, 1.0),
            onExit: () => Navigator.of(context).pop(),
            difficultyLabel: _difficulty!.label,
            accentColor: _accent,
          ),
          const SizedBox(height: 20),

          // Target
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                _accent.withValues(alpha: 0.15), _accent.withValues(alpha: 0.05)]),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _accent.withValues(alpha: 0.35)),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('Target  ', style: GoogleFonts.poppins(
                fontSize: 14, color: Colors.white38, fontWeight: FontWeight.w600)),
              Text('$_target', style: GoogleFonts.poppins(
                fontSize: 40, fontWeight: FontWeight.w900, color: _accent)),
              const SizedBox(width: 12),
              Text('Round $_round', style: GoogleFonts.poppins(
                fontSize: 12, color: Colors.white30)),
            ]),
          ),
          const SizedBox(height: 16),

          // Expression display
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            constraints: const BoxConstraints(minHeight: 56),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _correct ? _accent : Colors.white.withValues(alpha: 0.08)),
            ),
            child: Row(children: [
              Expanded(
                child: Text(
                  _expression.isEmpty ? 'Tap numbers to start...' : _expression,
                  style: GoogleFonts.poppins(
                    fontSize: 18, fontWeight: FontWeight.w700,
                    color: _expression.isEmpty ? Colors.white24 : Colors.white),
                ),
              ),
              if (_result != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (_result == _target ? _accent : Colors.white12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('= $_result',
                    style: GoogleFonts.poppins(
                      fontSize: 16, fontWeight: FontWeight.w800,
                      color: _result == _target ? Colors.white : Colors.white60)),
                ),
            ]),
          ),
          const SizedBox(height: 16),

          // Number tiles
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Wrap(
              spacing: 8, runSpacing: 8,
              alignment: WrapAlignment.center,
              children: List.generate(_numbers.length, (i) {
                final used = _used.contains(i);
                return GestureDetector(
                  onTap: () => _tapNumber(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 56, height: 56,
                    decoration: BoxDecoration(
                      color: used
                          ? Colors.white.withValues(alpha: 0.04)
                          : _accent.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: used ? Colors.white12 : _accent.withValues(alpha: 0.6)),
                    ),
                    child: Center(
                      child: Text('${_numbers[i]}',
                        style: GoogleFonts.poppins(
                          fontSize: 18, fontWeight: FontWeight.w800,
                          color: used ? Colors.white24 : Colors.white)),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 16),

          // Operators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: ['+', '−', '×', '÷'].map((op) => GestureDetector(
              onTap: () => _tapOp(op == '−' ? '-' : op == '×' ? '×' : op == '÷' ? '÷' : op),
              child: Container(
                width: 52, height: 52,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                ),
                child: Center(
                  child: Text(op, style: GoogleFonts.poppins(
                    fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
                ),
              ),
            )).toList(),
          ),
          const SizedBox(height: 12),

          // Undo / Clear
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _actionBtn('Undo', Icons.backspace_outlined, _undo),
            const SizedBox(width: 12),
            _actionBtn('Clear', Icons.clear_all_rounded, _clear),
          ]),

          const Spacer(),
          if (_correct) _buildSuccessBanner(),
          if (_gameOver && !_correct) _buildGameOverBanner(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _actionBtn(String label, IconData icon, VoidCallback fn) {
    return GestureDetector(
      onTap: fn,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 16, color: Colors.white54),
          const SizedBox(width: 6),
          Text(label, style: GoogleFonts.poppins(fontSize: 12, color: Colors.white54)),
        ]),
      ),
    );
  }

  Widget _buildSuccessBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [_accent, _accent.withValues(alpha: 0.7)]),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: _accent.withValues(alpha: 0.4), blurRadius: 20)],
      ),
      child: Row(children: [
        const Text('⏱️', style: TextStyle(fontSize: 26)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Target Reached!', style: GoogleFonts.poppins(
            fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
          Text('$_expression = $_target  ·  Score: $_score',
            style: GoogleFonts.poppins(fontSize: 11, color: Colors.white70)),
        ])),
        GestureDetector(
          onTap: _nextRound,
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

  Widget _buildGameOverBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
      ),
      child: Row(children: [
        const Text('⌛', style: TextStyle(fontSize: 24)),
        const SizedBox(width: 10),
        Expanded(child: Text('Time\'s up!  Score: $_score',
          style: GoogleFonts.poppins(fontSize: 14, color: Colors.white70))),
        GestureDetector(
          onTap: () => setState(() {
            _score = 0;
            _round = 1;
            _gameOver = false;
            _secondsLeft = switch (_difficulty!) {
              BrainDifficulty.easy   => 90,
              BrainDifficulty.medium => 60,
              BrainDifficulty.hard   => 45,
            };
            _generateRound();
            _startTimer();
          }),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10)),
            child: Text('Retry', style: GoogleFonts.poppins(
              fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white)),
          ),
        ),
      ]),
    );
  }
}

