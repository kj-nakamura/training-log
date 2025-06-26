import 'package:flutter_test/flutter_test.dart';
import 'package:training_app/models/training_set.dart';

void main() {
  group('TrainingSet', () {
    test('should create TrainingSet with valid data', () {
      final set = TrainingSet(weight: 80.5, reps: 10);

      expect(set.weight, 80.5);
      expect(set.reps, 10);
    });

    test('should serialize to JSON correctly', () {
      final set = TrainingSet(weight: 80.5, reps: 10);
      final json = set.toJson();

      expect(json['weight'], 80.5);
      expect(json['reps'], 10);
    });

    test('should deserialize from JSON correctly', () {
      final json = {
        'weight': 80.5,
        'reps': 10,
      };

      final set = TrainingSet.fromJson(json);

      expect(set.weight, 80.5);
      expect(set.reps, 10);
    });

    test('should handle zero values', () {
      final set = TrainingSet(weight: 0, reps: 0);

      expect(set.weight, 0);
      expect(set.reps, 0);

      final json = set.toJson();
      expect(json['weight'], 0);
      expect(json['reps'], 0);

      final restoredSet = TrainingSet.fromJson(json);
      expect(restoredSet.weight, 0);
      expect(restoredSet.reps, 0);
    });

    test('should handle integer weights as doubles', () {
      final json = {
        'weight': 80, // integer
        'reps': 10,
      };

      final set = TrainingSet.fromJson(json);

      expect(set.weight, 80.0);
      expect(set.reps, 10);
    });
  });
}