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
                          '${game.league.displayName} \u2022 ${game.totalPoints} pts',
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

            // ── Color Theme ───────────────────────────────────
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
                    const SizedBox(height: 12),
                    // Color swatch grid
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: AppThemeColor.values.map((color) {
                        final d = _colorData(color);
                        final isSelected = settings.appThemeColor == color;
                        return GestureDetector(
                          onTap: () => settings.setAppThemeColor(color),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: d.color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.transparent,
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: d.color.withAlpha(
                                    isSelected ? 120 : 60,
                                  ),
                                  blurRadius: isSelected ? 16 : 8,
                                  spreadRadius: isSelected ? 2 : 0,
                                ),
                              ],
                            ),
                            child: isSelected
                                ? const Icon(
                                    Icons.check_rounded,
                                    color: Colors.white,
                                    size: 22,
                                  )
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      settings.appThemeColorLabel,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: primary,
                      ),
                    ),
                  ],
                ),
              ),
            ).animate(delay: 150.ms).fadeIn(),
            const SizedBox(height: 16),

            // ── General ────────────────────────────────────────
            _SectionCard(
              title: 'General',
              child: Column(
                children: [
                  // Rename
                  ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: primary.withAlpha(20),
                        border: Border.all(
                          color: primary.withAlpha(60),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        Icons.drive_file_rename_outline_rounded,
                        color: primary,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      'Rename',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      'Change your display name',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: Colors.grey,
                    ),
                    onTap: () => _showRenameDialog(context, user),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  // About
                  ListTile(
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
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
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
                ],
              ),
            ).animate(delay: 200.ms).fadeIn(),
            const SizedBox(height: 16),

            // ── Reset App ─────────────────────────────────────
            _SectionCard(
              title: 'Danger Zone',
              child: ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.red.shade50,
                    border: Border.all(
                      color: Colors.red.shade200,
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    Icons.restart_alt_rounded,
                    color: Colors.red.shade600,
                    size: 22,
                  ),
                ),
                title: Text(
                  'Reset App',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: Colors.red.shade700,
                  ),
                ),
                subtitle: Text(
                  'Clears all data and progress',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                trailing: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: Colors.grey,
                ),
                onTap: () => _showResetDialog(context),
              ),
            ).animate(delay: 250.ms).fadeIn(),
            const SizedBox(height: 28),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Rename',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 20,
          decoration: InputDecoration(
            hintText: 'Enter new name',
            hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400),
            filled: true,
            fillColor: primary.withAlpha(12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: primary.withAlpha(60)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: primary, width: 2),
            ),
            counterText: '',
          ),
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
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
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Save',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Reset App?',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            color: Colors.red.shade700,
          ),
        ),
        content: Text(
          'This will permanently delete all your progress, points, streaks, and data. This action cannot be undone.',
          style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade700),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              // Capture all context-dependent refs before the first await
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
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Reset',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  _ColorData _colorData(AppThemeColor color) {
    switch (color) {
      case AppThemeColor.orange:
        return _ColorData(label: 'Orange', color: const Color(0xFFFF8C00));
      case AppThemeColor.cyan:
        return _ColorData(label: 'Cyan', color: const Color(0xFF00BCD4));
      case AppThemeColor.purple:
        return _ColorData(label: 'Purple', color: const Color(0xFF7C4DFF));
      case AppThemeColor.emeraldGreen:
        return _ColorData(label: 'Emerald', color: const Color(0xFF1A7A50));
      case AppThemeColor.brickRed:
        return _ColorData(label: 'Brick Red', color: const Color(0xFFA0303A));
    }
  }
}

// ── Data helpers ──────────────────────────────────────────────────
class _ColorData {
  final String label;
  final Color color;
  _ColorData({required this.label, required this.color});
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
