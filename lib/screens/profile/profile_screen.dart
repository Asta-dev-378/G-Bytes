import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/user_provider.dart';
import '../../providers/game_provider.dart';
import '../../providers/player_progress_provider.dart';
import '../../providers/settings_provider.dart';
import 'about_screen.dart';

// â”€â”€ Design tokens â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

const _bg      = Color(0xFF0A0A0F);
const _surface = Color(0xFF12121A);
const _lime    = Color(0xFFC6E05B);

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user     = context.watch<UserProvider>();
    final game     = context.watch<GameProvider>();
    final progress = context.watch<PlayerProgressProvider>();
    final settings = context.watch<SettingsProvider>();
    final primary  = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: _bg,
      // â”€â”€ Dark frosted app bar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              decoration: BoxDecoration(
                color: _bg.withValues(alpha: 0.88),
                border: Border(
                  bottom: BorderSide(
                      color: Colors.white.withValues(alpha: 0.07))),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 16, 0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white70, size: 18),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      Text('Profile',
                          style: GoogleFonts.poppins(
                            fontSize: 18, fontWeight: FontWeight.w800,
                            color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
        child: Column(
          children: [
            // â”€â”€ Profile Hero â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            _ProfileHero(
              user: user,
              game: game,
              progress: progress,
              primary: primary,
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.08, end: 0),
            const SizedBox(height: 20),

            // â”€â”€ Stats row â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            _StatsRow(game: game, primary: primary)
                .animate(delay: 60.ms).fadeIn().slideY(begin: 0.08, end: 0),
            const SizedBox(height: 20),

            // â”€â”€ Sound â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            _GlassSection(
              title: 'Sound',
              icon: Icons.volume_up_rounded,
              child: _DarkToggleRow(
                label: 'Sound Effects',
                subtitle: 'Timer audio cues & tick sounds',
                icon: Icons.volume_up_outlined,
                value: settings.soundEffectsEnabled,
                onChanged: settings.setSoundEffects,
                activeColor: primary,
              ),
            ).animate(delay: 100.ms).fadeIn(),
            const SizedBox(height: 14),

            // â”€â”€ Color Theme â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            _GlassSection(
              title: 'Color Theme',
              icon: Icons.palette_rounded,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Choose your app accent color',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.white38,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 12,
                      runSpacing: 14,
                      children: AppThemeColor.values.map((themeColor) {
                        final isSelected = settings.appThemeColor == themeColor;
                        final d = _colorData(themeColor);
                        return GestureDetector(
                          onTap: () => settings.setAppThemeColor(themeColor),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            width: 52, height: 52,
                            decoration: BoxDecoration(
                              color: d.color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? Colors.white : Colors.transparent,
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: d.color.withAlpha(isSelected ? 140 : 60),
                                  blurRadius: isSelected ? 18 : 8,
                                  spreadRadius: isSelected ? 2 : 0,
                                ),
                              ],
                            ),
                            child: isSelected
                                ? const Icon(Icons.check_rounded,
                                    color: Colors.white, size: 22)
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      settings.appThemeColorLabel,
                      style: GoogleFonts.poppins(
                        fontSize: 13, fontWeight: FontWeight.w600,
                        color: primary,
                      ),
                    ),
                  ],
                ),
              ),
            ).animate(delay: 150.ms).fadeIn(),
            const SizedBox(height: 14),

            // â”€â”€ General â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            _GlassSection(
              title: 'General',
              icon: Icons.settings_rounded,
              child: Column(
                children: [
                  _DarkListTile(
                    icon: Icons.drive_file_rename_outline_rounded,
                    iconColor: primary,
                    title: 'Rename',
                    subtitle: 'Change your display name',
                    onTap: () => _showRenameDialog(context, user),
                  ),
                  Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      color: Colors.white.withValues(alpha: 0.06)),
                  _DarkListTile(
                    icon: Icons.info_outline_rounded,
                    iconColor: settings.appSeedColor,
                    title: 'About G-Bytes',
                    subtitle: 'Version 1.0.0 â€” Our story & what\'s coming',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AboutScreen()),
                    ),
                  ),
                ],
              ),
            ).animate(delay: 200.ms).fadeIn(),
            const SizedBox(height: 14),

            // â”€â”€ Danger Zone â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            _GlassSection(
              title: 'Danger Zone',
              icon: Icons.warning_amber_rounded,
              iconColor: Colors.red,
              child: _DarkListTile(
                icon: Icons.restart_alt_rounded,
                iconColor: Colors.red,
                title: 'Reset App',
                titleColor: Colors.red,
                subtitle: 'Clears all data and progress',
                onTap: () => _showResetDialog(context),
              ),
            ).animate(delay: 250.ms).fadeIn(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _showRenameDialog(BuildContext context, UserProvider user) {
    final controller = TextEditingController(text: user.userName ?? '');
    final primary = Theme.of(context).colorScheme.primary;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
                color: Colors.white.withValues(alpha: 0.08))),
        title: Text('Rename',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700, color: Colors.white)),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 20,
          style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600, color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Enter new name',
            hintStyle: GoogleFonts.poppins(color: Colors.white38),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.06),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.12)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: primary, width: 2),
            ),
            counterText: '',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.poppins(color: Colors.white38)),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                context.read<UserProvider>().rename(controller.text.trim());
              }
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Save',
                style: GoogleFonts.poppins(
                    color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.red.withValues(alpha: 0.25))),
        title: Text('Reset App?',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700, color: Colors.red)),
        content: Text(
          'This will permanently delete all your progress, points, streaks, and data. This action cannot be undone.',
          style: GoogleFonts.poppins(fontSize: 14, color: Colors.white60),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.poppins(
                    color: Colors.white38, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final game = context.read<GameProvider>();
              final user = context.read<UserProvider>();
              final router = GoRouter.of(context);
              await game.resetAllData();
              await user.logout();
              router.go('/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Reset',
                style: GoogleFonts.poppins(
                    color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  _ColorData _colorData(AppThemeColor color) {
    switch (color) {
      case AppThemeColor.orange:
        return _ColorData(label: 'Thunder Orange', color: const Color(0xFFFF6B00));
      case AppThemeColor.purple:
        return _ColorData(label: 'Purple Thunder', color: const Color(0xFF9B5DE5));
    }
  }
}

// â”€â”€ Profile Hero â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _ProfileHero extends StatelessWidget {
  final UserProvider user;
  final GameProvider game;
  final PlayerProgressProvider progress;
  final Color primary;

  const _ProfileHero({
    required this.user,
    required this.game,
    required this.progress,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _surface,
            primary.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
            color: primary.withValues(alpha: 0.20)),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.15),
            blurRadius: 24, spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar with neon ring
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [primary, primary.withValues(alpha: 0.40)],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
              boxShadow: [
                BoxShadow(
                  color: primary.withValues(alpha: 0.45),
                  blurRadius: 16, spreadRadius: 1),
              ],
            ),
            child: CircleAvatar(
              radius: 34,
              backgroundColor: _bg,
              child: Text(
                (user.userName?[0] ?? 'G').toUpperCase(),
                style: GoogleFonts.poppins(
                  fontSize: 26, fontWeight: FontWeight.w900,
                  color: primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.userName ?? 'G-Bytes User',
                  style: GoogleFonts.poppins(
                    color: Colors.white, fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(progress.league.icon,
                        color: progress.league.color, size: 14),
                    const SizedBox(width: 5),
                    Text(
                      '${progress.league.displayName} League',
                      style: GoogleFonts.poppins(
                        color: progress.league.color,
                        fontSize: 12, fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // XP bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (game.totalPoints % 1000) / 1000,
                    minHeight: 4,
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                    valueColor: AlwaysStoppedAnimation(primary),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${game.totalPoints} XP total',
                  style: GoogleFonts.poppins(
                    color: Colors.white38, fontSize: 11,
                    fontWeight: FontWeight.w500,
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

// â”€â”€ Stats row â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _StatsRow extends StatelessWidget {
  final GameProvider game;
  final Color primary;
  const _StatsRow({required this.game, required this.primary});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatPill(
          icon: Icons.local_fire_department_rounded,
          value: '${game.streak}',
          label: 'Streak',
          color: const Color(0xFFF07845),
        ),
        const SizedBox(width: 10),
        _StatPill(
          icon: Icons.star_rounded,
          value: '${game.totalPoints}',
          label: 'XP',
          color: _lime,
        ),
        const SizedBox(width: 10),
        _StatPill(
          icon: Icons.emoji_events_rounded,
          value: '${game.bestStreak}',
          label: 'Best',
          color: const Color(0xFFF59E0B),
        ),
      ],
    );
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  const _StatPill({
    required this.icon, required this.value,
    required this.label, required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.25)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.15),
              blurRadius: 12),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(value,
                style: GoogleFonts.poppins(
                  color: color, fontSize: 18,
                  fontWeight: FontWeight.w900)),
            Text(label,
                style: GoogleFonts.poppins(
                  color: Colors.white38, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

// â”€â”€ Glass Section â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _GlassSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final Widget child;

  const _GlassSection({
    required this.title,
    required this.icon,
    this.iconColor = Colors.white54,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 14, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                Icon(icon, size: 14, color: iconColor),
                const SizedBox(width: 6),
                Text(title,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: Colors.white38,
                      letterSpacing: 0.8,
                    )),
              ],
            ),
          ),
          child,
        ],
      ),
    );
  }
}

// â”€â”€ Dark toggle row â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _DarkToggleRow extends StatelessWidget {
  final String label;
  final String? subtitle;
  final IconData icon;
  final bool value;
  final Future<void> Function(bool) onChanged;
  final Color activeColor;

  const _DarkToggleRow({
    required this.label, this.subtitle,
    required this.icon, required this.value,
    required this.onChanged, required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon,
          color: value ? activeColor : Colors.white30),
      title: Text(label,
          style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600, color: Colors.white)),
      subtitle: subtitle != null
          ? Text(subtitle!,
              style: GoogleFonts.poppins(
                fontSize: 12, color: Colors.white38))
          : null,
      trailing: Switch.adaptive(
        value: value,
        onChanged: (v) => onChanged(v),
        activeTrackColor: activeColor,
      ),
    );
  }
}

// â”€â”€ Dark list tile â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _DarkListTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final Color? titleColor;
  final String subtitle;
  final VoidCallback? onTap;

  const _DarkListTile({
    required this.icon, required this.iconColor,
    required this.title, this.titleColor,
    required this.subtitle, this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 38, height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: iconColor.withValues(alpha: 0.12),
          border: Border.all(
              color: iconColor.withValues(alpha: 0.25), width: 1.2),
        ),
        child: Icon(icon, color: iconColor, size: 18),
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          color: titleColor ?? Colors.white,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.poppins(
          fontSize: 12, color: Colors.white38),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios_rounded,
        size: 13, color: Colors.white24),
      onTap: onTap,
    );
  }
}

// â”€â”€ Data helpers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _ColorData {
  final String label;
  final Color color;
  _ColorData({required this.label, required this.color});
}
