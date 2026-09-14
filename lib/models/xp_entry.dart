// lib/models/xp_entry.dart
// Typed XP history entry — replaces the fragile 'date|points' string format.
// Schema-versioned so future field additions are backward-compatible.

class XpEntry {
  static const int _currentVersion = 1;

  final String weekStartDate; // ISO date of the Monday this week started
  final int points;           // total XP earned in that week

  const XpEntry({required this.weekStartDate, required this.points});

  Map<String, dynamic> toJson() => {
        '_v': _currentVersion,
        'week': weekStartDate,
        'pts': points,
      };

  /// Parses both the legacy 'date|points' string format AND the new JSON map.
  /// Returns null on malformed input — callers skip null entries gracefully.
  static XpEntry? tryParse(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      // New JSON format
      try {
        final week = raw['week'] as String?;
        final pts = raw['pts'] as int?;
        if (week == null || pts == null) return null;
        return XpEntry(weekStartDate: week, points: pts);
      } catch (_) {
        return null;
      }
    }

    if (raw is String) {
      // Legacy 'date|points' format — migrate on read
      final parts = raw.split('|');
      if (parts.length != 2) return null;
      final pts = int.tryParse(parts[1]);
      if (pts == null) return null;
      return XpEntry(weekStartDate: parts[0], points: pts);
    }

    return null;
  }

  @override
  String toString() => 'XpEntry(week: $weekStartDate, pts: $points)';
}
