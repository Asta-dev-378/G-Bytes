import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/nav_provider.dart';
import '../providers/timer_provider.dart';
import '../providers/interval_timer_provider.dart';
import 'home/g_zone_screen.dart';
import 'timer/timer_shell_screen.dart';
import 'music/music_player_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with WidgetsBindingObserver {
  static const List<Widget> _screens = [
    GZoneScreen(),
    TimerShellScreen(),
    MusicPlayerScreen(),
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
      // Pause classic timer if running
      final timer = context.read<TimerProvider>();
      if (timer.status == TimerStatus.running) {
        timer.pause();
      }
      // Stop interval timer if running
      final interval = context.read<IntervalTimerProvider>();
      if (interval.isRunning) {
        interval.pauseResume(); // toggles to paused
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<NavProvider>();
    return Scaffold(
      body: IndexedStack(index: nav.currentIndex, children: _screens),
      bottomNavigationBar: _GBytesNavBar(currentIndex: nav.currentIndex),
    );
  }
}

class _GBytesNavBar extends StatelessWidget {
  final int currentIndex;
  const _GBytesNavBar({required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 66,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.explore_outlined,
                activeIcon: Icons.explore,
                label: 'G-Zone',
                index: 0,
                current: currentIndex,
                color: primary,
              ),
              _NavItem(
                icon: Icons.timer_outlined,
                activeIcon: Icons.timer,
                label: 'G-Timer',
                index: 1,
                current: currentIndex,
                color: primary,
              ),
              _NavItem(
                icon: Icons.music_note_outlined,
                activeIcon: Icons.music_note,
                label: 'G-Tunes',
                index: 2,
                current: currentIndex,
                color: primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  final int current;
  final Color color;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
    required this.current,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = index == current;
    return GestureDetector(
      onTap: () => context.read<NavProvider>().setIndex(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? color.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isActive ? activeIcon : icon,
                key: ValueKey(isActive),
                color: isActive ? color : Colors.grey.shade400,
                size: 24,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                color: isActive ? color : Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
