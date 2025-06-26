import 'package:flutter_test/flutter_test.dart';
import 'package:training_app/models/exercise.dart';
import 'package:training_app/models/training_set.dart';

void main() {
  group('Exercise', () {
    test('should create Exercise with valid data', () {
      final sets = [
        TrainingSet(weight: 80, reps: 10),
        TrainingSet(weight: 85, reps: 8),
      ];

      final exercise = Exercise(
        name: 'ベンチプレス',
        sets: sets,
        memo: 'フォーム良好',
      );

      expect(exercise.name, 'ベンチプレス');
      expect(exercise.sets.length, 2);
      expect(exercise.memo, 'フォーム良好');
    });

    test('should serialize to JSON correctly', () {
      final sets = [TrainingSet(weight: 80, reps: 10)];
      final exercise = Exercise(
        name: 'ベンチプレス',
        sets: sets,
        memo: 'フォーム良好',
      );

      final json = exercise.toJson();

      expect(json['name'], 'ベンチプレス');
      expect(json['sets'], isA<List>());
      expect(json['sets'].length, 1);
      expect(json['memo'], 'フォーム良好');
    });

    test('should deserialize from JSON correctly', () {
      final json = {
        'name': 'ベンチプレス',
        'sets': [
          {'weight': 80.0, 'reps': 10},
          {'weight': 85.0, 'reps': 8},
        ],
        'memo': 'フォーム良好',
      };

      final exercise = Exercise.fromJson(json);

      expect(exercise.name, 'ベンチプレス');
      expect(exercise.sets.length, 2);
      expect(exercise.sets.first.weight, 80.0);
      expect(exercise.sets.first.reps, 10);
      expect(exercise.memo, 'フォーム良好');
    });

    test('should handle null memo', () {
      final exercise = Exercise(
        name: 'ベンチプレス',
        sets: [TrainingSet(weight: 80, reps: 10)],
        memo: null,
      );

      expect(exercise.memo, null);

      final json = exercise.toJson();
      expect(json['memo'], null);

      final restoredExercise = Exercise.fromJson(json);
      expect(restoredExercise.memo, null);
    });

    test('should handle empty sets list', () {
      final exercise = Exercise(
        name: 'ベンチプレス',
        sets: [],
        memo: null,
      );

      expect(exercise.sets.length, 0);

      final json = exercise.toJson();
      expect(json['sets'], isA<List>());
      expect(json['sets'].length, 0);
    });
  });
}