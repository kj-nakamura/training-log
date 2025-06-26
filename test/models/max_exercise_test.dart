import 'package:flutter_test/flutter_test.dart';
import 'package:training_app/models/max_exercise.dart';

void main() {
  group('MaxExercise', () {
    test('should create MaxExercise with valid data', () {
      final createdAt = DateTime(2024, 1, 1);
      final exercise = MaxExercise(
        id: '1',
        name: 'ベンチプレス',
        goalWeight: 100.0,
        createdAt: createdAt,
      );

      expect(exercise.id, '1');
      expect(exercise.name, 'ベンチプレス');
      expect(exercise.goalWeight, 100.0);
      expect(exercise.createdAt, createdAt);
    });

    test('should serialize to JSON correctly', () {
      final createdAt = DateTime(2024, 1, 1);
      final exercise = MaxExercise(
        id: '1',
        name: 'ベンチプレス',
        goalWeight: 100.0,
        createdAt: createdAt,
      );

      final json = exercise.toJson();

      expect(json['id'], '1');
      expect(json['name'], 'ベンチプレス');
      expect(json['goalWeight'], 100.0);
      expect(json['createdAt'], createdAt.toIso8601String());
    });

    test('should deserialize from JSON correctly', () {
      final json = {
        'id': '1',
        'name': 'ベンチプレス',
        'goalWeight': 100.0,
        'createdAt': '2024-01-01T00:00:00.000',
      };

      final exercise = MaxExercise.fromJson(json);

      expect(exercise.id, '1');
      expect(exercise.name, 'ベンチプレス');
      expect(exercise.goalWeight, 100.0);
      expect(exercise.createdAt.year, 2024);
      expect(exercise.createdAt.month, 1);
      expect(exercise.createdAt.day, 1);
    });

    test('should handle empty values with defaults', () {
      final json = {
        'id': '',
        'name': '',
        'goalWeight': 0,
        'createdAt': DateTime.now().toIso8601String(),
      };

      final exercise = MaxExercise.fromJson(json);

      expect(exercise.id, '');
      expect(exercise.name, '');
      expect(exercise.goalWeight, 0.0);
    });

    test('should handle missing fields with defaults', () {
      final json = <String, dynamic>{};

      final exercise = MaxExercise.fromJson(json);

      expect(exercise.id, '');
      expect(exercise.name, '');
      expect(exercise.goalWeight, 0.0);
      expect(exercise.createdAt, isA<DateTime>());
    });

    test('should handle integer goalWeight as double', () {
      final json = {
        'id': '1',
        'name': 'ベンチプレス',
        'goalWeight': 100, // integer
        'createdAt': '2024-01-01T00:00:00.000',
      };

      final exercise = MaxExercise.fromJson(json);

      expect(exercise.goalWeight, 100.0);
    });
  });
}