import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/user_provider.dart';
import '../../providers/game_provider.dart';
import '../../providers/settings_provider.dart';
import 'about_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>();
    final game = context.watch<GameProvider>();
    final settings = context.watch<SettingsProvider>();
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ── Profile Header ─────────────────────────────────
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    settings.appSeedColor,
                    settings.appSeedColor.withAlpha(180),
                  ],
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.white,
                    child: Text(
                      (user.userName?[0] ?? 'G').toUpperCase(),
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: settings.appSeedColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.userName ?? 'G-Bytes User',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Growth Member',
                          style: GoogleFonts.poppins(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${game.league.displayName} • ${game.totalPoints} pts',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms),
            const SizedBox(height: 24),

            // ── Sound ──────────────────────────────────────────
            _SectionCard(
              title: 'Sound',
              child: _ToggleRow(
                label: 'Sound Effects',
                subtitle: 'Timer audio cues & tick sounds',
                icon: Icons.volume_up_outlined,
                value: settings.soundEffectsEnabled,
                onChanged: settings.setSoundEffects,
                activeColor: primary,
              ),
            ).animate(delay: 100.ms).fadeIn(),
            const SizedBox(height: 16),

            // ── Timer Animation Dropdown ───────────────────────
            _SectionCard(
              title: 'Timer Animation',
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Animation style for interval timer',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _StyledDropdown<TimerAnimationType>(
                      value: settings.timerAnimation,
                      items: TimerAnimationType.values.map((type) {
                        final d = _animationData(type);
                        return DropdownMenuItem(
                          value: type,
                          child: Row(
                            children: [
                              Text(
                                d.emoji,
                                style: const TextStyle(fontSize: 20),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      d.label,
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      d.description,
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        color: Colors.grey.shade500,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (v) {
                        if (v != null) settings.setTimerAnimation(v);
                      },
                      accentColor: primary,
                    ),
                  ],
                ),
              ),
            ).animate(delay: 150.ms).fadeIn(),
            const SizedBox(height: 16),

            // ── Color Theme Dropdown ───────────────────────────
            _SectionCard(
              title: 'Color Theme',
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Choose your app accent color',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _StyledDropdown<AppThemeColor>(
                      value: settings.appThemeColor,
                      items: AppThemeColor.values.map((color) {
                        final d = _colorData(color);
                        return DropdownMenuItem(
                          value: color,
                          child: Row(
                            children: [
                              Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  color: d.color,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: d.color.withAlpha(80),
                                      blurRadius: 6,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '${d.emoji}  ${d.label}',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (v) {
                        if (v != null) settings.setAppThemeColor(v);
                      },
                      accentColor: settings.appSeedColor,
                    ),
                  ],
                ),
              ),
            ).animate(delay: 200.ms).fadeIn(),
            const SizedBox(height: 16),

            // ── General / About ────────────────────────────────
            _SectionCard(
              title: 'General',
              child: ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        settings.appSeedColor,
                        settings.appSeedColor.withAlpha(180),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: settings.appSeedColor.withValues(alpha: 0.3),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      'G',
                      style: GoogleFonts.russoOne(
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                title: Text(
                  'About G-Bytes',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  'Version 1.0.0 — Our story & what\'s coming',
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: Colors.grey,
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AboutScreen()),
                ),
              ),
            ).animate(delay: 250.ms).fadeIn(),
            const SizedBox(height: 16),

            // ── Sign Out ───────────────────────────────────────
            ElevatedButton.icon(
              onPressed: () {
                context.read<UserProvider>().logout();
                context.go('/login');
              },
              icon: const Icon(Icons.logout_rounded),
              label: const Text('SIGN OUT'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade800,
              ),
            ).animate(delay: 300.ms).fadeIn(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  _AnimData _animationData(TimerAnimationType type) {
    switch (type) {
      case TimerAnimationType.jellyfish:
        return _AnimData(
          emoji: '🪼',
          label: 'Jellyfish Glow',
          description: 'Flowing tentacles & radial glow rings',
          color: const Color(0xFF00E5FF),
        );
      case TimerAnimationType.bubbleBurst:
        return _AnimData(
          emoji: '🫧',
          label: 'Bubble Burst',
          description: 'Expanding bubbles that burst on phase change',
          color: const Color(0xFF7C4DFF),
        );
      case TimerAnimationType.starDust:
        return _AnimData(
          emoji: '✨',
          label: 'Star Dust',
          description: 'Twinkling star particles & shooting trails',
          color: const Color(0xFFFFB300),
        );
    }
  }

  _ColorData _colorData(AppThemeColor color) {
    switch (color) {
      case AppThemeColor.orange:
        return _ColorData(
          emoji: '🔶',
          label: 'Orange',
          color: const Color(
            0xFFFF8C00,
          ), // orange stays in the color-picker data item
        );
      case AppThemeColor.cyan:
        return _ColorData(
          emoji: '🩵',
          label: 'Cyan',
          color: const Color(0xFF00BCD4),
        );
      case AppThemeColor.purple:
        return _ColorData(
          emoji: '💜',
          label: 'Purple',
          color: const Color(0xFF7C4DFF),
        );
    }
  }
}

// ── Data helpers ──────────────────────────────────────────────────
class _AnimData {
  final String emoji;
  final String label;
  final String description;
  final Color color;
  _AnimData({
    required this.emoji,
    required this.label,
    required this.description,
    required this.color,
  });
}

class _ColorData {
  final String emoji;
  final String label;
  final Color color;
  _ColorData({required this.emoji, required this.label, required this.color});
}

// ── Styled Dropdown ───────────────────────────────────────────────
class _StyledDropdown<T> extends StatelessWidget {
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final Color accentColor;

  const _StyledDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accentColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: accentColor.withAlpha(25),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: accentColor),
          items: items,
          onChanged: onChanged,
          selectedItemBuilder: (context) => items.map((item) {
            return Align(alignment: Alignment.centerLeft, child: item.child);
          }).toList(),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(14),
          itemHeight: 60,
        ),
      ),
    );
  }
}

// ── Section Card ──────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              title,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: Colors.grey.shade500,
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

// ── Toggle Row ────────────────────────────────────────────────────
class _ToggleRow extends StatelessWidget {
  final String label;
  final String? subtitle;
  final IconData icon;
  final bool value;
  final Future<void> Function(bool) onChanged;
  final Color activeColor;

  const _ToggleRow({
    required this.label,
    this.subtitle,
    required this.icon,
    required this.value,
    required this.onChanged,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: value ? activeColor : Colors.grey),
      title: Text(
        label,
        style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            )
          : null,
      trailing: Switch.adaptive(
        value: value,
        onChanged: (v) => onChanged(v),
        activeTrackColor: activeColor,
      ),
    );
  }
}
