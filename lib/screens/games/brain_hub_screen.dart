// brain_hub_screen.dart — Premium redesign
// Hero banner · category horizontal rows · press micro-animation · expand launch

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/app_scale.dart';

import '../../providers/player_progress_provider.dart';
import '../../features/streak/models/daily_task.dart';

// ── Brain Hub game screens ─────────────────────────────────────────────────
import 'binary_puzzle_screen.dart';
import 'sum_snake_screen.dart';
import 'countdown_math_screen.dart';
import 'akari_screen.dart';
import 'balance_scale_screen.dart';
import 'attentional_blink_screen.dart';
import 'word_wheel_screen.dart';
import 'action_sequence_recall_screen.dart';
import 'color_clash_screen.dart';
import 'number_maze_screen.dart';


// ---------------------------------------------------------------------------
// DATA MODEL
// ---------------------------------------------------------------------------

enum _BrainCategory { speed, memory, focus, logic, verbal, spatial }

extension _BrainCategoryX on _BrainCategory {
  String get label => switch (this) {
        _BrainCategory.speed   => 'Speed',
        _BrainCategory.memory  => 'Memory',
        _BrainCategory.focus   => 'Focus',
        _BrainCategory.logic   => 'Logic',
        _BrainCategory.verbal  => 'Verbal',
        _BrainCategory.spatial => 'Spatial',
      };

  // Unique icon per category (matches nav-bar icon language — geometric, clean)
  IconData get icon => switch (this) {
        _BrainCategory.speed   => Icons.bolt_rounded,
        _BrainCategory.memory  => Icons.memory_rounded,
        _BrainCategory.focus   => Icons.remove_red_eye_rounded,
        _BrainCategory.logic   => Icons.account_tree_rounded,
        _BrainCategory.verbal  => Icons.sort_by_alpha_rounded,
        _BrainCategory.spatial => Icons.grid_view_rounded,
      };

  Color get color => switch (this) {
        _BrainCategory.speed   => const Color(0xFFF59E0B),
        _BrainCategory.memory  => const Color(0xFF10B981),
        _BrainCategory.focus   => const Color(0xFF8B5CF6),
        _BrainCategory.logic   => const Color(0xFF3B82F6),
        _BrainCategory.verbal  => const Color(0xFFEC4899),
        _BrainCategory.spatial => const Color(0xFF06B6D4),
      };

  Color get bgGradientEnd => switch (this) {
        _BrainCategory.speed   => const Color(0xFFFEF3C7),
        _BrainCategory.memory  => const Color(0xFFD1FAE5),
        _BrainCategory.focus   => const Color(0xFFEDE9FE),
        _BrainCategory.logic   => const Color(0xFFDBEAFE),
        _BrainCategory.verbal  => const Color(0xFFFCE7F3),
        _BrainCategory.spatial => const Color(0xFFCFFAFE),
      };
}

class _GameInfo {
  final String id;
  final String title;
  /// Premium emoji displayed on the game tile (replaces icon).
  final String emoji;
  final String subtitle;
  final String howToPlay; // shown in long-press info sheet
  final _BrainCategory category;
  final TaskType taskType;
  final Widget Function() builder;

  const _GameInfo({
    required this.id,
    required this.title,
    required this.emoji,
    required this.subtitle,
    required this.howToPlay,
    required this.category,
    required this.taskType,
    required this.builder,
  });
}

final _allGames = <_GameInfo>[
  // ── Logic ─────────────────────────────────────────────────────────────────
  _GameInfo(
    id: 'binary_puzzle',
    title: 'Binary Puzzle',
    emoji: '⬛01⬜',
    subtitle: 'Fill the grid with 0s and 1s',
    howToPlay:
        'Fill every cell with 0 or 1. No three identical values in a row or column. Each row and column must contain equal counts of 0s and 1s. No two rows or columns may be identical. Tap a cell to cycle: empty → 0 → 1. Gray-locked cells are given clues.',
    category: _BrainCategory.logic,
    taskType: TaskType.slidingPuzzle,
    builder: () => const BinaryPuzzleScreen(),
  ),
  _GameInfo(
    id: 'sum_snake',
    title: 'Sum Snake',
    emoji: '🐍',
    subtitle: 'Draw a path that hits the target sum',
    howToPlay:
        'A grid of numbers is shown with a target sum at the top. Draw a connected path through adjacent cells — up, down, left, or right. The running total of your path must equal the target. Tap cells to extend your snake. Tap an earlier cell to backtrack.',
    category: _BrainCategory.logic,
    taskType: TaskType.logic,
    builder: () => const SumSnakeScreen(),
  ),
  _GameInfo(
    id: 'akari',
    title: 'Akari · Light Up',
    emoji: '💡',
    subtitle: 'Place bulbs to illuminate every cell',
    howToPlay:
        'Place light bulbs in white cells. Each bulb shines in all four directions until blocked by a black wall. Every white cell must be illuminated. Bulbs may not shine directly on each other. Numbered black walls must have exactly that many adjacent bulbs.',
    category: _BrainCategory.logic,
    taskType: TaskType.logic,
    builder: () => const AkariScreen(),
  ),
  // ── Speed ──────────────────────────────────────────────────────────────────
  _GameInfo(
    id: 'countdown_math',
    title: 'Countdown Math',
    emoji: '⏱️',
    subtitle: 'Build the target from given numbers',
    howToPlay:
        'You are given 6 numbers and a target. Use any combination of +, −, ×, ÷ to reach the target before time runs out. Not all numbers need to be used. Tap a number then an operator to build your expression. Hit Undo to remove the last step.',
    category: _BrainCategory.speed,
    taskType: TaskType.mathSprint,
    builder: () => const CountdownMathScreen(),
  ),
  _GameInfo(
    id: 'color_clash',
    title: 'Color Clash',
    emoji: '🎨',
    subtitle: 'Don\'t be fooled — word vs ink color!',
    howToPlay:
        'A colored word appears in a mismatched ink color (e.g. "RED" in blue ink). A prompt tells you to tap either the WORD meaning or the INK color. Build combos for bonus points! You have 60 seconds — how high can you score?',
    category: _BrainCategory.speed,
    taskType: TaskType.mathSprint,
    builder: () => const ColorClashScreen(),
  ),
  // ── Focus ─────────────────────────────────────────────────────────────────
  _GameInfo(
    id: 'attentional_blink',
    title: 'Attention Blink',
    emoji: '👁️',
    subtitle: 'Catch two digits hidden in a rapid stream',
    howToPlay:
        'A rapid stream of letters flashes on screen. Two target digits are hidden within the stream. After it ends, recall both digits in order. The tricky part: if T2 appears within ~200–500ms of T1, your brain "blinks" and often misses it. Train to widen your attention window!',
    category: _BrainCategory.focus,
    taskType: TaskType.sart,
    builder: () => const AttentionalBlinkScreen(),
  ),
  // ── Memory ────────────────────────────────────────────────────────────────
  _GameInfo(
    id: 'action_sequence_recall',
    title: 'Action Sequence',
    emoji: '🎯',
    subtitle: 'Watch & replay the action sequence',
    howToPlay:
        'A sequence of colored shape + direction actions flashes on screen. After the display phase, tap the matching tiles in the exact same order. Each successful round adds one more action. The sequence keeps growing — how far can you go?',
    category: _BrainCategory.memory,
    taskType: TaskType.sequenceRecall,
    builder: () => const ActionSequenceRecallScreen(),
  ),
  // ── Verbal ────────────────────────────────────────────────────────────────
  _GameInfo(
    id: 'word_wheel',
    title: 'Word Wheel',
    emoji: '🔠',
    subtitle: 'Spin letters into words — use the center!',
    howToPlay:
        'Eight letters circle one center letter. Tap any combination of 3 or more letters to form a word — every word MUST include the center letter. Submit to score. Longer words score more points. Race against the clock to find as many words as possible!',
    category: _BrainCategory.verbal,
    taskType: TaskType.anagramSolver,
    builder: () => const WordWheelScreen(),
  ),
  // ── Logic (continued) ─────────────────────────────────────────────────────
  _GameInfo(
    id: 'number_maze',
    title: 'Number Maze',
    emoji: '🔢',
    subtitle: 'Tap 1, 2, 3… as fast as you can!',
    howToPlay:
        'A grid of scrambled numbers is shown. Tap them in ascending order: 1, 2, 3… all the way to the last number. Your timer counts up — the goal is the fastest time. Each wrong tap adds a +1s penalty. Choose Easy (4×4), Medium (5×5), or Hard (6×6).',
    category: _BrainCategory.logic,
    taskType: TaskType.slidingPuzzle,
    builder: () => const NumberMazeScreen(),
  ),
  // ── Spatial ───────────────────────────────────────────────────────────────
  _GameInfo(
    id: 'balance_scale',
    title: 'Balance Scale',
    emoji: '⚖️',
    subtitle: 'Deduce which side weighs more',
    howToPlay:
        'Each tray holds emoji items with hidden weights. Decide: is the left side heavier, the right side heavier, or are they equal? Tap your answer. The scale tilts to reveal the truth. Score as many correct judgements as possible across all rounds!',
    category: _BrainCategory.spatial,
    taskType: TaskType.logic,
    builder: () => const BalanceScaleScreen(),
  ),
];

// ---------------------------------------------------------------------------
// SCREEN
// ---------------------------------------------------------------------------

class BrainHubScreen extends StatefulWidget {
  const BrainHubScreen({super.key});

  @override
  State<BrainHubScreen> createState() => _BrainHubScreenState();
}

class _BrainHubScreenState extends State<BrainHubScreen>
    with SingleTickerProviderStateMixin {
  final ScrollController _scroll = ScrollController();
  late final PageController _heroPageCtrl;

  // Hero banner rotates through 3 featured games
  int _heroIndex = 0;
  static const _featuredIds = ['binary_puzzle', 'action_sequence_recall', 'countdown_math'];
  late final _heroGames = _allGames.where((g) => _featuredIds.contains(g.id)).toList();

  // Onboarding overlay
  bool _showOnboarding = false;
  int _onboardingStep = 0;
  static const _onboardingSteps = [
    ('🧠', 'Welcome to Brain Hub', 'Scientifically-designed games to train your memory, speed, focus, and more.'),
    ('👈👉', 'Swipe to explore', 'Each category has a horizontal row of games. Scroll sideways to see all of them.'),
    ('🏆', 'League unlocks difficulty', 'Start at Spark. Reach Flux to unlock Medium — reach Apex for Hard mode.'),
    ('👆', 'Long-press to learn', 'Long-press any game card to see full instructions before you play.'),
  ];

  @override
  void initState() {
    super.initState();
    // viewportFraction: 0.88 so adjacent slides peek in — no grey edges visible
    _heroPageCtrl = PageController(viewportFraction: 0.88);
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('brain_hub_onboarding_seen') ?? false;
    if (!seen && mounted) {
      setState(() => _showOnboarding = true);
    }
  }

  Future<void> _advanceOnboarding() async {
    if (_onboardingStep < _onboardingSteps.length - 1) {
      setState(() => _onboardingStep++);
    } else {
      // Last step tapped — dismiss
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('brain_hub_onboarding_seen', true);
      setState(() => _showOnboarding = false);
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    _heroPageCtrl.dispose();
    super.dispose();
  }

  // Expand-to-fill launch — tile scales up to cover screen, then pushes route
  void _launchGame(BuildContext context, _GameInfo info) {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, a1, a2) => info.builder(),
        transitionDuration: const Duration(milliseconds: 380),
        reverseTransitionDuration: const Duration(milliseconds: 260),
        transitionsBuilder: (context, anim, _, child) {
          final fade  = CurvedAnimation(parent: anim, curve: Curves.easeOut);
          final slide = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
          return FadeTransition(
            opacity: fade,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.06), end: Offset.zero,
              ).animate(slide),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<PlayerProgressProvider>();
    final primary  = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scroll,
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── Glassmorphism App Bar ────────────────────────────────────────
              SliverAppBar(
                pinned: true,
                backgroundColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                expandedHeight: 108,
                automaticallyImplyLeading: false,
                flexibleSpace: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A0A0F).withValues(alpha: 0.88),
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.white.withValues(alpha: 0.08), width: 1),
                        ),
                      ),
                      child: FlexibleSpaceBar(
                        titlePadding: const EdgeInsets.only(left: 24, bottom: 14),
                        title: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${_allGames.length} games  ·  Train your mind',
                                style: GoogleFonts.poppins(
                                  fontSize: 11, color: Colors.white38,
                                  fontWeight: FontWeight.w500)),
                              Text('Brain Hub',
                                style: GoogleFonts.poppins(
                                  fontSize: 22, fontWeight: FontWeight.w800,
                                  color: Colors.white)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ── Hero Carousel Banner ─────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppScale.dp(context, 20),
                    AppScale.dp(context, 20),
                    AppScale.dp(context, 20),
                    0,
                  ),
                  child: _HeroBanner(
                    games: _heroGames,
                    currentIndex: _heroIndex,
                    pageController: _heroPageCtrl,
                    onPageChanged: (i) => setState(() => _heroIndex = i),
                    onPlay: (g) => _launchGame(context, g),
                    primary: primary,
                  ),
                ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.08, end: 0),
              ),

              // ── Category Sections ────────────────────────────────────────────
              ..._BrainCategory.values.map((cat) {
                final games = _allGames.where((g) => g.category == cat).toList();
                return _CategorySection(
                  category: cat,
                  games: games,
                  progress: progress,
                  onTap: (g) => _launchGame(context, g),
                  onLongPress: (g, c) => _showHowToPlay(context, g, c),
                  isFirst: cat == _BrainCategory.values.first,
                );
              }),

              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),

          // ── Onboarding Overlay ──────────────────────────────────────────
          if (_showOnboarding)
            _OnboardingOverlay(
              step: _onboardingStep,
              totalSteps: _onboardingSteps.length,
              emoji: _onboardingSteps[_onboardingStep].$1,
              title: _onboardingSteps[_onboardingStep].$2,
              body: _onboardingSteps[_onboardingStep].$3,
              onTap: _advanceOnboarding,
            ),
        ],
      ),
    );
  }

  // How-to-play bottom sheet
  void _showHowToPlay(BuildContext context, _GameInfo info, _BrainCategory cat) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _HowToPlaySheet(info: info, cat: cat),
    );
  }
}


// ---------------------------------------------------------------------------
// HERO BANNER
// ---------------------------------------------------------------------------

class _HeroBanner extends StatelessWidget {
  final List<_GameInfo> games;
  final int currentIndex;
  final PageController pageController;
  final void Function(int) onPageChanged;
  final void Function(_GameInfo) onPlay;
  final Color primary;

  const _HeroBanner({
    required this.games,
    required this.currentIndex,
    required this.pageController,
    required this.onPageChanged,
    required this.onPlay,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    if (games.isEmpty) return const SizedBox.shrink();
    final bannerH = AppScale.dp(context, 176);

    return Column(
      children: [
        SizedBox(
          height: bannerH,
          child: PageView.builder(
            controller: pageController,
            onPageChanged: onPageChanged,
            itemCount: games.length,
            clipBehavior: Clip.none, // allow adjacent slides to peek outside bounds
            itemBuilder: (context, index) {
              final game = games[index];
              final cat = game.category;
              return _HeroBannerSlide(
                game: game,
                cat: cat,
                onPlay: onPlay,
              );
            },
          ),
        ),
        SizedBox(height: AppScale.dp(context, 10)),
        // Dot indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(games.length, (i) => GestureDetector(
            onTap: () => pageController.animateToPage(
              i,
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeInOut,
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: i == currentIndex ? AppScale.dp(context, 20) : AppScale.dp(context, 6),
              height: AppScale.dp(context, 6),
              margin: EdgeInsets.symmetric(horizontal: AppScale.dp(context, 3)),
              decoration: BoxDecoration(
                color: i == currentIndex
                    ? primary
                    : primary.withValues(alpha: 0.28),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          )),
        ),
      ],
    );
  }
}

class _HeroBannerSlide extends StatelessWidget {
  final _GameInfo game;
  final _BrainCategory cat;
  final void Function(_GameInfo) onPlay;

  const _HeroBannerSlide({
    required this.game,
    required this.cat,
    required this.onPlay,
  });

  // Small symmetric margin so the grey behind shows as a clean gap
  // between the active slide and the peeking adjacent slides.
  // Since viewportFraction is 0.88 the peeking slides are visible.
  @override
  Widget build(BuildContext context) {
    final s = AppScale.of(context);
    final iconBoxSz = 76 * s;
    final iconSz    = 38 * s;
    final rightPad  = 24 * s;
    final textRightPad = (iconBoxSz + rightPad + 18 * s);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 2 * s),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cat.color, cat.bgGradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26 * s),
        boxShadow: [
          BoxShadow(
            color: cat.color.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background decorative circles
          Positioned(
            right: -28 * s, top: -28 * s,
            child: Container(
              width: 140 * s, height: 140 * s,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.10),
              ),
            ),
          ),
          Positioned(
            right: 16 * s, bottom: -16 * s,
            child: Container(
              width: 80 * s, height: 80 * s,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          // Game icon (large, centered on right)
          Positioned(
            right: rightPad, top: 0, bottom: 0,
            child: Center(
              child: Container(
                width: iconBoxSz, height: iconBoxSz,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(22 * s),
                ),
                child: Center(child: Text(game.emoji,
                    style: TextStyle(fontSize: iconSz))),
              ),
            ),
          ),
          // Text + play button (left side)
          Padding(
            padding: EdgeInsets.fromLTRB(22 * s, 22 * s, textRightPad, 18 * s),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10 * s, vertical: 4 * s),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('Featured',
                    style: GoogleFonts.poppins(
                      fontSize: 10 * s, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
                SizedBox(height: 10 * s),
                Text(game.title,
                  style: GoogleFonts.poppins(
                    fontSize: 20 * s, fontWeight: FontWeight.w800, color: Colors.white,
                    height: 1.2)),
                SizedBox(height: 4 * s),
                Text(game.subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 12 * s, color: Colors.white.withValues(alpha: 0.85)),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
                const Spacer(),
                _PressableTile(
                  onTap: () => onPlay(game),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 18 * s, vertical: 9 * s),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.play_arrow_rounded, size: 18 * s, color: cat.color),
                      SizedBox(width: 4 * s),
                      Text('Play Now',
                        style: GoogleFonts.poppins(
                          fontSize: 12 * s, fontWeight: FontWeight.w700, color: cat.color)),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// CATEGORY SECTION
// ---------------------------------------------------------------------------

class _CategorySection extends StatelessWidget {
  final _BrainCategory category;
  final List<_GameInfo> games;
  final PlayerProgressProvider progress;
  final void Function(_GameInfo) onTap;
  final void Function(_GameInfo, _BrainCategory) onLongPress;
  final bool isFirst;

  const _CategorySection({
    required this.category,
    required this.games,
    required this.progress,
    required this.onTap,
    required this.onLongPress,
    this.isFirst = false,
  });

  @override
  Widget build(BuildContext context) {
    if (games.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

    final s        = AppScale.of(context);
    final hPad     = 20 * s;
    final cardW    = 130 * s;
    final cardH    = 148 * s;
    final spacing  = 10 * s;
    final headerSz = 32 * s;

    // All tiles + coming-soon at the end
    final tiles = [...games];

    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(hPad, isFirst ? hPad : 14 * s, 0, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header
            Padding(
              padding: EdgeInsets.only(right: hPad),
              child: Row(
                children: [
                  Container(
                    width: headerSz, height: headerSz,
                    decoration: BoxDecoration(
                      color: category.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10 * s),
                      boxShadow: [
                        BoxShadow(
                          color: category.color.withValues(alpha: 0.30),
                          blurRadius: 12, spreadRadius: 0),
                      ],
                    ),
                    child: Icon(category.icon, size: 16 * s, color: category.color),
                  ),
                  SizedBox(width: 10 * s),
                  Text(category.label,
                    style: GoogleFonts.poppins(
                      fontSize: 17 * s, fontWeight: FontWeight.w800,
                      color: Colors.white)),
                ],
              ).animate().fadeIn(duration: 300.ms).slideX(begin: -0.05, end: 0),
            ),
            SizedBox(height: 10 * s),

            // Horizontal scrolling row of game cards
            SizedBox(
              height: cardH,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.only(right: hPad),
                itemCount: tiles.length + 1, // +1 for coming-soon
                itemBuilder: (ctx, i) {
                  if (i < tiles.length) {
                    final info   = tiles[i];
                    final isDone = progress.isTaskCompleted(info.taskType);
                    return Padding(
                      padding: EdgeInsets.only(right: spacing),
                      child: SizedBox(
                        width: cardW,
                        child: _GameTile(
                          info: info,
                          isDone: isDone,
                          index: i,
                          onTap: () => onTap(info),
                          onLongPress: () => onLongPress(info, category),
                        ),
                      ),
                    );
                  } else {
                    return SizedBox(
                      width: cardW,
                      child: _ComingSoonTile(color: category.color, index: i),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// COMING SOON TILE
// ---------------------------------------------------------------------------

class _ComingSoonTile extends StatelessWidget {
  final Color color;
  final int index;
  const _ComingSoonTile({required this.color, required this.index});

  @override
  Widget build(BuildContext context) {
    final s = AppScale.of(context);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(18 * s),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1.2,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(12 * s),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(14 * s),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Center(
                  child: Icon(
                    Icons.lock_outline_rounded,
                    size: 22 * s,
                    color: Colors.white24,
                  ),
                ),
              ),
            ),
            SizedBox(height: 8 * s),
            Text(
              'More Soon',
              style: GoogleFonts.poppins(
                fontSize: 11.5 * s,
                fontWeight: FontWeight.w700,
                color: Colors.white24,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 3 * s),
            Text(
              'Coming soon!',
              style: GoogleFonts.poppins(
                fontSize: 9 * s,
                color: Colors.white12,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
            ),
          ],
        ),
      ),
    ).animate(delay: (index * 30).ms).fadeIn(duration: 280.ms).slideY(begin: 0.06, end: 0);
  }
}

// ---------------------------------------------------------------------------
// GAME TILE — 3-col square with press micro-animation
// ---------------------------------------------------------------------------

class _GameTile extends StatefulWidget {
  final _GameInfo info;
  final bool isDone;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _GameTile({
    required this.info, required this.isDone,
    required this.index, required this.onTap,
    required this.onLongPress,
  });

  @override
  State<_GameTile> createState() => _GameTileState();
}

class _GameTileState extends State<_GameTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 90),
      reverseDuration: const Duration(milliseconds: 180),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.94)
        .animate(CurvedAnimation(parent: _press, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) => _press.forward();
  void _onTapUp(TapUpDetails _) {
    _press.reverse();
    widget.onTap();
  }
  void _onTapCancel() => _press.reverse();

  @override
  Widget build(BuildContext context) {
    final cat      = widget.info.category;
    final catColor = cat.color;
    final s        = AppScale.of(context);

    return AnimatedBuilder(
      animation: _scale,
      builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        onLongPress: widget.onLongPress,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(18 * s),
            border: Border.all(
              color: catColor.withValues(alpha: 0.25),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: catColor.withValues(alpha: 0.12),
                blurRadius: 16,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(12 * s),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Icon + done badge row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Centred icon container
                    Expanded(
                      child: Container(
                        height: 46 * s,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              catColor.withValues(alpha: 0.20),
                              catColor.withValues(alpha: 0.08),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14 * s),
                          boxShadow: [
                            BoxShadow(
                              color: catColor.withValues(alpha: 0.25),
                              blurRadius: 10,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            widget.info.emoji,
                            style: TextStyle(
                              fontSize: 22 * s,
                              // No color needed — emoji has its own color
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                    if (widget.isDone) ...[
                      SizedBox(width: 4 * s),
                      Container(
                        width: 18 * s, height: 18 * s,
                        decoration: const BoxDecoration(
                          color: Color(0xFF20BC68),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.check_rounded,
                          size: 11 * s, color: Colors.white),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 8 * s),
                // Title centred
                Text(
                  widget.info.title,
                  style: GoogleFonts.poppins(
                    fontSize: 11.5 * s, fontWeight: FontWeight.w700,
                    color: Colors.white, height: 1.2),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 3 * s),
                // Subtitle
                Text(
                  widget.info.subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 9 * s, color: Colors.white38),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate(delay: (widget.index * 30).ms)
        .fadeIn(duration: 280.ms)
        .slideY(begin: 0.06, end: 0);
  }
}

// ---------------------------------------------------------------------------
// PRESSABLE TILE WRAPPER (for hero banner play button)
// ---------------------------------------------------------------------------

class _PressableTile extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _PressableTile({required this.child, required this.onTap});

  @override
  State<_PressableTile> createState() => _PressableTileState();
}

class _PressableTileState extends State<_PressableTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
      reverseDuration: const Duration(milliseconds: 160),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.94).animate(_ctrl);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown: (_) => _ctrl.forward(),
    onTapUp:   (_) { _ctrl.reverse(); widget.onTap(); },
    onTapCancel: _ctrl.reverse,
    child: AnimatedBuilder(
      animation: _scale,
      builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
      child: widget.child,
    ),
  );
}

// ---------------------------------------------------------------------------
// ONBOARDING OVERLAY — First-time 4-step tappable tutorial
// ---------------------------------------------------------------------------

class _OnboardingOverlay extends StatelessWidget {
  final int step;
  final int totalSteps;
  final String emoji;
  final String title;
  final String body;
  final VoidCallback onTap;

  const _OnboardingOverlay({
    required this.step,
    required this.totalSteps,
    required this.emoji,
    required this.title,
    required this.body,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: Colors.black.withValues(alpha: 0.78),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Step dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(totalSteps, (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: i == step ? 20 : 7,
                    height: 7,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: i == step
                          ? const Color(0xFFC6E05B)
                          : Colors.white.withValues(alpha: 0.30),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  )),
                ),
                const SizedBox(height: 40),
                // Emoji
                Text(emoji, style: const TextStyle(fontSize: 72)),
                const SizedBox(height: 24),
                // Title
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 16),
                // Body
                Text(
                  body,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    color: Colors.white.withValues(alpha: 0.78),
                    fontWeight: FontWeight.w400,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 48),
                // CTA button
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32, vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFC6E05B),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFC6E05B).withValues(alpha: 0.40),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Text(
                    step < totalSteps - 1 ? 'Next  →' : 'Get Started!',
                    style: GoogleFonts.poppins(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1C1C1E),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Tap anywhere to continue',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.white30,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}

// ---------------------------------------------------------------------------
// HOW TO PLAY BOTTOM SHEET — Long-press game card → shows full info
// ---------------------------------------------------------------------------

class _HowToPlaySheet extends StatelessWidget {
  final _GameInfo info;
  final _BrainCategory cat;

  const _HowToPlaySheet({required this.info, required this.cat});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 60),
      decoration: const BoxDecoration(
        color: Color(0xFF0E0E18),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Handle bar + close button
          Padding(
            padding: const EdgeInsets.only(top: 12, left: 16, right: 16, bottom: 4),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Positioned(
                  right: 0,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded,
                          color: Colors.white54, size: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Game header
                  Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              cat.color,
                              cat.color.withValues(alpha: 0.65),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: cat.color.withValues(alpha: 0.35),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(info.emoji,
                            style: const TextStyle(fontSize: 30)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: cat.color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                cat.label.toUpperCase(),
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: cat.color,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              info.title,
                              style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Description
                  Text(
                    info.subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // How to play section
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline_rounded,
                                size: 18, color: cat.color),
                            const SizedBox(width: 8),
                            Text(
                              'How to Play',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          info.howToPlay,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.white70,
                            fontWeight: FontWeight.w400,
                            height: 1.65,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.of(context).pop();
                        Future.delayed(const Duration(milliseconds: 300), () {
                          if (context.mounted) {
                            Navigator.of(context).push(
                              PageRouteBuilder(
                                pageBuilder: (ctx, a1, a2) => info.builder(),
                                transitionDuration:
                                    const Duration(milliseconds: 380),
                                transitionsBuilder: (ctx, anim, a2, child) =>
                                    FadeTransition(opacity: anim, child: child),
                              ),
                            );
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [cat.color, cat.color.withValues(alpha: 0.75)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: cat.color.withValues(alpha: 0.40),
                              blurRadius: 16, offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.play_arrow_rounded,
                                color: Colors.white, size: 22),
                            const SizedBox(width: 8),
                            Text(
                              'Play Now',
                              style: GoogleFonts.poppins(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

