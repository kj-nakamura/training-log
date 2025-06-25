import 'exercise.dart';

class TrainingNote {
  final String id;
  final DateTime date;
  final double bodyWeight;
  final List<Exercise> exercises;

  TrainingNote({
    required this.id,
    required this.date,
    required this.bodyWeight,
    required this.exercises,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'bodyWeight': bodyWeight,
      'exercises': exercises.map((exercise) => exercise.toJson()).toList(),
    };
  }

  factory TrainingNote.fromJson(Map<String, dynamic> json) {
    return TrainingNote(
      id: json['id'] ?? '',
      date: DateTime.parse(json['date']),
      bodyWeight: json['bodyWeight']?.toDouble() ?? 0.0,
      exercises: (json['exercises'] as List<dynamic>?)
          ?.map((exerciseJson) => Exercise.fromJson(exerciseJson))
          .toList() ?? [],
    );
  }
}