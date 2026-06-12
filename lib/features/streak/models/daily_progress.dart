class DailyProgress {
  /// Date format: YYYY-MM-DD
  final String date;
  
  /// Total points earned on this day
  final int pointsEarned;
  
  /// Whether the user reached the >= 100 points goal for the day
  final bool isCompleted;

  DailyProgress({
    required this.date,
    required this.pointsEarned,
    this.isCompleted = false,
  });

  /// Converting to JSON for saving into SharedPreferences
  Map<String, dynamic> toJson() => {
        'date': date,
        'pointsEarned': pointsEarned,
        'isCompleted': isCompleted,
      };

  /// Building from JSON when loading from SharedPreferences
  factory DailyProgress.fromJson(Map<String, dynamic> json) => DailyProgress(
        date: json['date'] as String,
        pointsEarned: json['pointsEarned'] as int,
        isCompleted: json['isCompleted'] as bool,
      );
}
