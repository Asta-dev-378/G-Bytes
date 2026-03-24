import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Facts Data ─────────────────────────────────────────────────────────────
// Each fact has a theme-matched gradient for its background.

const _facts = [
  (
    title: 'Hydration Boosts Performance',
    body:
        'Even mild dehydration (just 2% of body weight in water loss) can impair memory, attention, and reaction time. Keep sipping — your brain needs it!',
    icon: '💧',
    color: Color(0xFF00BCD4),
    category: 'Body & Brain',
    gradient: [Color(0xFF0288D1), Color(0xFF00BCD4), Color(0xFF80DEEA)],
  ),
  (
    title: 'Sleep Consolidates Memory',
    body:
        'During deep sleep, your brain replays the day\'s experiences and moves memories from short-term to long-term storage. 7–9 hours per night is the sweet spot.',
    icon: '🌙',
    color: Color(0xFF6C63FF),
    category: 'Sleep Science',
    gradient: [Color(0xFF1A1A3E), Color(0xFF3F3D9B), Color(0xFF6C63FF)],
  ),
  (
    title: 'Exercise Grows Your Brain',
    body:
        'Aerobic exercise increases the size of the hippocampus — the brain region involved in memory and learning. Just 30 min of moderate activity boosts BDNF levels.',
    icon: '🏋️',
    color: Color(0xFFFF8C00),
    category: 'Fitness',
    gradient: [Color(0xFFFF5722), Color(0xFFFF8C00), Color(0xFFFFCC02)],
  ),
  (
    title: 'Music Enhances Focus',
    body:
        'Listening to instrumental music or binaural beats can induce flow states and sharpen concentration. The "Mozart Effect" shows short-term spatial reasoning boosts.',
    icon: '🎵',
    color: Color(0xFF20BC68),
    category: 'Productivity',
    gradient: [Color(0xFF004D40), Color(0xFF00897B), Color(0xFF20BC68)],
  ),
  (
    title: 'Cold Showers Sharpen Alertness',
    body:
        'Cold water triggers a surge of noradrenaline — a neurotransmitter linked to focus and mood. Even 30 seconds of cold water can make a measurable difference.',
    icon: '🚿',
    color: Color(0xFF0288D1),
    category: 'Wellness',
    gradient: [Color(0xFF01579B), Color(0xFF0288D1), Color(0xFF4FC3F7)],
  ),
  (
    title: 'Reading Rewires Your Brain',
    body:
        'Reading fiction activates the same brain regions used during real experiences. It builds empathy, vocabulary, and strengthens neural pathways for critical thinking.',
    icon: '📚',
    color: Color(0xFF8E24AA),
    category: 'Learning',
    gradient: [Color(0xFF4A148C), Color(0xFF8E24AA), Color(0xFFCE93D8)],
  ),
  (
    title: 'Your Brain Is 60% Fat',
    body:
        'The human brain is the fattiest organ in the body. Omega-3 fatty acids (found in fish and walnuts) are essential for maintaining brain cell structure and function.',
    icon: '🧠',
    color: Color(0xFFE91E63),
    category: 'Neuroscience',
    gradient: [Color(0xFF880E4F), Color(0xFFE91E63), Color(0xFFF48FB1)],
  ),
  (
    title: 'Naps Supercharge Learning',
    body:
        'A 20-minute power nap can boost alertness by 54% and performance by 34%. NASA showed that napping improves mood, memory consolidation, and reaction time.',
    icon: '😴',
    color: Color(0xFF3F51B5),
    category: 'Sleep Science',
    gradient: [Color(0xFF1A237E), Color(0xFF3F51B5), Color(0xFF9FA8DA)],
  ),
  (
    title: 'Gratitude Changes Brain Chemistry',
    body:
        'Practicing gratitude activates the medial prefrontal cortex and floods your brain with dopamine and serotonin. Even 5 minutes of journaling can rewire your mood.',
    icon: '🙏',
    color: Color(0xFFFF7043),
    category: 'Mental Health',
    gradient: [Color(0xFFBF360C), Color(0xFFFF7043), Color(0xFFFFCCBC)],
  ),
  (
    title: 'Multitasking Is a Myth',
    body:
        'The brain can\'t truly multitask — it rapidly switches between tasks, losing up to 40% efficiency. Deep focus on one task at a time produces far better results.',
    icon: '🎯',
    color: Color(0xFF00897B),
    category: 'Productivity',
    gradient: [Color(0xFF004D40), Color(0xFF00897B), Color(0xFF80CBC4)],
  ),
  (
    title: 'Laughter Boosts Immunity',
    body:
        'Laughing increases endorphins and strengthens immune function. A genuine belly laugh can lower cortisol levels and improve both mental and physical health.',
    icon: '😂',
    color: Color(0xFFFFCA28),
    category: 'Mental Health',
    gradient: [Color(0xFFF57F17), Color(0xFFFFCA28), Color(0xFFFFECB3)],
  ),
  (
    title: 'Walking Increases Creativity',
    body:
        'Walking boosts creative thinking by up to 60%. The rhythmic motion activates the brain\'s default mode network, ideal for brainstorming and problem-solving.',
    icon: '🚶',
    color: Color(0xFF26A69A),
    category: 'Productivity',
    gradient: [Color(0xFF004D40), Color(0xFF26A69A), Color(0xFF80CBC4)],
  ),
  (
    title: 'Coffee Timing Matters',
    body:
        'Caffeine is most effective 90–120 minutes after waking, when your afternoon energy dips. Drinking it strategically avoids interfering with sleep later.',
    icon: '☕',
    color: Color(0xFF795548),
    category: 'Wellness',
    gradient: [Color(0xFF3E2723), Color(0xFF795548), Color(0xFFBCAAA4)],
  ),
  (
    title: 'Nature Reduces Stress',
    body:
        'Time in nature lowers cortisol and activates the parasympathetic nervous system. Just 20 minutes in a park or forest can significantly reduce stress and anxiety.',
    icon: '🌲',
    color: Color(0xFF27AE60),
    category: 'Wellness',
    gradient: [Color(0xFF1B5E20), Color(0xFF27AE60), Color(0xFF81C784)],
  ),
  (
    title: 'Sunlight Syncs Your Circadian Rhythm',
    body:
        'Morning sunlight exposure synchronizes your internal clock, improving sleep quality and energy levels throughout the day. Get 15–30 min within 1–2 hours of waking.',
    icon: '☀️',
    color: Color(0xFFFFB300),
    category: 'Sleep Science',
    gradient: [Color(0xFFF57F17), Color(0xFFFFB300), Color(0xFFFFE082)],
  ),
  (
    title: 'Teaching Reinforces Learning',
    body:
        'Explaining concepts to others strengthens your own understanding and memory. The "Feynman Technique" shows that teaching forces you to identify knowledge gaps.',
    icon: '🎓',
    color: Color(0xFF1976D2),
    category: 'Learning',
    gradient: [Color(0xFF0D47A1), Color(0xFF1976D2), Color(0xFF64B5F6)],
  ),
  (
    title: 'Hydration Affects Brain Performance',
    body:
        'A 1.5% loss in body water impairs concentration and increases fatigue. Drink water consistently throughout the day, not just when thirsty.',
    icon: '💦',
    color: Color(0xFF0097A7),
    category: 'Body & Brain',
    gradient: [Color(0xFF006064), Color(0xFF0097A7), Color(0xFF4DD0E1)],
  ),
  (
    title: 'Spaced Repetition Maximizes Retention',
    body:
        'Reviewing information at increasing intervals (1 day, 3 days, 1 week) moves it into long-term memory far more effectively than cramming.',
    icon: '📝',
    color: Color(0xFF7E57C2),
    category: 'Learning',
    gradient: [Color(0xFF4527A0), Color(0xFF7E57C2), Color(0xFFB39DDB)],
  ),
  (
    title: 'Meditation Rewires Your Brain',
    body:
        'Regular meditation increases gray matter in areas responsible for focus, emotional regulation, and self-awareness. Even 10 minutes daily shows measurable benefits.',
    icon: '🧘',
    color: Color(0xFF00838F),
    category: 'Mental Health',
    gradient: [Color(0xFF004D40), Color(0xFF00838F), Color(0xFF4DD0E1)],
  ),
  (
    title: 'Strategic Breaks Improve Focus',
    body:
        'Taking short breaks every 25 minutes (Pomodoro Technique) prevents mental fatigue and maintains peak productivity. Movement during breaks is even better.',
    icon: '⏱️',
    color: Color(0xFFD32F2F),
    category: 'Productivity',
    gradient: [Color(0xFFB71C1C), Color(0xFFD32F2F), Color(0xFFF44336)],
  ),
  (
    title: 'Protein Powers Brain Functions',
    body:
        'Amino acids from protein are building blocks for neurotransmitters like dopamine and serotonin. Include lean protein in every meal for sustained mental clarity.',
    icon: '🥚',
    color: Color(0xFFAA4444),
    category: 'Body & Brain',
    gradient: [Color(0xFF5D4037), Color(0xFFAA4444), Color(0xFFD7CCC8)],
  ),
  (
    title: 'Posture Affects Mood',
    body:
        'Standing or sitting upright increases confidence and mood. Slouching correlates with depression. Your body position directly influences your mental state.',
    icon: '💪',
    color: Color(0xFFFBC02D),
    category: 'Wellness',
    gradient: [Color(0xFFF57F17), Color(0xFFFBC02D), Color(0xFFFFF59D)],
  ),
  (
    title: 'Social Connection Boosts Mental Health',
    body:
        'Strong social bonds reduce anxiety and depression risk by up to 50%. Quality time with friends and family literally changes your brain chemistry for the better.',
    icon: '👥',
    color: Color(0xFFC2185B),
    category: 'Mental Health',
    gradient: [Color(0xFF880E4F), Color(0xFFC2185B), Color(0xFFF48FB1)],
  ),
];

// ── Daily Index Helper ─────────────────────────────────────────────────────

/// Returns 10 random facts for today based on the day of the year (deterministic).
/// The same 10 facts will show each day until the day changes.
List<dynamic> _getTodaysFacts() {
  final now = DateTime.now();
  final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;

  // Use day of year as seed for deterministic randomization
  final random = Random(dayOfYear);

  // Shuffle a copy of facts and take the first 10
  final shuffled = List.from(_facts)..shuffle(random);
  return shuffled.take(10).toList();
}

/// Returns the index of today's fact in the daily facts list for highlighting.
int _getTodayFactIndex(List<dynamic> todaysFacts) {
  final now = DateTime.now();
  final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
  final random = Random(dayOfYear);

  // Recreate the same shuffle to find which position the first fact landed in
  final shuffled = List.from(_facts)..shuffle(random);
  final firstDaily = shuffled.first;

  return todaysFacts.indexWhere((f) => f.title == firstDaily.title);
}

// ── Screen ─────────────────────────────────────────────────────────────────

class DidYouKnowScreen extends StatefulWidget {
  const DidYouKnowScreen({super.key});

  @override
  State<DidYouKnowScreen> createState() => _DidYouKnowScreenState();
}

class _DidYouKnowScreenState extends State<DidYouKnowScreen>
    with TickerProviderStateMixin {
  late final PageController _pageController;
  late int _current;
  late AnimationController _pulseController;
  late List<dynamic> _todaysFacts;
  late int _todayIndex;

  @override
  void initState() {
    super.initState();
    _todaysFacts = _getTodaysFacts();
    _todayIndex = _getTodayFactIndex(_todaysFacts);
    _current = _todayIndex;
    _pageController = PageController(
      viewportFraction: 0.92,
      initialPage: _current,
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fact = _todaysFacts[_current];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1A1A1A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Did You Know?',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1A1A1A),
            fontSize: 20,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: fact.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_current + 1} / ${_todaysFacts.length}',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: fact.color,
                  ),
                ),
              ).animate(key: ValueKey(_current)).fadeIn(duration: 300.ms),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Daily Fact Label
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [fact.color, fact.gradient.last],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.today_rounded,
                        size: 14,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _current == _todayIndex
                            ? "Today's Fact"
                            : 'Explore All',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Refreshes daily  •  Swipe to explore',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          // Page View
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (i) => setState(() => _current = i),
              itemCount: _todaysFacts.length,
              itemBuilder: (context, index) {
                final f = _todaysFacts[index];
                final isActive = index == _current;
                return AnimatedScale(
                  scale: isActive ? 1.0 : 0.93,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  child: _FactCard(
                    fact: f,
                    pulseController: _pulseController,
                    isToday: index == _todayIndex,
                  ),
                );
              },
            ),
          ),
          // Dot indicators
          Padding(
            padding: const EdgeInsets.only(bottom: 20, top: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _todaysFacts.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _current ? 20 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: i == _current ? fact.color : Colors.grey.shade300,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Fact Card ──────────────────────────────────────────────────────────────

class _FactCard extends StatelessWidget {
  final dynamic fact;
  final AnimationController pulseController;
  final bool isToday;

  const _FactCard({
    required this.fact,
    required this.pulseController,
    required this.isToday,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            // ── Themed Gradient Background ───────────────────────────────
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: (fact.gradient as List<Color>),
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),

            // Pulsing decorative circle (top right)
            Positioned(
              top: -60,
              right: -60,
              child: AnimatedBuilder(
                animation: pulseController,
                builder: (context, child) => Container(
                  width: 220 + pulseController.value * 30,
                  height: 220 + pulseController.value * 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.07),
                  ),
                ),
              ),
            ),
            // Static decorative circle (bottom left)
            Positioned(
              bottom: -80,
              left: -60,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withValues(alpha: 0.08),
                ),
              ),
            ),

            // ── Content ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category + Today badge
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          fact.category as String,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (isToday) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade300,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                size: 12,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Today',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),

                  const Spacer(),

                  // Giant emoji icon
                  Text(
                    fact.icon as String,
                    style: const TextStyle(fontSize: 72),
                  ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),

                  const SizedBox(height: 16),

                  // Title
                  Text(
                    fact.title as String,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Body
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Text(
                      fact.body as String,
                      style: GoogleFonts.poppins(
                        color: Colors.white.withValues(alpha: 0.95),
                        fontSize: 14,
                        height: 1.6,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Swipe hint
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.swipe_rounded,
                        size: 16,
                        color: Colors.white54,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Swipe for more facts',
                        style: GoogleFonts.poppins(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
