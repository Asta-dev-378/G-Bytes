import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

const _facts = [
  (
    title: 'Hydration Boosts Performance',
    body:
        'Even mild dehydration (just 2% of body weight in water loss) can impair memory, attention, and reaction time. Keep sipping — your brain needs it!',
    icon: '💧',
    color: Color(0xFF00BCD4),
    category: 'Body & Brain',
  ),
  (
    title: 'Sleep Consolidates Memory',
    body:
        'During deep sleep, your brain replays the day\'s experiences and moves memories from short-term to long-term storage. 7–9 hours per night is the sweet spot.',
    icon: '🌙',
    color: Color(0xFF6C63FF),
    category: 'Sleep Science',
  ),
  (
    title: 'Exercise Grows Your Brain',
    body:
        'Aerobic exercise increases the size of the hippocampus — the brain region involved in memory and learning. Just 30 min of moderate activity boosts BDNF levels.',
    icon: '🏋️',
    color: Color(0xFFFF8C00),
    category: 'Fitness',
  ),
  (
    title: 'Music Enhances Focus',
    body:
        'Listening to instrumental music or binaural beats can induce flow states and sharpen concentration. The "Mozart Effect" shows short-term spatial reasoning boosts.',
    icon: '🎵',
    color: Color(0xFF20BC68),
    category: 'Productivity',
  ),
  (
    title: 'Cold Showers Sharpen Alertness',
    body:
        'Cold water triggers a surge of noradrenaline — a neurotransmitter linked to focus and mood. Even 30 seconds of cold water can make a measurable difference.',
    icon: '🚿',
    color: Color(0xFF0288D1),
    category: 'Wellness',
  ),
  (
    title: 'Reading Rewires Your Brain',
    body:
        'Reading fiction activates the same brain regions used during real experiences. It builds empathy, vocabulary, and strengthens neural pathways for critical thinking.',
    icon: '📚',
    color: Color(0xFF8E24AA),
    category: 'Learning',
  ),
  (
    title: 'Your Brain Is 60% Fat',
    body:
        'The human brain is the fattiest organ in the body. Omega-3 fatty acids (found in fish and walnuts) are essential for maintaining brain cell structure and function.',
    icon: '🧠',
    color: Color(0xFFE91E63),
    category: 'Neuroscience',
  ),
  (
    title: 'Naps Supercharge Learning',
    body:
        'A 20-minute power nap can boost alertness by 54% and performance by 34%. NASA showed that napping improves mood, memory consolidation, and reaction time.',
    icon: '😴',
    color: Color(0xFF3F51B5),
    category: 'Sleep Science',
  ),
  (
    title: 'Gratitude Changes Brain Chemistry',
    body:
        'Practicing gratitude activates the medial prefrontal cortex and floods your brain with dopamine and serotonin. Even 5 minutes of journaling can rewire your mood.',
    icon: '🙏',
    color: Color(0xFFFF7043),
    category: 'Mental Health',
  ),
  (
    title: 'Multitasking Is a Myth',
    body:
        'The brain can\'t truly multitask — it rapidly switches between tasks, losing up to 40% efficiency. Deep focus on one task at a time produces far better results.',
    icon: '🎯',
    color: Color(0xFF00897B),
    category: 'Productivity',
  ),
];

class DidYouKnowScreen extends StatefulWidget {
  const DidYouKnowScreen({super.key});

  @override
  State<DidYouKnowScreen> createState() => _DidYouKnowScreenState();
}

class _DidYouKnowScreenState extends State<DidYouKnowScreen>
    with TickerProviderStateMixin {
  final _pageController = PageController(viewportFraction: 0.92);
  int _current = 0;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
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
    final fact = _facts[_current];
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
                  '${_current + 1} / ${_facts.length}',
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
          // Category pill
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
            child: Row(
              children: [
                AnimatedContainer(
                      key: ValueKey(_current),
                      duration: const Duration(milliseconds: 400),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: fact.color,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        fact.category,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                    .animate(key: ValueKey(_current))
                    .slideX(begin: -0.2, end: 0)
                    .fadeIn(),
              ],
            ),
          ),
          const SizedBox(height: 4),

          // PageView of cards
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _facts.length,
              onPageChanged: (i) => setState(() => _current = i),
              itemBuilder: (_, i) {
                final f = _facts[i];
                final isActive = i == _current;
                return AnimatedScale(
                  scale: isActive ? 1.0 : 0.93,
                  duration: const Duration(milliseconds: 300),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 6,
                    ),
                    child: _FactCard(
                      fact: f,
                      isActive: isActive,
                      pulseController: _pulseController,
                    ),
                  ),
                );
              },
            ),
          ),

          // Swipe hint
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Swipe to explore more facts',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey.shade400,
              ),
            ),
          ),

          // Dot indicators
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _facts.length,
                  (i) => GestureDetector(
                    onTap: () => _pageController.animateToPage(
                      i,
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: _current == i ? 28 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _current == i
                            ? _facts[_current].color
                            : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
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

class _FactCard extends StatelessWidget {
  final ({String title, String body, String icon, Color color, String category})
  fact;
  final bool isActive;
  final AnimationController pulseController;
  const _FactCard({
    required this.fact,
    required this.isActive,
    required this.pulseController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: fact.color.withValues(alpha: isActive ? 0.2 : 0.08),
            blurRadius: isActive ? 32 : 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            // Decorative background circles
            Positioned(
              top: -40,
              right: -40,
              child: AnimatedBuilder(
                animation: pulseController,
                builder: (context, child) => Container(
                  width: 180 + pulseController.value * 20,
                  height: 180 + pulseController.value * 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: fact.color.withValues(alpha: 0.06),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -30,
              left: -30,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: fact.color.withValues(alpha: 0.04),
                ),
              ),
            ),

            // Card content
            Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon with glow
                  Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: fact.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: fact.color.withValues(alpha: 0.3),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            fact.icon,
                            style: const TextStyle(fontSize: 32),
                          ),
                        ),
                      )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .scale(
                        begin: const Offset(1, 1),
                        end: const Offset(1.05, 1.05),
                        duration: 1800.ms,
                        curve: Curves.easeInOut,
                      ),

                  const SizedBox(height: 16),

                  // Title
                  Text(
                        fact.title,
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1A1A1A),
                          height: 1.2,
                        ),
                      )
                      .animate(key: ValueKey('${fact.title}_title'))
                      .fadeIn(duration: 400.ms, delay: 100.ms)
                      .slideY(begin: 0.15, end: 0),

                  const SizedBox(height: 10),

                  // Divider accent
                  Container(
                        width: 48,
                        height: 4,
                        decoration: BoxDecoration(
                          color: fact.color,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      )
                      .animate(key: ValueKey('${fact.title}_div'))
                      .fadeIn(delay: 150.ms)
                      .slideX(begin: -0.3, end: 0),

                  const SizedBox(height: 12),

                  // Body text
                  Expanded(
                    child: SingleChildScrollView(
                      child:
                          Text(
                                fact.body,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                  height: 1.6,
                                ),
                              )
                              .animate(key: ValueKey('${fact.title}_body'))
                              .fadeIn(duration: 500.ms, delay: 200.ms),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // CTA button
                  Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    fact.color,
                                    Color.lerp(fact.color, Colors.white, 0.3)!,
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: fact.color.withValues(alpha: 0.35),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(14),
                                  onTap: () {},
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.lightbulb_rounded,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Explore This Topic',
                                          style: GoogleFonts.poppins(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          _ShareButton(color: fact.color),
                        ],
                      )
                      .animate(key: ValueKey('${fact.title}_cta'))
                      .fadeIn(delay: 300.ms)
                      .slideY(begin: 0.2, end: 0),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShareButton extends StatelessWidget {
  final Color color;
  const _ShareButton({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
          ),
          child: Icon(Icons.share_rounded, color: color, size: 20),
        )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .shimmer(duration: 2500.ms, color: color.withValues(alpha: 0.2));
  }
}
