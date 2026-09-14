// balance_scale_screen.dart
// Ported from sidhant947/puzzle — Balance Scale
// Deduce weight relationships from scale clues. Tap the heavier side or Equal.

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'brain_game_shared.dart';

class BalanceScaleScreen extends StatefulWidget {
  const BalanceScaleScreen({super.key});
  @override
  State<BalanceScaleScreen> createState() => _BalanceScaleScreenState();
}

class _BalanceScaleScreenState extends State<BalanceScaleScreen>
    with TickerProviderStateMixin {
  // ignore: unused_field
  static const _gameId = 'balance_scale';

  BrainDifficulty? _difficulty;
  bool _countdownDone = false;

  late List<_WeightItem> _leftItems;
  late List<_WeightItem> _rightItems;
  late int _correctAnswer; // -1=left heavier, 0=equal, 1=right heavier
  // ignore: unused_field
  int? _playerAnswer;
  bool _showResult = false;
  int _score = 0;
  int _round = 0;
  int _totalRounds = 0;
  bool _gameOver = false;
  String _feedback = '';

  late AnimationController _tiltCtrl;
  late Animation<double> _tilt;

  Color get _accent => const Color(0xFF8B5CF6);

  @override
  void initState() {
    super.initState();
    _tiltCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _tilt = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _tiltCtrl, curve: Curves.elasticOut));
  }

  @override
  void dispose() {
    _tiltCtrl.dispose();
    super.dispose();
  }

  void _start(BrainDifficulty d) {
    _difficulty = d;
    _totalRounds = switch (d) {
      BrainDifficulty.easy   => 6,
      BrainDifficulty.medium => 10,
      BrainDifficulty.hard   => 14,
    };
    _score = 0;
    _round = 0;
    _gameOver = false;
    _nextRound();
    setState(() {});
  }

  void _nextRound() {
    final rng = Random();
    _round++;
    _playerAnswer = null;
    _showResult = false;
    _feedback = '';

    final items = _WeightItem.allItems;
    final numItems = switch (_difficulty!) {
      BrainDifficulty.easy   => 1,
      BrainDifficulty.medium => 2,
      BrainDifficulty.hard   => 3,
    };

    // Pick random items for each side
    final shuffled = [...items]..shuffle(rng);
    _leftItems = shuffled.take(numItems).toList();
    final shuffled2 = [...items]..shuffle(rng);
    _rightItems = shuffled2.take(numItems).toList();

    // Occasionally force equal
    if (rng.nextDouble() < 0.25 && numItems == 1) {
      _rightItems = [_leftItems[0]];
    }

    final leftW = _leftItems.fold(0, (s, i) => s + i.weight);
    final rightW = _rightItems.fold(0, (s, i) => s + i.weight);
    _correctAnswer = leftW > rightW ? -1 : leftW < rightW ? 1 : 0;

    // Animate tilt
    final tiltAngle = _correctAnswer == 0 ? 0.0 : _correctAnswer == -1 ? -0.12 : 0.12;
    _tilt = Tween<double>(begin: 0, end: tiltAngle).animate(
      CurvedAnimation(parent: _tiltCtrl, curve: Curves.elasticOut));
    _tiltCtrl.forward(from: 0);
  }

  void _answer(int ans) {
    if (_showResult) return;
    HapticFeedback.lightImpact();
    final correct = ans == _correctAnswer;
    setState(() {
      _playerAnswer = ans;
      _showResult = true;
      if (correct) {
        _score++;
        _feedback = '✓ Correct!';
        HapticFeedback.heavyImpact();
      } else {
        _feedback = '✗ ${_correctAnswer == -1 ? 'Left was heavier' : _correctAnswer == 1 ? 'Right was heavier' : 'They were equal'}';
      }
    });

    Future.delayed(const Duration(milliseconds: 1400), () {
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
        gameTitle: 'Balance Scale',
        description: 'Which side is heavier?\nUse the items on each tray to decide.\nTap your answer below!',
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
            timerText: 'Round $_round / $_totalRounds',
            onExit: () => Navigator.of(context).pop(),
            difficultyLabel: _difficulty!.label,
            accentColor: _accent,
          ),
          const SizedBox(height: 20),

          // Progress bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: _round / _totalRounds,
                minHeight: 5,
                backgroundColor: Colors.white.withValues(alpha: 0.08),
                valueColor: AlwaysStoppedAnimation(_accent),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Scale visual
          Expanded(
            child: AnimatedBuilder(
              animation: _tiltCtrl,
              builder: (_, __) => Transform.rotate(
                angle: _tilt.value,
                child: _buildScale(),
              ),
            ),
          ),

          // Feedback
          if (_showResult)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(_feedback,
                style: GoogleFonts.poppins(
                  fontSize: 18, fontWeight: FontWeight.w800,
                  color: _feedback.startsWith('✓') ? Colors.green.shade400 : Colors.red.shade400)),
            ),

          // Answer buttons
          if (!_showResult && !_gameOver)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              child: Row(children: [
                Expanded(child: _answerBtn('⬅️ Left Heavier', -1, const Color(0xFFF59E0B))),
                const SizedBox(width: 10),
                Expanded(child: _answerBtn('⚖️ Equal', 0, Colors.white54)),
                const SizedBox(width: 10),
                Expanded(child: _answerBtn('Right Heavier ➡️', 1, const Color(0xFF3B82F6))),
              ]),
            )
          else if (_gameOver)
            _buildGameOver()
          else
            const SizedBox(height: 64),
        ],
      ),
    );
  }

  Widget _buildScale() {
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      // Beam
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        _buildTray(_leftItems, 'Left'),
        Container(
          width: 120, height: 6,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        _buildTray(_rightItems, 'Right'),
      ]),
      const SizedBox(height: 8),
      // Pillar
      Container(width: 8, height: 60,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(4))),
      Container(width: 80, height: 8,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(4))),
    ]);
  }

  Widget _buildTray(List<_WeightItem> items, String side) {
    return Column(mainAxisAlignment: MainAxisAlignment.end, children: [
      Container(
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(minWidth: 90, minHeight: 80),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _accent.withValues(alpha: 0.2)),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Wrap(
            spacing: 4, runSpacing: 4,
            alignment: WrapAlignment.center,
            children: items.map((i) => Text(i.emoji,
              style: const TextStyle(fontSize: 28))).toList(),
          ),
          const SizedBox(height: 6),
          Text(side, style: GoogleFonts.poppins(
            fontSize: 10, color: Colors.white30)),
        ]),
      ),
      // Chain
      Container(width: 2, height: 20, color: Colors.white24),
    ]);
  }

  Widget _answerBtn(String label, int ans, Color color) {
    return GestureDetector(
      onTap: () => _answer(ans),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Text(label,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
      ),
    );
  }

  Widget _buildGameOver() {
    final pct = (_score / _totalRounds * 100).round();
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [_accent, _accent.withValues(alpha: 0.7)]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: _accent.withValues(alpha: 0.4), blurRadius: 20)],
      ),
      child: Column(children: [
        Text('⚖️ Game Over', style: GoogleFonts.poppins(
          fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
        const SizedBox(height: 6),
        Text('$_score / $_totalRounds correct  ·  $pct%',
          style: GoogleFonts.poppins(fontSize: 14, color: Colors.white70)),
        const SizedBox(height: 14),
        GestureDetector(
          onTap: () => _start(_difficulty!),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(14)),
            child: Text('Play Again', style: GoogleFonts.poppins(
              fontSize: 14, fontWeight: FontWeight.w800, color: _accent)),
          ),
        ),
      ]),
    );
  }
}

class _WeightItem {
  final String emoji;
  final int weight;
  const _WeightItem(this.emoji, this.weight);

  static const allItems = [
    _WeightItem('🍎', 3), _WeightItem('🍊', 4), _WeightItem('🍋', 2),
    _WeightItem('🍇', 6), _WeightItem('🍓', 1), _WeightItem('🥝', 3),
    _WeightItem('🍑', 5), _WeightItem('🍒', 2), _WeightItem('🥭', 7),
    _WeightItem('🍍', 8), _WeightItem('🍌', 3), _WeightItem('🥥', 9),
    _WeightItem('🧁', 4), _WeightItem('🍰', 6), _WeightItem('🍫', 3),
    _WeightItem('🍬', 1), _WeightItem('🎂', 10), _WeightItem('🍩', 4),
  ];
}

