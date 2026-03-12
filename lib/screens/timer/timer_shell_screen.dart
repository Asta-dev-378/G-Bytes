import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'timer_screen.dart';
import 'interval_timer_setup_screen.dart';

class TimerShellScreen extends StatefulWidget {
  const TimerShellScreen({super.key});

  @override
  State<TimerShellScreen> createState() => _TimerShellScreenState();
}

class _TimerShellScreenState extends State<TimerShellScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const orange = Color(0xFFFF8C00);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'G Timer',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: const Color(0xFF1A1A1A),
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Color(0xFF1A1A1A)),
            onPressed: () {},
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: orange,
          unselectedLabelColor: Colors.grey.shade600,
          labelStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
          indicatorColor: orange,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Classic Timer'),
            Tab(text: 'Interval Timer'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics:
            const NeverScrollableScrollPhysics(), // Prevent swipe for tighter control
        children: const [
          // Render the original timer screen, minus its own appbar
          _ClassicTimerTab(),
          IntervalTimerSetupScreen(),
        ],
      ),
    );
  }
}

// Wrapper to remove the AppBar from the original TimerScreen
// Alternatively, we could directly modify TimerScreen to not have an AppBar.
// For faster iteration without breaking anything else, wrapping is safer first.
class _ClassicTimerTab extends StatelessWidget {
  const _ClassicTimerTab();
  @override
  Widget build(BuildContext context) {
    // We will just directly modify timer_screen.dart to remove the AppBar
    return const TimerScreen();
  }
}
