import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/nav_provider.dart';
import '../providers/timer_provider.dart';
import '../providers/interval_timer_provider.dart';
import 'home/g_zone_screen.dart';
import 'timer/timer_shell_screen.dart';
import 'games/brain_hub_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with WidgetsBindingObserver {
  // Screens instantiated once and kept alive via IndexedStack.
  // AnimatedSwitcher + KeyedSubtree was unmounting/remounting on every tab
  // switch, destroying in-flight game state.
  static const _screens = [
    BrainHubScreen(),
    GZoneScreen(),
    TimerShellScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      final timer = context.read<TimerProvider>();
      if (timer.status == TimerStatus.running) timer.pause();
      final interval = context.read<IntervalTimerProvider>();
      if (interval.isRunning) interval.pauseResume();
    }
  }

  int _prevIndex = 0;

  @override
  Widget build(BuildContext context) {
    final index = context.select<NavProvider, int>((n) => n.currentIndex);
    final forward = index >= _prevIndex;
    _prevIndex = index;
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      extendBody: true,
      body: Stack(
        children: [
          for (int i = 0; i < _screens.length; i++)
            AnimatedOpacity(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOut,
              opacity: i == index ? 1.0 : 0.0,
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                offset: i == index
                    ? Offset.zero
                    : (forward ? const Offset(-0.04, 0) : const Offset(0.04, 0)),
                child: IgnorePointer(
                  ignoring: i != index,
                  child: _screens[i],
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: _GBytesNavBar(currentIndex: index),
    );
  }
}

// â”€â”€ Floating Pill Nav Bar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _GBytesNavBar extends StatelessWidget {
  final int currentIndex;
  const _GBytesNavBar({required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(44, 0, 44, 22),
      child: SafeArea(
        top: false,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(44),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              height: 68,
              decoration: BoxDecoration(
                color: const Color(0xFF0A0A0A).withValues(alpha: 0.96),
                borderRadius: BorderRadius.circular(44),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.07)),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                    blurRadius: 24,
                    spreadRadius: 0,
                    offset: const Offset(0, -2),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.50),
                    blurRadius: 32,
                    spreadRadius: 0,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _BrainNavItem(
                    index: 0,
                    current: currentIndex,
                  ),
                  _PillNavItem(
                    icon: Icons.explore_outlined,
                    activeIcon: Icons.explore_rounded,
                    label: 'G-Zone',
                    index: 1,
                    current: currentIndex,
                  ),
                  _PillNavItem(
                    icon: Icons.timer_outlined,
                    activeIcon: Icons.timer_rounded,
                    label: 'G-Timer',
                    index: 2,
                    current: currentIndex,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PillNavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  final int current;

  const _PillNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
    required this.current,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = index == current;
    return GestureDetector(
      onTap: () => context.read<NavProvider>().setIndex(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: isActive ? 20 : 16,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isActive
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(32),
          border: isActive
              ? Border.all(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.35),
                  width: 1)
              : null,
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.18),
                    blurRadius: 14,
                    spreadRadius: 0,
                  )
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isActive ? activeIcon : icon,
                key: ValueKey(isActive),
                color: isActive
                    ? Theme.of(context).colorScheme.primary
                    : Colors.white.withValues(alpha: 0.38),
                size: 22,
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeInOut,
              child: isActive
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(width: 8),
                        Text(
                          label,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

// â”€â”€ Brain Nav Item (custom wire-brain icon) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _BrainNavItem extends StatelessWidget {
  final int index;
  final int current;
  const _BrainNavItem({required this.index, required this.current});

  @override
  Widget build(BuildContext context) {
    final isActive = index == current;
    return GestureDetector(
      onTap: () => context.read<NavProvider>().setIndex(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: isActive ? 20 : 16,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isActive
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(32),
          border: isActive
              ? Border.all(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.35),
                  width: 1)
              : null,
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.18),
                    blurRadius: 14,
                  )
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: CustomPaint(
                painter: _WireBrainIcon(
                  color: isActive
                      ? Theme.of(context).colorScheme.primary
                      : Colors.white.withValues(alpha: 0.38),
                ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeInOut,
              child: isActive
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(width: 8),
                        Text(
                          'Brain',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Wire/outline brain icon drawn with CustomPainter â€” no SVG asset needed.
class _WireBrainIcon extends CustomPainter {
  final Color color;
  const _WireBrainIcon({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;

    // Left hemisphere outline
    final left = Path()
      ..moveTo(w * 0.50, h * 0.18)
      ..cubicTo(w * 0.36, h * 0.04, w * 0.06, h * 0.10,
                w * 0.06, h * 0.36)
      ..cubicTo(w * 0.06, h * 0.54, w * 0.14, h * 0.62,
                w * 0.22, h * 0.68)
      ..cubicTo(w * 0.26, h * 0.80, w * 0.36, h * 0.86,
                w * 0.50, h * 0.86);
    canvas.drawPath(left, p);

    // Right hemisphere outline
    final right = Path()
      ..moveTo(w * 0.50, h * 0.18)
      ..cubicTo(w * 0.64, h * 0.04, w * 0.94, h * 0.10,
                w * 0.94, h * 0.36)
      ..cubicTo(w * 0.94, h * 0.54, w * 0.86, h * 0.62,
                w * 0.78, h * 0.68)
      ..cubicTo(w * 0.74, h * 0.80, w * 0.64, h * 0.86,
                w * 0.50, h * 0.86);
    canvas.drawPath(right, p);

    // Corpus callosum (center divider)
    canvas.drawLine(
      Offset(w * 0.50, h * 0.18),
      Offset(w * 0.50, h * 0.86),
      p..strokeWidth = 1.1,
    );

    // Brain stem nub
    p.strokeWidth = 1.7;
    canvas.drawLine(
      Offset(w * 0.50, h * 0.86),
      Offset(w * 0.50, h * 0.96),
      p,
    );

    // Left gyri wrinkle lines
    final gyriL = Path()
      ..moveTo(w * 0.24, h * 0.32)
      ..quadraticBezierTo(w * 0.18, h * 0.40, w * 0.22, h * 0.50)
      ..moveTo(w * 0.32, h * 0.24)
      ..quadraticBezierTo(w * 0.20, h * 0.28, w * 0.16, h * 0.38);
    canvas.drawPath(gyriL, p..strokeWidth = 1.1);

    // Right gyri wrinkle lines
    final gyriR = Path()
      ..moveTo(w * 0.76, h * 0.32)
      ..quadraticBezierTo(w * 0.82, h * 0.40, w * 0.78, h * 0.50)
      ..moveTo(w * 0.68, h * 0.24)
      ..quadraticBezierTo(w * 0.80, h * 0.28, w * 0.84, h * 0.38);
    canvas.drawPath(gyriR, p);
  }

  @override
  bool shouldRepaint(_WireBrainIcon old) => old.color != color;
}

// â”€â”€ Shared Page Route Helpers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class AppRoutes {
  AppRoutes._();

  /// Slide up + fade â€” use for detail screens.
  static PageRoute<T> slideUp<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (_, a1, a2) => page,
      transitionDuration: const Duration(milliseconds: 350),
      reverseTransitionDuration: const Duration(milliseconds: 280),
      transitionsBuilder: (_, anim, sa, child) {
        return FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween<Offset>(
                    begin: const Offset(0, 0.10), end: Offset.zero)
                .animate(
                    CurvedAnimation(parent: anim, curve: Curves.easeOut)),
            child: child,
          ),
        );
      },
    );
  }

  /// Slide in from right â€” use for nested navigation.
  static PageRoute<T> slideRight<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (_, a1, a2) => page,
      transitionDuration: const Duration(milliseconds: 320),
      reverseTransitionDuration: const Duration(milliseconds: 260),
      transitionsBuilder: (_, anim, sa, child) {
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
              .animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
          child: FadeTransition(opacity: anim, child: child),
        );
      },
    );
  }
}

