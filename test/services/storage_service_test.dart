// test/services/storage_service_test.dart
//
// Tests the XpEntry migration logic in StorageService using only pure Dart --
// no SharedPreferences instance needed because XpEntry.tryParse() is the
// actual migration function and can be tested in isolation.

import 'package:flutter_test/flutter_test.dart';
import 'package:g_bytes/models/xp_entry.dart';

/// Simulates what StorageService.getXpHistory() does when it reads the old
/// `List<String>` 'date|points' format from SharedPreferences.
List<XpEntry> _migrateFromLegacyStrings(List<String> raw) {
  return raw
      .map(XpEntry.tryParse)
      .whereType<XpEntry>()
      .toList();
}


void main() {
  group('StorageService XpHistory migration', () {
    test('migrates valid legacy "date|points" strings', () {
      final raw = ['2024-01-08|150', '2024-01-15|300', '2024-01-22|420'];
      final entries = _migrateFromLegacyStrings(raw);

      expect(entries.length, 3);
      expect(entries[0].weekStartDate, '2024-01-08');
      expect(entries[0].points, 150);
      expect(entries[2].points, 420);
    });

    test('skips malformed legacy strings without throwing', () {
      final raw = [
        '2024-01-08|150',
        'corrupt_entry',
        '2024-01-15|not_a_number',
        '',
        '2024-01-22|200',
      ];
      final entries = _migrateFromLegacyStrings(raw);

      expect(entries.length, 2);
      expect(entries[0].points, 150);
      expect(entries[1].points, 200);
    });

    test('handles empty legacy list', () {
      final entries = _migrateFromLegacyStrings([]);
      expect(entries, isEmpty);
    });

    test('XpEntry.toJson produces schema-versioned output', () {
      const entry = XpEntry(weekStartDate: '2024-03-04', points: 360);
      final json = entry.toJson();

      expect(json.containsKey('_v'), isTrue);
      expect(json['_v'], 1);
      expect(json['week'], '2024-03-04');
      expect(json['pts'], 360);
    });

    test('round-trip: toJson -> tryParse preserves data', () {
      const original = XpEntry(weekStartDate: '2024-06-10', points: 180);
      final restored = XpEntry.tryParse(original.toJson());

      expect(restored, isNotNull);
      expect(restored!.weekStartDate, original.weekStartDate);
      expect(restored.points, original.points);
    });

    test('schema is backward compatible — v0 JSON without _v field parses', () {
      // Simulate a JSON map written by a pre-v1 StorageService
      final v0map = {'week': '2024-05-06', 'pts': 420};
      final entry = XpEntry.tryParse(v0map);

      expect(entry, isNotNull);
      expect(entry!.points, 420);
    });
  });
}
