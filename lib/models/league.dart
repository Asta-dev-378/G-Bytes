import 'package:flutter/material.dart';

/// Defines the 7 leagues × 3 sub-levels = 21 tiers.
/// Every tier requires 100 points.
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

  static const List<LeagueInfo> _tiers = [
    // ── Wooden (Step: 100) ───────────────────────────────────────────
    LeagueInfo(
      name: 'Wooden',
      romanLevel: 'I',
      color: Color(0xFF8B5E3C),
      bgColor: Color(0xFFF5E6D8),
      icon: Icons.forest_rounded,
      tierIndex: 0,
      pointsForTier: 0,
    ),
    LeagueInfo(
      name: 'Wooden',
      romanLevel: 'II',
      color: Color(0xFF8B5E3C),
      bgColor: Color(0xFFF5E6D8),
      icon: Icons.forest_rounded,
      tierIndex: 1,
      pointsForTier: 100,
    ),
    LeagueInfo(
      name: 'Wooden',
      romanLevel: 'III',
      color: Color(0xFF8B5E3C),
      bgColor: Color(0xFFF5E6D8),
      icon: Icons.forest_rounded,
      tierIndex: 2,
      pointsForTier: 200,
    ),
    // ── Stone (Step: 200) ─────────────────────────────────────────────
    LeagueInfo(
      name: 'Stone',
      romanLevel: 'I',
      color: Color(0xFF757575),
      bgColor: Color(0xFFEEEEEE),
      icon: Icons.circle_outlined,
      tierIndex: 3,
      pointsForTier: 300,
    ),
    LeagueInfo(
      name: 'Stone',
      romanLevel: 'II',
      color: Color(0xFF757575),
      bgColor: Color(0xFFEEEEEE),
      icon: Icons.circle_outlined,
      tierIndex: 4,
      pointsForTier: 500,
    ),
    LeagueInfo(
      name: 'Stone',
      romanLevel: 'III',
      color: Color(0xFF757575),
      bgColor: Color(0xFFEEEEEE),
      icon: Icons.circle_outlined,
      tierIndex: 5,
      pointsForTier: 700,
    ),
    // ── Iron (Step: 300) ──────────────────────────────────────────────
    LeagueInfo(
      name: 'Iron',
      romanLevel: 'I',
      color: Color(0xFF546E7A),
      bgColor: Color(0xFFECEFF1),
      icon: Icons.shield_outlined,
      tierIndex: 6,
      pointsForTier: 900,
    ),
    LeagueInfo(
      name: 'Iron',
      romanLevel: 'II',
      color: Color(0xFF546E7A),
      bgColor: Color(0xFFECEFF1),
      icon: Icons.shield_outlined,
      tierIndex: 7,
      pointsForTier: 1200,
    ),
    LeagueInfo(
      name: 'Iron',
      romanLevel: 'III',
      color: Color(0xFF546E7A),
      bgColor: Color(0xFFECEFF1),
      icon: Icons.shield_outlined,
      tierIndex: 8,
      pointsForTier: 1500,
    ),
    // ── Bronze (Step: 400) ────────────────────────────────────────────
    LeagueInfo(
      name: 'Bronze',
      romanLevel: 'I',
      color: Color(0xFFCD7F32),
      bgColor: Color(0xFFFFF3E0),
      icon: Icons.military_tech_rounded,
      tierIndex: 9,
      pointsForTier: 1800,
    ),
    LeagueInfo(
      name: 'Bronze',
      romanLevel: 'II',
      color: Color(0xFFCD7F32),
      bgColor: Color(0xFFFFF3E0),
      icon: Icons.military_tech_rounded,
      tierIndex: 10,
      pointsForTier: 2200,
    ),
    LeagueInfo(
      name: 'Bronze',
      romanLevel: 'III',
      color: Color(0xFFCD7F32),
      bgColor: Color(0xFFFFF3E0),
      icon: Icons.military_tech_rounded,
      tierIndex: 11,
      pointsForTier: 2600,
    ),
    // ── Silver (Step: 500) ────────────────────────────────────────────
    LeagueInfo(
      name: 'Silver',
      romanLevel: 'I',
      color: Color(0xFF9E9E9E),
      bgColor: Color(0xFFF5F5F5),
      icon: Icons.workspace_premium_rounded,
      tierIndex: 12,
      pointsForTier: 3000,
    ),
    LeagueInfo(
      name: 'Silver',
      romanLevel: 'II',
      color: Color(0xFF9E9E9E),
      bgColor: Color(0xFFF5F5F5),
      icon: Icons.workspace_premium_rounded,
      tierIndex: 13,
      pointsForTier: 3500,
    ),
    LeagueInfo(
      name: 'Silver',
      romanLevel: 'III',
      color: Color(0xFF9E9E9E),
      bgColor: Color(0xFFF5F5F5),
      icon: Icons.workspace_premium_rounded,
      tierIndex: 14,
      pointsForTier: 4000,
    ),
    // ── Gold (Step: 600) ──────────────────────────────────────────────
    LeagueInfo(
      name: 'Gold',
      romanLevel: 'I',
      color: Color(0xFFFFB300),
      bgColor: Color(0xFFFFFDE7),
      icon: Icons.emoji_events_rounded,
      tierIndex: 15,
      pointsForTier: 4500,
    ),
    LeagueInfo(
      name: 'Gold',
      romanLevel: 'II',
      color: Color(0xFFFFB300),
      bgColor: Color(0xFFFFFDE7),
      icon: Icons.emoji_events_rounded,
      tierIndex: 16,
      pointsForTier: 5100,
    ),
    LeagueInfo(
      name: 'Gold',
      romanLevel: 'III',
      color: Color(0xFFFFB300),
      bgColor: Color(0xFFFFFDE7),
      icon: Icons.emoji_events_rounded,
      tierIndex: 17,
      pointsForTier: 5700,
    ),
    // ── Diamond (Step: 700) ───────────────────────────────────────────
    LeagueInfo(
      name: 'Diamond',
      romanLevel: 'I',
      color: Color(0xFF00BCD4),
      bgColor: Color(0xFFE0F7FA),
      icon: Icons.diamond_rounded,
      tierIndex: 18,
      pointsForTier: 6300,
    ),
    LeagueInfo(
      name: 'Diamond',
      romanLevel: 'II',
      color: Color(0xFF00BCD4),
      bgColor: Color(0xFFE0F7FA),
      icon: Icons.diamond_rounded,
      tierIndex: 19,
      pointsForTier: 7000,
    ),
    LeagueInfo(
      name: 'Diamond',
      romanLevel: 'III',
      color: Color(0xFF00BCD4),
      bgColor: Color(0xFFE0F7FA),
      icon: Icons.diamond_rounded,
      tierIndex: 20,
      pointsForTier: 7700,
    ),
  ];

  static List<LeagueInfo> get allTiers => _tiers;
}
