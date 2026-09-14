import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum TimerAnimationType { jellyfish, bubbleBurst, starDust }

/// Two thunder-themed accent variants — orange (default) and purple.
enum AppThemeColor { orange, purple }

class SettingsProvider extends ChangeNotifier {
  bool _soundEffectsEnabled = true;
  TimerAnimationType _timerAnimation = TimerAnimationType.starDust;
  bool _schulteHardMode = false;
  AppThemeColor _appThemeColor = AppThemeColor.orange;

  SharedPreferences? _prefs;

  bool get soundEffectsEnabled => _soundEffectsEnabled;
  TimerAnimationType get timerAnimation => _timerAnimation;
  bool get schulteHardMode => _schulteHardMode;
  AppThemeColor get appThemeColor => _appThemeColor;
  bool get isPurpleThunder => _appThemeColor == AppThemeColor.purple;

  /// Primary accent — drives the entire Material ColorScheme.
  Color get appSeedColor {
    switch (_appThemeColor) {
      case AppThemeColor.orange:
        return const Color(0xFFFF6B00); // Thunder orange
      case AppThemeColor.purple:
        return const Color(0xFF9B5DE5); // Purple thunder
    }
  }

  /// Secondary accent used for chips, badges, highlights.
  Color get appSecondaryColor {
    switch (_appThemeColor) {
      case AppThemeColor.orange:
        return const Color(0xFFFFB800); // Electric amber flash
      case AppThemeColor.purple:
        return const Color(0xFFD4A4F7); // Soft lavender
    }
  }

  String get appThemeColorLabel {
    switch (_appThemeColor) {
      case AppThemeColor.orange:
        return 'Thunder Orange';
      case AppThemeColor.purple:
        return 'Purple Thunder';
    }
  }

  SettingsProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _prefs = prefs;
    _soundEffectsEnabled = prefs.getBool('sound_effects') ?? true;
    _schulteHardMode = prefs.getBool('schulte_hard_mode') ?? false;
    final animIdx = prefs.getInt('timer_animation') ?? 2;
    _timerAnimation = TimerAnimationType
        .values[animIdx.clamp(0, TimerAnimationType.values.length - 1)];
    final colorIdx = prefs.getInt('app_theme_color') ?? 0;
    _appThemeColor = AppThemeColor
        .values[colorIdx.clamp(0, AppThemeColor.values.length - 1)];
    notifyListeners();
  }

  Future<void> setSoundEffects(bool value) async {
    _soundEffectsEnabled = value;
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.setBool('sound_effects', value);
    notifyListeners();
  }

  Future<void> setTimerAnimation(TimerAnimationType type) async {
    _timerAnimation = type;
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.setInt('timer_animation', type.index);
    notifyListeners();
  }

  Future<void> setSchulteHardMode(bool value) async {
    _schulteHardMode = value;
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.setBool('schulte_hard_mode', value);
    notifyListeners();
  }

  Future<void> setAppThemeColor(AppThemeColor color) async {
    _appThemeColor = color;
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.setInt('app_theme_color', color.index);
    notifyListeners();
  }

  String get timerAnimationLabel {
    switch (_timerAnimation) {
      case TimerAnimationType.jellyfish:
        return 'Jellyfish Glow';
      case TimerAnimationType.bubbleBurst:
        return 'Bubble Burst';
      case TimerAnimationType.starDust:
        return 'Star Dust';
    }
  }
}
