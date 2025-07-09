import 'cardio_exercise.dart';
import 'exercise.dart';

class TrainingNote {
  final String id;
  final DateTime date;
  final double? bodyWeight;
  final List<Exercise> exercises;
  final CardioExercise? cardioExercise;

  TrainingNote({
    required this.id,
    required this.date,
    this.bodyWeight,
    required this.exercises,
    this.cardioExercise,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'bodyWeight': bodyWeight,
      'exercises': exercises.map((exercise) => exercise.toJson()).toList(),
      'cardioExercise': cardioExercise?.toJson(),
    };
  }

  factory TrainingNote.fromJson(Map<String, dynamic> json) {
    return TrainingNote(
      id: json['id'] ?? '',
      date: DateTime.parse(json['date']),
      bodyWeight: json['bodyWeight']?.toDouble(),
      exercises: (json['exercises'] as List<dynamic>?)
              ?.map((exerciseJson) => Exercise.fromJson(exerciseJson))
              .toList() ??
          [],
      cardioExercise: json['cardioExercise'] != null
          ? CardioExercise.fromJson(json['cardioExercise'])
          : null,
    );
  }
}
