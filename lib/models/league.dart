import 'package:flutter/material.dart';

/// Defines the 7 leagues × 3 sub-levels = 21 tiers.
/// League names: Spark → Pulse → Flux → Nova → Apex → Titan → Nexus
/// Flux (tier 6) unlocks Medium difficulty.
/// Apex (tier 12) unlocks Hard difficulty.
class LeagueInfo {
  final String name;
  final String romanLevel; // I, II, III
  final Color color;
  final Color bgColor;
  final IconData icon;
  final int tierIndex; // 0-20
  final int pointsForTier; // points required to reach this tier

  const LeagueInfo({
    required this.name,
    required this.romanLevel,
    required this.color,
    required this.bgColor,
    required this.icon,
    required this.tierIndex,
    required this.pointsForTier,
  });

  String get displayName => '$name $romanLevel';

  /// Returns the [LeagueInfo] for a given total points value.
  static LeagueInfo fromPoints(int points) {
    for (int i = _tiers.length - 1; i >= 0; i--) {
      if (points >= _tiers[i].pointsForTier) {
        return _tiers[i];
      }
    }
    return _tiers[0];
  }

  /// Progress within the current tier (0.0 – 1.0).
  static double progressInTier(int points) {
    final currentTier = fromPoints(points);
    if (currentTier.tierIndex >= _tiers.length - 1) return 1.0;

    final nextTier = _tiers[currentTier.tierIndex + 1];
    final tierStart = currentTier.pointsForTier;
    final tierEnd = nextTier.pointsForTier;
    final range = tierEnd - tierStart;

    if (range <= 0) return 0.0;
    return ((points - tierStart) / range).clamp(0.0, 1.0);
  }

  /// Points still needed to reach the next tier.
  static int pointsToNextTier(int points) {
    final currentTier = fromPoints(points);
    if (currentTier.tierIndex >= _tiers.length - 1) return 0;

    final nextTier = _tiers[currentTier.tierIndex + 1];
    return nextTier.pointsForTier - points;
  }

  /// Returns the highest difficulty the player can access based on their tier.
  /// Spark/Pulse (0–5)  → Easy only
  /// Flux/Nova  (6–11)  → Easy + Medium
  /// Apex/Titan/Nexus (12–20) → Easy + Medium + Hard
  static BrainDifficultyUnlock maxUnlocked(int tierIndex) {
    if (tierIndex >= 12) return BrainDifficultyUnlock.hard;
    if (tierIndex >= 6)  return BrainDifficultyUnlock.medium;
    return BrainDifficultyUnlock.easy;
  }

  /// League name that unlocks Medium (shown in lock hint).
  static const String mediumUnlockLeague = 'Flux';

  /// League name that unlocks Hard (shown in lock hint).
  static const String hardUnlockLeague = 'Apex';

  static const List<LeagueInfo> _tiers = [
    // ── Spark ──────────────────────────────────────────────────────────────
    LeagueInfo(
      name: 'Spark', romanLevel: 'I',
      color: Color(0xFFF59E0B), bgColor: Color(0xFFFEF3C7),
      icon: Icons.electric_bolt_rounded,
      tierIndex: 0, pointsForTier: 0,
    ),
    LeagueInfo(
      name: 'Spark', romanLevel: 'II',
      color: Color(0xFFF59E0B), bgColor: Color(0xFFFEF3C7),
      icon: Icons.electric_bolt_rounded,
      tierIndex: 1, pointsForTier: 250,
    ),
    LeagueInfo(
      name: 'Spark', romanLevel: 'III',
      color: Color(0xFFF59E0B), bgColor: Color(0xFFFEF3C7),
      icon: Icons.electric_bolt_rounded,
      tierIndex: 2, pointsForTier: 500,
    ),
    // ── Pulse ──────────────────────────────────────────────────────────────
    LeagueInfo(
      name: 'Pulse', romanLevel: 'I',
      color: Color(0xFF6366F1), bgColor: Color(0xFFEEF2FF),
      icon: Icons.radio_button_checked_rounded,
      tierIndex: 3, pointsForTier: 1000,
    ),
    LeagueInfo(
      name: 'Pulse', romanLevel: 'II',
      color: Color(0xFF6366F1), bgColor: Color(0xFFEEF2FF),
      icon: Icons.radio_button_checked_rounded,
      tierIndex: 4, pointsForTier: 1500,
    ),
    LeagueInfo(
      name: 'Pulse', romanLevel: 'III',
      color: Color(0xFF6366F1), bgColor: Color(0xFFEEF2FF),
      icon: Icons.radio_button_checked_rounded,
      tierIndex: 5, pointsForTier: 2000,
    ),
    // ── Flux ── (unlocks Medium difficulty) ────────────────────────────────
    LeagueInfo(
      name: 'Flux', romanLevel: 'I',
      color: Color(0xFF14B8A6), bgColor: Color(0xFFCCFBF1),
      icon: Icons.waves_rounded,
      tierIndex: 6, pointsForTier: 3000,
    ),
    LeagueInfo(
      name: 'Flux', romanLevel: 'II',
      color: Color(0xFF14B8A6), bgColor: Color(0xFFCCFBF1),
      icon: Icons.waves_rounded,
      tierIndex: 7, pointsForTier: 4000,
    ),
    LeagueInfo(
      name: 'Flux', romanLevel: 'III',
      color: Color(0xFF14B8A6), bgColor: Color(0xFFCCFBF1),
      icon: Icons.waves_rounded,
      tierIndex: 8, pointsForTier: 5000,
    ),
    // ── Nova ───────────────────────────────────────────────────────────────
    LeagueInfo(
      name: 'Nova', romanLevel: 'I',
      color: Color(0xFF8B5CF6), bgColor: Color(0xFFEDE9FE),
      icon: Icons.auto_awesome_rounded,
      tierIndex: 9, pointsForTier: 6500,
    ),
    LeagueInfo(
      name: 'Nova', romanLevel: 'II',
      color: Color(0xFF8B5CF6), bgColor: Color(0xFFEDE9FE),
      icon: Icons.auto_awesome_rounded,
      tierIndex: 10, pointsForTier: 8000,
    ),
    LeagueInfo(
      name: 'Nova', romanLevel: 'III',
      color: Color(0xFF8B5CF6), bgColor: Color(0xFFEDE9FE),
      icon: Icons.auto_awesome_rounded,
      tierIndex: 11, pointsForTier: 10000,
    ),
    // ── Apex ── (unlocks Hard difficulty) ──────────────────────────────────
    LeagueInfo(
      name: 'Apex', romanLevel: 'I',
      color: Color(0xFFEF4444), bgColor: Color(0xFFFEE2E2),
      icon: Icons.change_history_rounded,
      tierIndex: 12, pointsForTier: 12000,
    ),
    LeagueInfo(
      name: 'Apex', romanLevel: 'II',
      color: Color(0xFFEF4444), bgColor: Color(0xFFFEE2E2),
      icon: Icons.change_history_rounded,
      tierIndex: 13, pointsForTier: 14000,
    ),
    LeagueInfo(
      name: 'Apex', romanLevel: 'III',
      color: Color(0xFFEF4444), bgColor: Color(0xFFFEE2E2),
      icon: Icons.change_history_rounded,
      tierIndex: 14, pointsForTier: 16000,
    ),
    // ── Titan ──────────────────────────────────────────────────────────────
    LeagueInfo(
      name: 'Titan', romanLevel: 'I',
      color: Color(0xFFEAB308), bgColor: Color(0xFFFEFCE8),
      icon: Icons.workspace_premium_rounded,
      tierIndex: 15, pointsForTier: 18500,
    ),
    LeagueInfo(
      name: 'Titan', romanLevel: 'II',
      color: Color(0xFFEAB308), bgColor: Color(0xFFFEFCE8),
      icon: Icons.workspace_premium_rounded,
      tierIndex: 16, pointsForTier: 21000,
    ),
    LeagueInfo(
      name: 'Titan', romanLevel: 'III',
      color: Color(0xFFEAB308), bgColor: Color(0xFFFEFCE8),
      icon: Icons.workspace_premium_rounded,
      tierIndex: 17, pointsForTier: 24000,
    ),
    // ── Nexus ──────────────────────────────────────────────────────────────
    LeagueInfo(
      name: 'Nexus', romanLevel: 'I',
      color: Color(0xFF06B6D4), bgColor: Color(0xFFCFFAFE),
      icon: Icons.diamond_rounded,
      tierIndex: 18, pointsForTier: 27000,
    ),
    LeagueInfo(
      name: 'Nexus', romanLevel: 'II',
      color: Color(0xFF06B6D4), bgColor: Color(0xFFCFFAFE),
      icon: Icons.diamond_rounded,
      tierIndex: 19, pointsForTier: 30000,
    ),
    LeagueInfo(
      name: 'Nexus', romanLevel: 'III',
      color: Color(0xFF06B6D4), bgColor: Color(0xFFCFFAFE),
      icon: Icons.diamond_rounded,
      tierIndex: 20, pointsForTier: 35000,
    ),
  ];

  static List<LeagueInfo> get allTiers => _tiers;
}

/// Used by BrainDifficultySelector to communicate which difficulties
/// are unlocked for the current player.
enum BrainDifficultyUnlock { easy, medium, hard }
