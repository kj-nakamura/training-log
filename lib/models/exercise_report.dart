class ExerciseReport {
  final String exerciseName;
  final double maxWeight;
  final DateTime achievedDate;
  final int totalSessions;

  ExerciseReport({
    required this.exerciseName,
    required this.maxWeight,
    required this.achievedDate,
    required this.totalSessions,
  });

  Map<String, dynamic> toJson() {
    return {
      'exerciseName': exerciseName,
      'maxWeight': maxWeight,
      'achievedDate': achievedDate.toIso8601String(),
      'totalSessions': totalSessions,
    };
  }

  factory ExerciseReport.fromJson(Map<String, dynamic> json) {
    return ExerciseReport(
      exerciseName: json['exerciseName'] ?? '',
      maxWeight: json['maxWeight']?.toDouble() ?? 0.0,
      achievedDate: DateTime.parse(json['achievedDate']),
      totalSessions: json['totalSessions']?.toInt() ?? 0,
    );
  }
}