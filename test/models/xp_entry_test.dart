// test/models/xp_entry_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:g_bytes/models/xp_entry.dart';

void main() {
  group('XpEntry.tryParse', () {
    // ── Legacy string format ────────────────────────────────────────────────
    test('parses valid legacy "date|points" string', () {
      final entry = XpEntry.tryParse('2024-01-08|150');
      expect(entry, isNotNull);
      expect(entry!.weekStartDate, '2024-01-08');
      expect(entry.points, 150);
    });

    test('returns null for legacy string with wrong separator count', () {
      expect(XpEntry.tryParse('2024-01-08'), isNull);
      expect(XpEntry.tryParse('2024-01-08|50|extra'), isNull);
    });

    test('returns null for legacy string with non-integer points', () {
      expect(XpEntry.tryParse('2024-01-08|abc'), isNull);
    });

    test('returns null for empty string', () {
      expect(XpEntry.tryParse(''), isNull);
    });

    // ── New JSON map format ─────────────────────────────────────────────────
    test('parses valid JSON map', () {
      final entry = XpEntry.tryParse({'_v': 1, 'week': '2024-01-15', 'pts': 300});
      expect(entry, isNotNull);
      expect(entry!.weekStartDate, '2024-01-15');
      expect(entry.points, 300);
    });

    test('parses JSON map without _v field (v0 data)', () {
      final entry = XpEntry.tryParse({'week': '2024-01-15', 'pts': 200});
      expect(entry, isNotNull);
      expect(entry!.points, 200);
    });

    test('returns null for JSON map missing week field', () {
      expect(XpEntry.tryParse({'pts': 100}), isNull);
    });

    test('returns null for JSON map missing pts field', () {
      expect(XpEntry.tryParse({'week': '2024-01-15'}), isNull);
    });

    test('returns null for null input', () {
      expect(XpEntry.tryParse(null), isNull);
    });

    test('returns null for integer input', () {
      expect(XpEntry.tryParse(42), isNull);
    });

    // ── toJson round-trip ───────────────────────────────────────────────────
    test('toJson produces expected keys', () {
      const entry = XpEntry(weekStartDate: '2024-02-05', points: 420);
      final json = entry.toJson();
      expect(json['_v'], 1);
      expect(json['week'], '2024-02-05');
      expect(json['pts'], 420);
    });

    test('toJson then tryParse round-trips correctly', () {
      const original = XpEntry(weekStartDate: '2024-03-04', points: 180);
      final roundTripped = XpEntry.tryParse(original.toJson());
      expect(roundTripped, isNotNull);
      expect(roundTripped!.weekStartDate, original.weekStartDate);
      expect(roundTripped.points, original.points);
    });
  });
}
