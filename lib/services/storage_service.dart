// lib/services/storage_service.dart
// Single-access-point for all SharedPreferences reads and writes.
// Centralises key names, handles schema migration (v0 XP history strings -> v1 JSON),
// and exposes typed getters/setters so providers never touch SharedPreferences directly.

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/xp_entry.dart';
import 'app_logger.dart';

class StorageService {
  // ---- Key constants -------------------------------------------------------
  static const _kSchemaVersion  = 'schema_version';
  static const _kTotalPoints    = 'total_points';
  static const _kWeeklyPoints   = 'weekly_points';
  static const _kStreak         = 'user_streak';
  static const _kBestStreak     = 'best_streak';
  static const _kLastStreakDate = 'last_streak_date';
  static const _kWeekStartDate  = 'week_start_date';
  static const _kXpHistoryNew   = 'xp_history_v1';   // new JSON list
  static const _kXpHistoryLeg   = 'xp_history';       // legacy string list
  static const _kTaskDate       = 'task_date';
  static const _kDailyTasksJson = 'daily_tasks_json';
  static const _kUserName       = 'user_name';


  static const int _currentSchema = 1;

  SharedPreferences? _prefs;

  /// Must be called once at app start before any provider touches storage.
  Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      await _runMigrations();
      AppLogger.info('StorageService', 'Initialised (schema v)');
    } catch (e, s) {
      AppLogger.error('StorageService.init', e, s);
    }
  }

  SharedPreferences get _p {
    assert(_prefs != null, 'StorageService.init() must be called before use');
    return _prefs!;
  }

  // ---- Migration -----------------------------------------------------------

  Future<void> _runMigrations() async {
    final version = _p.getInt(_kSchemaVersion) ?? 0;
    if (version >= _currentSchema) return;

    if (version < 1) await _migrateV0toV1();

    await _p.setInt(_kSchemaVersion, _currentSchema);
  }

  /// v0 -> v1: XP history migrated from `List<String>` 'date|points' format
  /// to `List<String>` containing JSON-encoded XpEntry objects.
  Future<void> _migrateV0toV1() async {
    try {
      final legacy = _p.getStringList(_kXpHistoryLeg);
      if (legacy == null || legacy.isEmpty) return;

      final migrated = legacy
          .map(XpEntry.tryParse)
          .whereType<XpEntry>()
          .map((e) => jsonEncode(e.toJson()))
          .toList();

      await _p.setStringList(_kXpHistoryNew, migrated);
      AppLogger.info('StorageService', 'Migrated  XP history entries v0->v1');
    } catch (e, s) {
      AppLogger.error('StorageService._migrateV0toV1', e, s);
    }
  }

  // ---- Typed getters -------------------------------------------------------

  int    getTotalPoints()    => _p.getInt(_kTotalPoints)    ?? 0;
  int    getWeeklyPoints()   => _p.getInt(_kWeeklyPoints)   ?? 0;
  int    getStreak()         => _p.getInt(_kStreak)         ?? 0;
  int    getBestStreak()     => _p.getInt(_kBestStreak)     ?? 0;
  String getLastStreakDate() => _p.getString(_kLastStreakDate) ?? '';
  String getWeekStartDate()  => _p.getString(_kWeekStartDate)  ?? '';
  String getUserName()       => _p.getString(_kUserName)    ?? '';
  String getTaskDate()       => _p.getString(_kTaskDate)    ?? '';
  String? getDailyTasksJson() => _p.getString(_kDailyTasksJson);

  int getHighScore(String gameKey) => _p.getInt(gameKey) ?? 0;

  List<XpEntry> getXpHistory() {
    // Prefer new v1 key; fall back to legacy on first run after migration
    final newList = _p.getStringList(_kXpHistoryNew);
    if (newList != null) {
      return newList
          .map((s) {
            try { return XpEntry.tryParse(jsonDecode(s)); }
            catch (_) { return null; }
          })
          .whereType<XpEntry>()
          .toList();
    }
    // Legacy fallback (should only hit once before migration runs)
    final legacy = _p.getStringList(_kXpHistoryLeg) ?? [];
    return legacy.map(XpEntry.tryParse).whereType<XpEntry>().toList();
  }

  // ---- Typed setters -------------------------------------------------------

  Future<void> setTotalPoints(int v)    async => _save(() => _p.setInt(_kTotalPoints, v));
  Future<void> setWeeklyPoints(int v)   async => _save(() => _p.setInt(_kWeeklyPoints, v));
  Future<void> setStreak(int v)         async => _save(() => _p.setInt(_kStreak, v));
  Future<void> setBestStreak(int v)     async => _save(() => _p.setInt(_kBestStreak, v));
  Future<void> setLastStreakDate(String v) async => _save(() => _p.setString(_kLastStreakDate, v));
  Future<void> setWeekStartDate(String v)  async => _save(() => _p.setString(_kWeekStartDate, v));
  Future<void> setTaskDate(String v)    async => _save(() => _p.setString(_kTaskDate, v));
  Future<void> setDailyTasksJson(String v) async => _save(() => _p.setString(_kDailyTasksJson, v));
  Future<void> setHighScore(String key, int v) async => _save(() => _p.setInt(key, v));

  Future<void> setXpHistory(List<XpEntry> history) async {
    final encoded = history.map((e) => jsonEncode(e.toJson())).toList();
    await _save(() => _p.setStringList(_kXpHistoryNew, encoded));
  }

  Future<void> addXpHistoryEntry(XpEntry entry) async {
    final current = getXpHistory();
    current.insert(0, entry);
    await setXpHistory(current);
  }

  Future<void> clearAll() async {
    try { await _p.clear(); }
    catch (e, s) { AppLogger.error('StorageService.clearAll', e, s); }
  }

  // ---- Internal helper -----------------------------------------------------

  Future<void> _save(Future<bool> Function() write) async {
    try {
      await write();
    } catch (e, s) {
      AppLogger.error('StorageService._save', e, s);
    }
  }
}
