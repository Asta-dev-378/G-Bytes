// color_clash_screen.dart — Color Clash (Stroop Effect) Brain Game
// A colored word appears with a mismatched ink color.
// Tap: WORD meaning or INK color — whichever matches the target prompt.
// 60-second session, combo multiplier, high-score tracking.

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../providers/player_progress_provider.dart';
import '../../features/streak/models/daily_task.dart';


// ── Color data ────────────────────────────────────────────────────────────────

class _ColorEntry {
  final String name;
  final Color color;
  const _ColorEntry(this.name, this.color);
}

const _colors = [
  _ColorEntry('RED',    Color(0xFFEF4444)),
  _ColorEntry('BLUE',   Color(0xFF3B82F6)),
  _ColorEntry('GREEN',  Color(0xFF22C55E)),
  _ColorEntry('YELLOW', Color(0xFFFACC15)),
  _ColorEntry('PURPLE', Color(0xFFA855F7)),
  _ColorEntry('ORANGE', Color(0xFFF97316)),
  _ColorEntry('PINK',   Color(0xFFEC4899)),
  _ColorEntry('CYAN',   Color(0xFF06B6D4)),
];

// ── Screen ────────────────────────────────────────────────────────────────────

class ColorClashScreen extends StatefulWidget {
  const ColorClashScreen({super.key});

  @override
  State<ColorClashScreen> createState() => _ColorClashScreenState();
}

class _ColorClashScreenState extends State<ColorClashScreen>
    with SingleTickerProviderStateMixin {
  static const _gameDuration = 60;

  final _rng = Random();

  // Current round
  late _ColorEntry _wordEntry;   // the word shown
  late _ColorEntry _inkEntry;    // the color the word is painted in
  late String _prompt;           // "WORD" or "INK"
  late _ColorEntry _target;      // which color the player must pick

  // State
  bool _running = false;
  bool _finished = false;
  int _timeLeft = _gameDuration;
  int _score = 0;
  int _combo = 0;
  int _bestCombo = 0;
  int _correct = 0;
  int _wrong = 0;
  int _highScore = 0;

  Timer? _timer;
  late AnimationController _feedbackCtrl;
  bool _lastCorrect = true;

  @override
  void initState() {
    super.initState();
    _feedbackCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _loadHighScore();
    _nextRound();
  }

  Future<void> _loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _highScore = prefs.getInt('color_clash_high') ?? 0);
  }

  Future<void> _saveHighScore() async {
    if (_score > _highScore) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('color_clash_high', _score);
      setState(() => _highScore = _score);
    }
  }

  void _nextRound() {
    // Pick two different entries
    _wordEntry = _colors[_rng.nextInt(_colors.length)];
    _ColorEntry ink;
    do { ink = _colors[_rng.nextInt(_colors.length)]; }
    while (ink.name == _wordEntry.name);
    _inkEntry = ink;

    // Prompt: WORD or INK
    _prompt = _rng.nextBool() ? 'WORD' : 'INK';
    _target = _prompt == 'WORD' ? _wordEntry : _inkEntry;
  }

  void _start() {
    setState(() {
      _running = true;
      _finished = false;
      _timeLeft = _gameDuration;
      _score = 0;
      _combo = 0;
      _bestCombo = 0;
      _correct = 0;
      _wrong = 0;
    });
    _nextRound();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_timeLeft <= 1) {
        _endGame();
      } else {
        setState(() => _timeLeft--);
      }
    });
  }

  void _endGame() {
    _timer?.cancel();
    _saveHighScore();
    context.read<PlayerProgressProvider>().markGameComplete(TaskType.mathSprint);

    setState(() {
      _running = false;
      _finished = true;
    });
  }

  void _onChoice(_ColorEntry picked) {
    if (!_running) return;
    HapticFeedback.lightImpact();

    final correct = picked.name == _target.name;
    _lastCorrect = correct;
    _feedbackCtrl.forward(from: 0);

    setState(() {
      if (correct) {
        _combo++;
        _correct++;
        if (_combo > _bestCombo) _bestCombo = _combo;
        // Combo multiplier: x1 base, +0.5 per 3 streak
        final mult = 1 + (_combo ~/ 3) * 0.5;
        _score += (10 * mult).round();
      } else {
        _combo = 0;
        _wrong++;
        _score = max(0, _score - 3);
      }
      _nextRound();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _feedbackCtrl.dispose();
    super.dispose();
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF0A0A0F);
    const accent = Color(0xFF6366F1); // indigo — speed category color

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white70),
          onPressed: () { _timer?.cancel(); Navigator.pop(context); },
        ),
        title: Text('Color Clash',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w800,
              color: Colors.white,
              fontSize: 18,
            )),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '🏆 $_highScore',
                style: GoogleFonts.poppins(
                    color: Colors.amber, fontWeight: FontWeight.w700, fontSize: 14),
              ),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎨', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 20),
            Text('Color Clash',
                style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.white)),
            const SizedBox(height: 12),
            Text(
              'A word appears in a different ink color.\n'
              'If asked for the WORD — tap its meaning.\n'
              'If asked for the INK — tap the ink\'s color.\n'
              'Don\'t be fooled! Build combos for bonus points.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  fontSize: 14, color: Colors.white54, height: 1.6),
            ),
            const SizedBox(height: 36),
            _PrimaryButton(
              label: 'Start – 60s',
              color: accent,
              onTap: _start,
            ),
          ],
        ),
      ),
    );
  }

  // ── Game ───────────────────────────────────────────────────────────────────

  Widget _buildGame(Color accent) {
    // Build answer options: the target + 3 distractors (all unique)
    final options = <_ColorEntry>[_target];
    final pool = List<_ColorEntry>.from(_colors)
      ..removeWhere((c) => c.name == _target.name)
      ..shuffle(_rng);
    options.addAll(pool.take(3));
    options.shuffle(_rng);

    final comboBonus = _combo >= 3;

    return AnimatedBuilder(
      animation: _feedbackCtrl,
      builder: (context, child) {
        final flashAlpha = ((1 - _feedbackCtrl.value) * 40).round();
        final flashColor = _lastCorrect
            ? Colors.green.withAlpha(flashAlpha)
            : Colors.red.withAlpha(flashAlpha);

        return Container(
          color: flashColor,
          child: child,
        );
      },
      child: SafeArea(
        child: Column(
          children: [
            // ── Timer + score bar ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Row(
                children: [
                  // Timer
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: _timeLeft <= 10
                          ? Colors.red.withAlpha(30)
                          : Colors.white.withAlpha(8),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _timeLeft <= 10
                            ? Colors.red.withAlpha(120)
                            : Colors.white24,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.timer_rounded,
                            size: 14,
                            color: _timeLeft <= 10 ? Colors.red : Colors.white54),
                        const SizedBox(width: 4),
                        Text('$_timeLeft',
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                color: _timeLeft <= 10 ? Colors.red : Colors.white)),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Combo
                  if (comboBonus)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: Colors.amber.withAlpha(25),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.amber.withAlpha(120)),
                      ),
                      child: Text('🔥 x${1 + (_combo ~/ 3) * 0.5}',
                          style: GoogleFonts.poppins(
                              color: Colors.amber,
                              fontWeight: FontWeight.w800,
                              fontSize: 12)),
                    ),
                  // Score
                  Text(
                    '$_score',
                    style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.white),
                  ),
                ],
              ),
            ),

            // Time bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _timeLeft / _gameDuration,
                  backgroundColor: Colors.white12,
                  color: _timeLeft <= 10 ? Colors.red : accent,
                  minHeight: 4,
                ),
              ),
            ),

            const Spacer(),

            // ── Prompt ────────────────────────────────────────────────────
            Text(
              'TAP THE $_prompt',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white38,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 32),

            // ── Word display ──────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 28),
              margin: const EdgeInsets.symmetric(horizontal: 40),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(6),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white12),
                boxShadow: [
                  BoxShadow(
                    color: _inkEntry.color.withAlpha(30),
                    blurRadius: 40,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Text(
                _wordEntry.name,
                style: GoogleFonts.poppins(
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  color: _inkEntry.color,
                  shadows: [
                    Shadow(color: _inkEntry.color.withAlpha(180), blurRadius: 24),
                  ],
                ),
              ),
            ),

            const Spacer(),

            // ── Answer buttons ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
              child: GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 2.8,
                physics: const NeverScrollableScrollPhysics(),
                children: options.map((entry) => _AnswerTile(
                  entry: entry,
                  onTap: () => _onChoice(entry),
                )).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Results ────────────────────────────────────────────────────────────────

  Widget _buildResults(Color accent) {
    final newBest = _score >= _highScore;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(newBest ? '🏆' : '🎨', style: const TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text(
              newBest ? 'New Best!' : 'Nice run!',
              style: GoogleFonts.poppins(
                  fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white),
            ),
            const SizedBox(height: 24),
            _StatRow(label: 'Score',       value: '$_score',      accent: accent),
            const SizedBox(height: 8),
            _StatRow(label: 'Best Combo',  value: 'x$_bestCombo', accent: const Color(0xFFFACC15)),
            const SizedBox(height: 8),
            _StatRow(label: 'Correct',     value: '$_correct',    accent: const Color(0xFF22C55E)),
            const SizedBox(height: 8),
            _StatRow(label: 'Wrong',       value: '$_wrong',      accent: Colors.red),
            const SizedBox(height: 8),
            _StatRow(label: 'High Score',  value: '$_highScore',  accent: Colors.amber),
            const SizedBox(height: 36),
            _PrimaryButton(label: 'Play Again', color: accent, onTap: _start),
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

// ── Answer tile ────────────────────────────────────────────────────────────────

class _AnswerTile extends StatefulWidget {
  final _ColorEntry entry;
  final VoidCallback onTap;
  const _AnswerTile({required this.entry, required this.onTap});

  @override
  State<_AnswerTile> createState() => _AnswerTileState();
}

class _AnswerTileState extends State<_AnswerTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _sc;
  @override
  void initState() {
    super.initState();
    _sc = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 100),
        reverseDuration: const Duration(milliseconds: 200));
  }
  @override
  void dispose() { _sc.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _sc.forward(),
      onTapUp: (_) { _sc.reverse(); widget.onTap(); },
      onTapCancel: () => _sc.reverse(),
      child: AnimatedBuilder(
        animation: _sc,
        builder: (_, child) => Transform.scale(
          scale: 1.0 - _sc.value * 0.05,
          child: child,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: widget.entry.color.withAlpha(20),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: widget.entry.color.withAlpha(100), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: widget.entry.color.withAlpha(30),
                blurRadius: 12,
              ),
            ],
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: widget.entry.color,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: widget.entry.color.withAlpha(120), blurRadius: 8)],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  widget.entry.name,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Shared small widgets ──────────────────────────────────────────────────────

class _PrimaryButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _PrimaryButton({required this.label, required this.color, required this.onTap});

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
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white)),
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;
  const _StatRow({required this.label, required this.value, required this.accent});

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
