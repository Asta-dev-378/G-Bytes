// action_sequence_recall_screen.dart
// Ported from sidhant947/puzzle — Action Sequence Recall
// Watch a sequence of colored shape+direction actions. Repeat the sequence!

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'brain_game_shared.dart';

class ActionSequenceRecallScreen extends StatefulWidget {
  const ActionSequenceRecallScreen({super.key});
  @override
  State<ActionSequenceRecallScreen> createState() => _ActionSequenceRecallScreenState();
}

class _ActionSequenceRecallScreenState extends State<ActionSequenceRecallScreen>
    with SingleTickerProviderStateMixin {
  // ignore: unused_field
  static const _gameId = 'action_sequence_recall';

  BrainDifficulty? _difficulty;
  bool _countdownDone = false;

  late List<_Action> _sequence;
  final List<_Action> _playerInput = [];
  bool _displaying = false;
  bool _inputPhase = false;
  int _displayIdx = -1;
  bool _correct = false;
  bool _failed = false;
  int _round = 1;
  int _bestRound = 0;
  int _score = 0;

  late AnimationController _highlightCtrl;
  late Animation<double> _highlightAnim;

  Color get _accent => const Color(0xFF10B981);

  @override
  void initState() {
    super.initState();
    _highlightCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 400));
    _highlightAnim = CurvedAnimation(parent: _highlightCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _highlightCtrl.dispose();
    super.dispose();
  }

  void _start(BrainDifficulty d) {
    _difficulty = d;
    _round = 1;
    _score = 0;
    _bestRound = 0;
    _sequence = [];
    _failed = false;
    _playerInput.clear();
    _beginRound();
    setState(() {});
  }

  void _beginRound() {
    // Add one new action to sequence
    final rng = Random();
    _sequence.add(_Action(
      emoji: _Action.shapes[rng.nextInt(_Action.shapes.length)],
      direction: _Action.directions[rng.nextInt(_Action.directions.length)],
      color: _Action.colors[rng.nextInt(_Action.colors.length)],
    ));
    _playerInput.clear();
    _correct = false;
    _failed = false;
    _inputPhase = false;
    _displaying = true;
    _displayIdx = -1;
    _displaySequence();
  }

  void _displaySequence() async {
    final delayMs = switch (_difficulty!) {
      BrainDifficulty.easy   => 900,
      BrainDifficulty.medium => 650,
      BrainDifficulty.hard   => 450,
    };
    for (int i = 0; i < _sequence.length; i++) {
      await Future.delayed(Duration(milliseconds: delayMs ~/ 3));
      if (!mounted) return;
      setState(() => _displayIdx = i);
      _highlightCtrl.forward(from: 0);
      HapticFeedback.lightImpact();
      await Future.delayed(Duration(milliseconds: (delayMs * 0.7).round()));
      if (!mounted) return;
      setState(() => _displayIdx = -1);
    }
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    setState(() {
      _displaying = false;
      _inputPhase = true;
    });
  }

  void _tapAction(_Action a) {
    if (!_inputPhase || _correct || _failed) return;
    HapticFeedback.lightImpact();
    final idx = _playerInput.length;
    final expected = _sequence[idx];

    setState(() {
      _playerInput.add(a);
      if (a != expected) {
        _failed = true;
        _inputPhase = false;
        if (_round - 1 > _bestRound) _bestRound = _round - 1;
        HapticFeedback.heavyImpact();
      } else if (_playerInput.length == _sequence.length) {
        _correct = true;
        _score += _round;
        _inputPhase = false;
        HapticFeedback.heavyImpact();
        Future.delayed(const Duration(milliseconds: 1200), () {
          if (!mounted) return;
          setState(() {
            _round++;
            _beginRound();
          });
        });
      }
    });
  }

  // Available tap actions (same pool as possible sequence actions)
  static final _allActions = <_Action>[
    for (final emoji in _Action.shapes)
      for (final dir in _Action.directions)
        for (final color in _Action.colors)
          _Action(emoji: emoji, direction: dir, color: color),
  ];

  // We show a compact pad of actions — 4 shapes × 4 directions = 16 combos shown in grid
  // For simplicity show the shapes and let player tap the shown combination
  late List<_Action> _padActions;

  void _buildPad() {
    // Show just directional + shape combos that exist in sequence + some distractors
    final rng = Random();
    final seqSet = _sequence.toSet();
    final distractors = _allActions
        .where((a) => !seqSet.contains(a))
        .toList()..shuffle(rng);
    final padSet = {...seqSet, ...distractors.take(max(0, 8 - seqSet.length))}.toList();
    padSet.shuffle(rng);
    _padActions = padSet.take(8).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_difficulty == null) {
      return BrainDifficultySelector(
        gameTitle: 'Action Sequence',
        description: 'Watch the sequence of colored shape actions.\nThen repeat them in the exact same order!\nThe sequence grows by one each round.',
        onSelected: _start,
      );
    }
    if (!_countdownDone) {
      return BrainCountdownOverlay(onDone: () => setState(() => _countdownDone = true));
    }

    if (!_displaying && _inputPhase && (_padActions.isEmpty || _padActions.length < 4)) {
      _buildPad();
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: Column(
        children: [
          BrainGameHUD(
            score: _score,
            timerText: 'Round $_round',
            onExit: () => Navigator.of(context).pop(),
            difficultyLabel: _difficulty!.label,
            accentColor: _accent,
          ),
          const SizedBox(height: 16),

          // Sequence display area
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_displaying ? 'Watch carefully...' : _inputPhase ? 'Repeat the sequence!' : _correct ? '✓ Correct!' : _failed ? '✗ Wrong!' : '',
                  style: GoogleFonts.poppins(fontSize: 14, color: Colors.white38)),
                const SizedBox(height: 10),
                SizedBox(
                  height: 68,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _sequence.length,
                    itemBuilder: (_, i) {
                      final a = _sequence[i];
                      final isHighlighted = i == _displayIdx;
                      final isPlayerInput = i < _playerInput.length;
                      final isCorrect = isPlayerInput && _playerInput[i] == _sequence[i];
                      final isFailed = isPlayerInput && _playerInput[i] != _sequence[i];
                      return AnimatedBuilder(
                        animation: _highlightAnim,
                        builder: (ctx, _) => Container(
                          width: 60, height: 60,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: isHighlighted
                                ? a.color.withValues(alpha: 0.7)
                                : isFailed
                                    ? Colors.red.withValues(alpha: 0.3)
                                    : isCorrect
                                        ? _accent.withValues(alpha: 0.3)
                                        : _displaying
                                            ? Colors.white.withValues(alpha: 0.04)
                                            : Colors.white.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isHighlighted
                                  ? a.color
                                  : isCorrect ? _accent
                                  : isFailed ? Colors.red
                                  : Colors.white.withValues(alpha: 0.08),
                              width: isHighlighted ? 2 : 1,
                            ),
                            boxShadow: isHighlighted ? [
                              BoxShadow(color: a.color.withValues(alpha: 0.6), blurRadius: 16)
                            ] : null,
                          ),
                          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Text(isDisplaying || isPlayerInput ? a.emoji : '?',
                              style: const TextStyle(fontSize: 20)),
                            Text(a.arrowEmoji,
                              style: TextStyle(
                                fontSize: 12,
                                color: isHighlighted ? Colors.white : Colors.white38)),
                          ]),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          if (_displaying)
            Expanded(
              child: Center(
                child: AnimatedBuilder(
                  animation: _highlightAnim,
                  builder: (ctx, _) {
                    if (_displayIdx < 0 || _displayIdx >= _sequence.length) {
                      return const SizedBox.shrink();
                    }
                    final a = _sequence[_displayIdx];
                    return Transform.scale(
                      scale: 0.8 + _highlightAnim.value * 0.3,
                      child: Container(
                        width: 140, height: 140,
                        decoration: BoxDecoration(
                          color: a.color.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                          border: Border.all(color: a.color, width: 3),
                          boxShadow: [BoxShadow(color: a.color.withValues(alpha: 0.5), blurRadius: 30)],
                        ),
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Text(a.emoji, style: const TextStyle(fontSize: 48)),
                          Text(a.arrowEmoji, style: TextStyle(fontSize: 28, color: a.color)),
                        ]),
                      ),
                    );
                  },
                ),
              ),
            )
          else if (_inputPhase)
            Expanded(child: _buildInputPad())
          else if (_failed)
            Expanded(child: _buildFailBanner())
          else
            const Expanded(child: SizedBox()),
        ],
      ),
    );
  }

  bool get isDisplaying => _displaying || _displayIdx >= 0;

  Widget _buildInputPad() {
    if (_padActions.isEmpty) _buildPad();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(children: [
        // Progress
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(children: [
            Text('${_playerInput.length} / ${_sequence.length}',
              style: GoogleFonts.poppins(fontSize: 13, color: Colors.white38)),
            const Spacer(),
            if (_bestRound > 0)
              Text('Best: round $_bestRound',
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.white24)),
          ]),
        ),
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4, mainAxisSpacing: 8, crossAxisSpacing: 8),
            itemCount: _padActions.length,
            itemBuilder: (_, i) {
              final a = _padActions[i];
              return GestureDetector(
                onTap: () => _tapAction(a),
                child: Container(
                  decoration: BoxDecoration(
                    color: a.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: a.color.withValues(alpha: 0.35)),
                  ),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(a.emoji, style: const TextStyle(fontSize: 22)),
                    const SizedBox(height: 2),
                    Text(a.arrowEmoji, style: TextStyle(fontSize: 16, color: a.color)),
                  ]),
                ),
              );
            },
          ),
        ),
      ]),
    );
  }

  Widget _buildFailBanner() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.red.withValues(alpha: 0.35)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('❌', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text('Sequence broken!', style: GoogleFonts.poppins(
            fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
          const SizedBox(height: 6),
          Text('Made it to round ${_round - 1}  ·  Score: $_score',
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.white54)),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => _start(_difficulty!),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [_accent, _accent.withValues(alpha: 0.7)]),
                borderRadius: BorderRadius.circular(14)),
              child: Text('Try Again', style: GoogleFonts.poppins(
                fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white)),
            ),
          ),
        ]),
      ),
    );
  }
}

class _Action {
  final String emoji;
  final String direction;
  final Color color;

  const _Action({required this.emoji, required this.direction, required this.color});

  static const shapes  = ['⭐', '🔴', '🔷', '🟩'];
  static const directions = ['↑', '↓', '←', '→'];
  static final colors = [
    const Color(0xFF3B82F6),
    const Color(0xFFEC4899),
    const Color(0xFF10B981),
    const Color(0xFFF59E0B),
  ];

  String get arrowEmoji => direction;

  @override
  bool operator ==(Object other) =>
      other is _Action &&
      emoji == other.emoji &&
      direction == other.direction &&
      color.toARGB32() == other.color.toARGB32();

  @override
  int get hashCode => Object.hash(emoji, direction, color.toARGB32());
}
