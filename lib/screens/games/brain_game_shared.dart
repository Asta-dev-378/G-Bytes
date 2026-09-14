// brain_game_shared.dart
// Shared models, local score storage, and reusable widgets used across
// all brain games in lib/screens/games/.
// Adapted from brain_games/lib/shared.dart for integration into the main app.

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/league.dart';
import '../../providers/player_progress_provider.dart';

// ---------------------------------------------------------------------------
// DIFFICULTY
// ---------------------------------------------------------------------------

enum BrainDifficulty { easy, medium, hard }

extension BrainDifficultyLabel on BrainDifficulty {
  String get label => switch (this) {
        BrainDifficulty.easy => 'Easy',
        BrainDifficulty.medium => 'Medium',
        BrainDifficulty.hard => 'Hard',
      };

  String get emoji => switch (this) {
        BrainDifficulty.easy => 'ðŸŒ±',
        BrainDifficulty.medium => 'âš¡',
        BrainDifficulty.hard => 'ðŸ”¥',
      };
}

// ---------------------------------------------------------------------------
// MODELS
// ---------------------------------------------------------------------------

class BrainGameResult {
  final String gameId;
  final int score;
  final double accuracy; // 0-100
  final int? avgReactionMs;
  final BrainDifficulty difficulty;
  final DateTime playedAt;

  BrainGameResult({
    required this.gameId,
    required this.score,
    required this.accuracy,
    this.avgReactionMs,
    required this.difficulty,
    required this.playedAt,
  });

  Map<String, dynamic> toJson() => {
        'gameId': gameId,
        'score': score,
        'accuracy': accuracy,
        'avgReactionMs': avgReactionMs,
        'difficulty': difficulty.name,
        'playedAt': playedAt.toIso8601String(),
      };

  factory BrainGameResult.fromJson(Map<String, dynamic> j) => BrainGameResult(
        gameId: j['gameId'],
        score: j['score'],
        accuracy: (j['accuracy'] as num).toDouble(),
        avgReactionMs: j['avgReactionMs'],
        difficulty: BrainDifficulty.values.byName(j['difficulty']),
        playedAt: DateTime.parse(j['playedAt']),
      );
}

// ---------------------------------------------------------------------------
// SCORE REPOSITORY
// ---------------------------------------------------------------------------

class BrainScoreRepository {
  BrainScoreRepository._();
  static final BrainScoreRepository instance = BrainScoreRepository._();

  Future<void> save(BrainGameResult result) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'brain_game_${result.gameId}';
    final list = prefs.getStringList(key) ?? [];
    list.add(jsonEncode(result.toJson()));
    // keep last 50 results per game
    final trimmed = list.length > 50 ? list.sublist(list.length - 50) : list;
    await prefs.setStringList(key, trimmed);
  }

  Future<List<BrainGameResult>> history(String gameId) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('brain_game_$gameId') ?? [];
    return list
        .map((s) => BrainGameResult.fromJson(jsonDecode(s)))
        .toList()
        .reversed
        .toList();
  }

  Future<int?> bestScore(String gameId, {bool lowerIsBetter = false}) async {
    final h = await history(gameId);
    if (h.isEmpty) return null;
    final scores = h.map((r) => r.score);
    return lowerIsBetter
        ? scores.reduce((a, b) => a < b ? a : b)
        : scores.reduce((a, b) => a > b ? a : b);
  }
}

// ---------------------------------------------------------------------------
// SHARED WIDGETS
// ---------------------------------------------------------------------------

/// Top HUD shown during gameplay: score, timer/progress, exit button.
/// Premium frosted-glass bar with animated score and coloured time ring.
class BrainGameHUD extends StatefulWidget {
  final int score;
  final String? timerText;
  final double? progress; // 0..1
  final VoidCallback onExit;
  final String? difficultyLabel;
  final Color accentColor;

  const BrainGameHUD({
    super.key,
    required this.score,
    this.timerText,
    this.progress,
    required this.onExit,
    this.difficultyLabel,
    this.accentColor = const Color(0xFFFF6B00),
  });

  @override
  State<BrainGameHUD> createState() => _BrainGameHUDState();
}

class _BrainGameHUDState extends State<BrainGameHUD>
    with SingleTickerProviderStateMixin {
  late AnimationController _scoreCtrl;
  late Animation<double> _scoreBounce;
  int _prevScore = 0;

  @override
  void initState() {
    super.initState();
    _prevScore = widget.score;
    _scoreCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 350));
    _scoreBounce = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _scoreCtrl, curve: Curves.elasticOut));
  }

  @override
  void didUpdateWidget(BrainGameHUD old) {
    super.didUpdateWidget(old);
    if (widget.score != _prevScore) {
      _prevScore = widget.score;
      _scoreCtrl.forward(from: 0).then((_) => _scoreCtrl.reverse());
    }
  }

  @override
  void dispose() {
    _scoreCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pct = widget.progress;
    final timeColor = pct == null
        ? widget.accentColor
        : pct > 0.5
            ? widget.accentColor
            : pct > 0.25
                ? Colors.orange
                : Colors.red;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF2C2C2E).withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Row(
              children: [
                // Exit
                GestureDetector(
                  onTap: widget.onExit,
                  child: Container(
                    width: 34, height: 34,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close_rounded,
                        size: 16, color: Colors.white70),
                  ),
                ),
                const SizedBox(width: 12),
                // Progress bar or timer
                Expanded(
                  child: pct != null
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: pct.clamp(0.0, 1.0),
                                minHeight: 7,
                                backgroundColor:
                                    Colors.white.withValues(alpha: 0.10),
                                valueColor:
                                    AlwaysStoppedAnimation(timeColor),
                              ),
                            ),
                          ],
                        )
                      : Text(
                          widget.timerText ?? '',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: timeColor,
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                // Animated score pill
                ScaleTransition(
                  scale: _scoreBounce,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          widget.accentColor.withValues(alpha: 0.25),
                          widget.accentColor.withValues(alpha: 0.10),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color:
                              widget.accentColor.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star_rounded,
                            color: widget.accentColor, size: 14),
                        const SizedBox(width: 5),
                        Text(
                          '${widget.score}',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (widget.difficultyLabel != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      widget.difficultyLabel!,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white54,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 3-2-1 countdown overlay shown before gameplay starts.
class BrainCountdownOverlay extends StatefulWidget {
  final VoidCallback onDone;
  const BrainCountdownOverlay({super.key, required this.onDone});

  @override
  State<BrainCountdownOverlay> createState() => _BrainCountdownOverlayState();
}

class _BrainCountdownOverlayState extends State<BrainCountdownOverlay>
    with SingleTickerProviderStateMixin {
  int _count = 3;
  late AnimationController _anim;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _scale = Tween<double>(begin: 0.5, end: 1.0).animate(
        CurvedAnimation(parent: _anim, curve: Curves.elasticOut));
    _tick();
  }

  void _tick() async {
    while (_count >= 0) {
      if (!mounted) return;
      _anim.forward(from: 0);
      await Future.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;
      setState(() => _count--);
    }
    widget.onDone();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF05050C).withValues(alpha: 0.96),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Neon pulse ring
            AnimatedBuilder(
              animation: _anim,
              builder: (_, child) => Transform.scale(
                scale: 1.0 + (_scale.value - 1.0) * 0.12,
                child: Container(
                  width: 160, height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.transparent,
                    border: Border.all(
                      color: _count <= 0
                          ? const Color(0xFFFF6B00).withValues(alpha: _scale.value * 0.6)
                          : Colors.white.withValues(alpha: _scale.value * 0.12),
                      width: 2,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 0),
            // Number
            ScaleTransition(
              scale: _scale,
              child: Text(
                _count <= 0 ? 'GO!' : '$_count',
                style: GoogleFonts.poppins(
                  fontSize: 96,
                  fontWeight: FontWeight.w900,
                  color: _count <= 0
                      ? const Color(0xFFFF6B00)
                      : Colors.white,
                  height: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Difficulty picker shown before a game starts.
/// Automatically reads the player's current league tier from
/// [PlayerProgressProvider] and gates which difficulty buttons are interactive.
/// The optional [maxUnlocked] override is only used when the screen is shown
/// outside the normal provider tree (e.g. in tests).
class BrainDifficultySelector extends StatefulWidget {
  final String gameTitle;
  final String description;
  final void Function(BrainDifficulty) onSelected;
  final BrainDifficulty? forcedDifficulty;
  /// Optional override â€” if null the selector reads from [PlayerProgressProvider].
  final BrainDifficultyUnlock? maxUnlocked;

  const BrainDifficultySelector({
    super.key,
    required this.gameTitle,
    required this.description,
    required this.onSelected,
    this.forcedDifficulty,
    this.maxUnlocked,           // no default â†’ auto-read from provider
  });

  @override
  State<BrainDifficultySelector> createState() =>
      _BrainDifficultySelectorState();
}

class _BrainDifficultySelectorState extends State<BrainDifficultySelector> {
  /// Reads the live tier-based unlock level from the provider tree.
  BrainDifficultyUnlock _resolveMaxUnlocked(BuildContext ctx) {
    if (widget.maxUnlocked != null) return widget.maxUnlocked!;
    try {
      final progress = ctx.read<PlayerProgressProvider>();
      return LeagueInfo.maxUnlocked(progress.league.tierIndex);
    } catch (_) {
      // Provider not available (tests / preview) â€” default to all-open.
      return BrainDifficultyUnlock.hard;
    }
  }
  @override
  void initState() {
    super.initState();
    if (widget.forcedDifficulty != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onSelected(widget.forcedDifficulty!);
      });
    }
  }

  bool _isUnlocked(BrainDifficulty d, BrainDifficultyUnlock maxUnlocked) {
    switch (d) {
      case BrainDifficulty.easy:
        return true; // always unlocked
      case BrainDifficulty.medium:
        return maxUnlocked == BrainDifficultyUnlock.medium ||
               maxUnlocked == BrainDifficultyUnlock.hard;
      case BrainDifficulty.hard:
        return maxUnlocked == BrainDifficultyUnlock.hard;
    }
  }

  String _lockHint(BrainDifficulty d) {
    switch (d) {
      case BrainDifficulty.easy:
        return '';
      case BrainDifficulty.medium:
        return 'Reach ${LeagueInfo.mediumUnlockLeague} to unlock';
      case BrainDifficulty.hard:
        return 'Reach ${LeagueInfo.hardUnlockLeague} to unlock';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.forcedDifficulty != null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Resolve the effective unlock level from the player's current league tier.
    final maxUnlocked = _resolveMaxUnlocked(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Game icon with neon glow
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: const Color(0xFFFF6B00).withValues(alpha: 0.4)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF6B00).withValues(alpha: 0.25),
                      blurRadius: 24, spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(Icons.videogame_asset_rounded,
                    color: Color(0xFFFF6B00), size: 36),
              ),
              const SizedBox(height: 20),
              Text(
                widget.gameTitle,
                style: GoogleFonts.poppins(
                  fontSize: 26, fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                widget.description,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14, color: Colors.white38,
                  fontWeight: FontWeight.w500, height: 1.5,
                ),
              ),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  'CHOOSE DIFFICULTY',
                  style: GoogleFonts.poppins(
                    fontSize: 11, fontWeight: FontWeight.w700,
                    color: Colors.white38, letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ...BrainDifficulty.values.map(
                (d) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: SizedBox(
                    width: double.infinity,
                    child: _DifficultyButton(
                      difficulty: d,
                      isUnlocked: _isUnlocked(d, maxUnlocked),
                      lockHint: _lockHint(d),
                      onTap: _isUnlocked(d, maxUnlocked)
                          ? () => widget.onSelected(d)
                          : null,
                    ),
                  ),
                ),
              ),
              if (!_isUnlocked(BrainDifficulty.medium, maxUnlocked)) ...[
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lock_outline_rounded,
                        size: 14, color: Colors.white24),
                    const SizedBox(width: 6),
                    Text(
                      'Keep playing to unlock higher difficulties',
                      style: GoogleFonts.poppins(
                        fontSize: 12, color: Colors.white24,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DifficultyButton extends StatefulWidget {
  final BrainDifficulty difficulty;
  final bool isUnlocked;
  final String lockHint;
  final VoidCallback? onTap;

  const _DifficultyButton({
    required this.difficulty,
    required this.isUnlocked,
    required this.lockHint,
    required this.onTap,
  });

  @override
  State<_DifficultyButton> createState() => _DifficultyButtonState();
}

class _DifficultyButtonState extends State<_DifficultyButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 80));
    _scale = Tween<double>(begin: 1.0, end: 0.94).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Color _bg(BuildContext ctx) => switch (widget.difficulty) {
        BrainDifficulty.easy   => Theme.of(ctx).colorScheme.primary,
        BrainDifficulty.medium => Theme.of(ctx).colorScheme.secondary,
        BrainDifficulty.hard   => const Color(0xFFF5F5F5),
      };

  Color get _fg => switch (widget.difficulty) {
        BrainDifficulty.easy   => const Color(0xFF0F0F0F),
        BrainDifficulty.medium => const Color(0xFF0F0F0F),
        BrainDifficulty.hard   => const Color(0xFF0F0F0F),
      };

  @override
  Widget build(BuildContext context) {
    final locked = !widget.isUnlocked;

    return GestureDetector(
      onTapDown: locked ? null : (_) => _ctrl.forward(),
      onTapUp: locked
          ? null
          : (_) async {
              await _ctrl.reverse();
              widget.onTap?.call();
            },
      onTapCancel: locked ? null : () => _ctrl.reverse(),
      onTap: locked
          ? () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    widget.lockHint,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  backgroundColor: const Color(0xFF1C1C1E),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          : null,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: locked ? 0.44 : 1.0,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 17),
            decoration: BoxDecoration(
              color: locked
                  ? Colors.white.withValues(alpha: 0.04)
                  : _bg(context),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: locked
                    ? Colors.white.withValues(alpha: 0.08)
                    : _bg(context).withValues(alpha: 0.45),
                width: 1.2,
              ),
              boxShadow: locked
                  ? []
                  : [
                      BoxShadow(
                        color: _bg(context).withValues(alpha: 0.45),
                        blurRadius: 20, spreadRadius: 0,
                        offset: const Offset(0, 7),
                      ),
                    ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (locked) ...[
                  const Icon(Icons.lock_rounded,
                      size: 18, color: Colors.white24),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.difficulty.label,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w800, fontSize: 15,
                          color: Colors.white24,
                        ),
                      ),
                      Text(
                        widget.lockHint,
                        style: GoogleFonts.poppins(
                          fontSize: 10, fontWeight: FontWeight.w500,
                          color: Colors.white24,
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  Text(
                    widget.difficulty.emoji,
                    style: const TextStyle(fontSize: 22),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    widget.difficulty.label,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: _fg,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Full-screen animated results report.
class BrainResultsSheet extends StatefulWidget {
  final int score;
  final double accuracy; // 0â€“100
  final int? bestScore;
  final int? avgReactionMs;
  final VoidCallback onPlayAgain;
  final VoidCallback onExit;
  final VoidCallback? onNextDifficulty;
  final String? nextDifficultyLabel;

  const BrainResultsSheet({
    super.key,
    required this.score,
    required this.accuracy,
    this.bestScore,
    this.avgReactionMs,
    required this.onPlayAgain,
    required this.onExit,
    this.onNextDifficulty,
    this.nextDifficultyLabel,
  });

  @override
  State<BrainResultsSheet> createState() => _BrainResultsSheetState();
}

class _BrainResultsSheetState extends State<BrainResultsSheet>
    with TickerProviderStateMixin {
  late AnimationController _entryCtrl;
  late AnimationController _ringCtrl;
  late Animation<double> _slide;
  late Animation<double> _fade;
  late Animation<double> _ring;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _ringCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));

    _slide = Tween<double>(begin: 60, end: 0).animate(
        CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));
    _fade = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _ring = CurvedAnimation(parent: _ringCtrl, curve: Curves.easeOut);

    Future.delayed(const Duration(milliseconds: 120), () {
      if (mounted) {
        _entryCtrl.forward();
        _ringCtrl.forward();
      }
    });
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _ringCtrl.dispose();
    super.dispose();
  }

  String get _headline {
    final acc = widget.accuracy;
    if (acc >= 90) return 'Outstanding! ðŸ†';
    if (acc >= 70) return 'Nice work! ðŸŽ‰';
    if (acc >= 50) return 'Keep going! ðŸ’ª';
    return 'Try again! ðŸ”„';
  }

  String? get _achievementText {
    if (widget.bestScore != null && widget.score > widget.bestScore!) {
      return 'ðŸ”¥ New Personal Best!';
    }
    if (widget.accuracy >= 100) return 'ðŸŽ¯ Perfect Accuracy!';
    if (widget.accuracy >= 90) return 'âš¡ Elite Performance!';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0F0F0F),
      child: SafeArea(
        child: AnimatedBuilder(
          animation: _entryCtrl,
          builder: (_, child) => FadeTransition(
            opacity: _fade,
            child: Transform.translate(
              offset: Offset(0, _slide.value),
              child: child,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [
                // Header
                Row(
                  children: [
                    GestureDetector(
                      onTap: widget.onExit,
                      child: Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded,
                            size: 18, color: Colors.white70),
                      ),
                    ),
                    const Spacer(),
                    Text('Results',
                        style: GoogleFonts.poppins(
                          fontSize: 15, fontWeight: FontWeight.w700,
                          color: Colors.white54)),
                    const Spacer(),
                    const SizedBox(width: 36),
                  ],
                ),
                const SizedBox(height: 28),

                // Accuracy ring
                AnimatedBuilder(
                  animation: _ring,
                  builder: (context, child) => SizedBox(
                    width: 160, height: 160,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: _ring.value * (widget.accuracy / 100),
                          strokeWidth: 12,
                          backgroundColor:
                              Colors.white.withValues(alpha: 0.08),
                          valueColor: AlwaysStoppedAnimation(
                            widget.accuracy >= 80
                                ? const Color(0xFFFF6B00)
                                : widget.accuracy >= 50
                                    ? Colors.amber
                                    : Colors.red,
                          ),
                          strokeCap: StrokeCap.round,
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${(widget.accuracy * _ring.value).toStringAsFixed(0)}%',
                              style: GoogleFonts.poppins(
                                fontSize: 32, fontWeight: FontWeight.w900,
                                color: Colors.white),
                            ),
                            Text('accuracy',
                                style: GoogleFonts.poppins(
                                  fontSize: 11, fontWeight: FontWeight.w600,
                                  color: Colors.white38)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Headline
                Text(_headline,
                    style: GoogleFonts.poppins(
                      fontSize: 22, fontWeight: FontWeight.w900,
                      color: Colors.white)),

                // Achievement badge
                if (_achievementText != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [
                        Color(0xFFFF6B00),
                        Color(0xFFFFB800),
                      ]),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _achievementText!,
                      style: GoogleFonts.poppins(
                        fontSize: 13, fontWeight: FontWeight.w800,
                        color: Colors.white),
                    ),
                  ),
                ],

                const SizedBox(height: 28),

                // Stat cards
                _buildStatCard('Score', '${widget.score}',
                    Icons.star_rounded, const Color(0xFFFF6B00)),
                const SizedBox(height: 10),
                if (widget.bestScore != null)
                  _buildStatCard('Personal Best',
                      '${widget.bestScore}',
                      Icons.emoji_events_rounded,
                      const Color(0xFFF59E0B)),
                if (widget.bestScore != null) const SizedBox(height: 10),
                if (widget.avgReactionMs != null)
                  _buildStatCard('Avg Reaction',
                      '${widget.avgReactionMs}ms',
                      Icons.speed_rounded,
                      const Color(0xFF3B82F6)),
                if (widget.avgReactionMs != null) const SizedBox(height: 10),

                const Spacer(),

                // Buttons
                if (widget.onNextDifficulty != null &&
                    widget.nextDifficultyLabel != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: widget.onNextDifficulty,
                        icon: const Icon(Icons.arrow_upward_rounded, size: 18),
                        label: Text(
                          'Level Up â†’ ${widget.nextDifficultyLabel}',
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF6B00),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: OutlinedButton(
                          onPressed: widget.onExit,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                                color: Colors.white.withValues(alpha: 0.15),
                                width: 1.5),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child: Text('Back',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700,
                                color: Colors.white54)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: widget.onPlayAgain,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF6B00),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child: Text('Play Again',
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w800)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 14),
          Text(label,
              style: GoogleFonts.poppins(
                fontSize: 14, fontWeight: FontWeight.w600,
                color: Colors.white60)),
          const Spacer(),
          Text(value,
              style: GoogleFonts.poppins(
                fontSize: 18, fontWeight: FontWeight.w900,
                color: Colors.white)),
        ],
      ),
    );
  }
}


/// Converts difficulty to a numeric scale value.
int brainDifficultyScale(BrainDifficulty d,
    {int easy = 1, int medium = 2, int hard = 3}) {
  return switch (d) {
    BrainDifficulty.easy => easy,
    BrainDifficulty.medium => medium,
    BrainDifficulty.hard => hard,
  };
}
