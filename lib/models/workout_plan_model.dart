import 'dart:convert';

class WorkoutItem {
  final String name;
  final int sets;
  final int workSeconds;
  final int restSeconds;

  const WorkoutItem({
    required this.name,
    required this.sets,
    required this.workSeconds,
    required this.restSeconds,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'sets': sets,
        'workSeconds': workSeconds,
        'restSeconds': restSeconds,
      };

  factory WorkoutItem.fromJson(Map<String, dynamic> json) => WorkoutItem(
        name: json['name'] as String,
        sets: json['sets'] as int,
        workSeconds: json['workSeconds'] as int,
        restSeconds: json['restSeconds'] as int,
      );

  String get workLabel {
    if (workSeconds >= 60) {
      final m = workSeconds ~/ 60;
      final s = workSeconds % 60;
      return s == 0 ? '${m}m' : '${m}m ${s}s';
    }
    return '${workSeconds}s';
  }

  String get restLabel {
    if (restSeconds == 0) return 'No rest';
    if (restSeconds >= 60) {
      final m = restSeconds ~/ 60;
      final s = restSeconds % 60;
      return s == 0 ? '${m}m' : '${m}m ${s}s';
    }
    return '${restSeconds}s';
  }

  int get totalSeconds => (workSeconds + restSeconds) * sets;
}

class WorkoutPlan {
  final String id;
  final String name;
  final List<WorkoutItem> items;

  const WorkoutPlan({
    required this.id,
    required this.name,
    required this.items,
  });

  /// Serialise for SharedPreferences.
  String encode() {
    final map = {
      'id': id,
      'name': name,
      'items': items.map((i) => i.toJson()).toList(),
    };
    return jsonEncode(map);
  }

  /// Decode from SharedPreferences. Falls back to old format gracefully.
  static WorkoutPlan? decode(String raw) {
    try {
      if (raw.startsWith('{')) {
        final map = jsonDecode(raw);
        return WorkoutPlan(
          id: map['id'],
          name: map['name'],
          items: (map['items'] as List)
              .map((e) => WorkoutItem.fromJson(e as Map<String, dynamic>))
              .toList(),
        );
      } else {
        // Legacy pipe-delimited format
        final parts = raw.split('|');
        if (parts.length < 5) return null;
        return WorkoutPlan(
          id: parts[0],
          name: parts[1],
          items: [
            WorkoutItem(
              name: 'Workout', // default name
              sets: int.parse(parts[2]),
              workSeconds: int.parse(parts[3]),
              restSeconds: int.parse(parts[4]),
            )
          ],
        );
      }
    } catch (_) {
      return null;
    }
  }

  int get totalSeconds => items.fold(0, (sum, item) => sum + item.totalSeconds);
}
