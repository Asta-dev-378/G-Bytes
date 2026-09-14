// attentional_blink_screen.dart
// Ported from sidhant947/puzzle — Attentional Blink
// Letters flash rapidly. Two target letters appear. Can you catch both?
// The "blink" window: if T2 appears within ~200-500ms of T1, it's often missed.

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'brain_game_shared.dart';

class AttentionalBlinkScreen extends StatefulWidget {
  const AttentionalBlinkScreen({super.key});
  @override
  State<AttentionalBlinkScreen> createState() => _AttentionalBlinkScreenState();
}

class _AttentionalBlinkScreenState extends State<AttentionalBlinkScreen>
    with SingleTickerProviderStateMixin {
  // ignore: unused_field
  static const _gameId = 'attentional_blink';

  BrainDifficulty? _difficulty;
  bool _countdownDone = false;

  // Stream state
  final List<String> _stream = [];
  int _streamIdx = 0;
  String _currentItem = '';
  // ignore: unused_field
  bool _streaming = false;

  // Targets (numbers among letters)
  late int _t1Position;
  late int _t2Position;
  String _t1 = '';
  String _t2 = '';

  // Response phase
  bool _responsePhase = false;
  String _responseT1 = '';
  String _responseT2 = '';
  bool? _t1Correct;
  bool? _t2Correct;

  int _score = 0;
  int _round = 0;
  static const _totalRounds = 8;
  bool _gameOver = false;

  late AnimationController _flashCtrl;
  late Animation<double> _flashAnim;
  Timer? _streamTimer;

  Color get _accent => const Color(0xFF8B5CF6);

  @override
  void initState() {
    super.initState();
    _flashCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 120));
    _flashAnim = Tween<double>(begin: 1.0, end: 0.0).animate(_flashCtrl);
  }

  @override
  void dispose() {
    _streamTimer?.cancel();
    _flashCtrl.dispose();
    super.dispose();
  }

  void _start(BrainDifficulty d) {
    _difficulty = d;
    _score = 0;
    _round = 0;
    _gameOver = false;
    _nextRound();
    setState(() {});
  }

  void _nextRound() {
    _round++;
    _responsePhase = false;
    _responseT1 = '';
    _responseT2 = '';
    _t1Correct = null;
    _t2Correct = null;
    _streamIdx = 0;
    _currentItem = '';

    final rng = Random();
    final streamLen = switch (_difficulty!) {
      BrainDifficulty.easy   => 12,
      BrainDifficulty.medium => 16,
      BrainDifficulty.hard   => 20,
    };

    // Items: mostly letters, two are digit targets
    final letters = List.generate(26, (i) => String.fromCharCode(65 + i));
    final digits = List.generate(10, (i) => '$i');

    // Pick T1 position (not too early/late), T2 shortly after
    _t1Position = 3 + rng.nextInt(streamLen ~/ 3);
    final lag = switch (_difficulty!) {
      BrainDifficulty.easy   => 4 + rng.nextInt(4), // blink window or safe
      BrainDifficulty.medium => 2 + rng.nextInt(4), // sometimes in blink window
      BrainDifficulty.hard   => 1 + rng.nextInt(3), // often in blink window
    };
    _t2Position = _t1Position + lag;
    if (_t2Position >= streamLen - 1) _t2Position = streamLen - 2;

    _t1 = digits[rng.nextInt(10)];
    do { _t2 = digits[rng.nextInt(10)]; } while (_t2 == _t1);

    _stream.clear();
    for (int i = 0; i < streamLen; i++) {
      if (i == _t1Position) {
        _stream.add(_t1);
      } else if (i == _t2Position) {
        _stream.add(_t2);
      } else {
        _stream.add(letters[rng.nextInt(26)]);
      }
    }

    _startStream();
  }

  void _startStream() {
    _streaming = true;
    final intervalMs = switch (_difficulty!) {
      BrainDifficulty.easy   => 300,
      BrainDifficulty.medium => 200,
      BrainDifficulty.hard   => 140,
    };

    _streamTimer?.cancel();
    _streamTimer = Timer.periodic(Duration(milliseconds: intervalMs), (t) {
      if (!mounted) { t.cancel(); return; }
      if (_streamIdx >= _stream.length) {
        t.cancel();
        setState(() {
          _streaming = false;
          _currentItem = '';
          _responsePhase = true;
        });
        return;
      }
      setState(() {
        _currentItem = _stream[_streamIdx];
      });
      _flashCtrl.forward(from: 0).then((_) => _flashCtrl.reverse());
      _streamIdx++;
    });
  }

  void _submitResponse() {
    final correct1 = _responseT1 == _t1;
    final correct2 = _responseT2 == _t2;
    HapticFeedback.lightImpact();
    setState(() {
      _t1Correct = correct1;
      _t2Correct = correct2;
      if (correct1) _score++;
      if (correct2) _score++;
    });

    Future.delayed(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      setState(() {
        if (_round >= _totalRounds) {
          _gameOver = true;
        } else {
          _nextRound();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_difficulty == null) {
      return BrainDifficultySelector(
        gameTitle: 'Attentional Blink',
        description: 'Letters flash rapidly on screen.\nTwo digits appear — catch both!\nThe tricky part: if the 2nd digit appears right after the 1st, your brain may "blink" and miss it.',
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
            score: _score,
            timerText: 'Round $_round/$_totalRounds',
            onExit: () => Navigator.of(context).pop(),
            difficultyLabel: _difficulty!.label,
            accentColor: _accent,
          ),
          Expanded(
            child: _gameOver
                ? _buildGameOver()
                : _responsePhase
                    ? _buildResponsePhase()
                    : _buildStreamPhase(),
          ),
        ],
      ),
    );
  }

  Widget _buildStreamPhase() {
    final isTarget = _currentItem.contains(RegExp(r'[0-9]'));
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text('Watch for the digits!',
        style: GoogleFonts.poppins(fontSize: 13, color: Colors.white38)),
      const SizedBox(height: 60),
      FadeTransition(
        opacity: _flashAnim,
        child: Container(
          width: 160, height: 160,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isTarget
                ? _accent.withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.04),
            border: Border.all(
              color: isTarget ? _accent : Colors.white12,
              width: isTarget ? 2 : 1,
            ),
            boxShadow: isTarget ? [
              BoxShadow(color: _accent.withValues(alpha: 0.5), blurRadius: 30)
            ] : null,
          ),
          child: Center(
            child: Text(_currentItem,
              style: GoogleFonts.poppins(
                fontSize: 72, fontWeight: FontWeight.w900,
                color: isTarget ? _accent : Colors.white70)),
          ),
        ),
      ),
      const SizedBox(height: 60),
      // Position indicator
      Row(mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_stream.length, (i) => Container(
          width: 6, height: 6,
          margin: const EdgeInsets.symmetric(horizontal: 1.5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: i < _streamIdx
                ? _accent.withValues(alpha: 0.6)
                : Colors.white.withValues(alpha: 0.1),
          ),
        )),
      ),
    ]);
  }

  Widget _buildResponsePhase() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text('What were the two digits?',
          style: GoogleFonts.poppins(
            fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
        const SizedBox(height: 8),
        Text('Enter them in the order they appeared',
          style: GoogleFonts.poppins(fontSize: 13, color: Colors.white38)),
        const SizedBox(height: 32),

        // Input fields
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _digitInput('1st digit', _responseT1, _t1Correct, (v) {
            setState(() => _responseT1 = v);
          }),
          const SizedBox(width: 20),
          _digitInput('2nd digit', _responseT2, _t2Correct, (v) {
            setState(() => _responseT2 = v);
          }),
        ]),
        const SizedBox(height: 32),

        // Digit pad
        ..._buildDigitPad(),

        const SizedBox(height: 24),
        if (_t1Correct == null)
          GestureDetector(
            onTap: _responseT1.isNotEmpty && _responseT2.isNotEmpty ? _submitResponse : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [_accent, _accent.withValues(alpha: 0.7)]),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: _accent.withValues(alpha: 0.35), blurRadius: 16)],
              ),
              child: Text('Submit', style: GoogleFonts.poppins(
                fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
            ),
          )
        else
          Text(
            '1st: ${_t1Correct! ? '✓ Correct' : '✗ Was $_t1'}'
            '   2nd: ${_t2Correct! ? '✓ Correct' : '✗ Was $_t2'}',
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.white70)),
      ]),
    );
  }

  Widget _digitInput(String label, String val, bool? correct, Function(String) onChanged) {
    final borderColor = correct == null
        ? _accent.withValues(alpha: 0.3)
        : correct ? Colors.green : Colors.red;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Text(label, style: GoogleFonts.poppins(fontSize: 11, color: Colors.white38)),
      const SizedBox(height: 6),
      Container(
        width: 70, height: 70,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: 2),
        ),
        child: Center(
          child: Text(val,
            style: GoogleFonts.poppins(
              fontSize: 32, fontWeight: FontWeight.w900,
              color: correct == null ? Colors.white : correct ? Colors.green.shade300 : Colors.red.shade300)),
        ),
      ),
    ]);
  }

  List<Widget> _buildDigitPad() {
    // Which input to fill: if T1 empty, fill T1; else T2
    void onDigit(String d) {
      if (_t1Correct != null) return;
      setState(() {
        if (_responseT1.isEmpty) {
          _responseT1 = d;
        } else if (_responseT2.isEmpty) {
          _responseT2 = d;
        }
      });
    }
    void onBack() {
      if (_t1Correct != null) return;
      setState(() {
        if (_responseT2.isNotEmpty) _responseT2 = '';
        else if (_responseT1.isNotEmpty) _responseT1 = '';
      });
    }

    return [
      Row(mainAxisAlignment: MainAxisAlignment.center,
        children: ['1','2','3','4','5'].map((d) => _padBtn(d, () => onDigit(d))).toList()),
      const SizedBox(height: 8),
      Row(mainAxisAlignment: MainAxisAlignment.center,
        children: ['6','7','8','9','0'].map((d) => _padBtn(d, () => onDigit(d))).toList()),
      const SizedBox(height: 8),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        _padBtn('⌫', onBack, wide: true),
      ]),
    ];
  }

  Widget _padBtn(String label, VoidCallback fn, {bool wide = false}) {
    return GestureDetector(
      onTap: fn,
      child: Container(
        width: wide ? 100 : 52, height: 44,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Center(child: Text(label,
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white))),
      ),
    );
  }

  Widget _buildGameOver() {
    final pct = (_score / (_totalRounds * 2) * 100).round();
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [_accent, _accent.withValues(alpha: 0.7)]),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: _accent.withValues(alpha: 0.4), blurRadius: 30)],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('👁️', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          Text('Game Over', style: GoogleFonts.poppins(
            fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white)),
          const SizedBox(height: 8),
          Text('$_score / ${_totalRounds * 2} targets caught',
            style: GoogleFonts.poppins(fontSize: 16, color: Colors.white70)),
          Text('$pct% detection rate',
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.white54)),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () => _start(_difficulty!),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Text('Play Again', style: GoogleFonts.poppins(
                fontSize: 15, fontWeight: FontWeight.w800, color: _accent)),
            ),
          ),
        ]),
      ),
    );
  }
}

