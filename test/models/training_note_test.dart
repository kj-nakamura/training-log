import 'package:flutter_test/flutter_test.dart';
import 'package:training_app/models/training_note.dart';
import 'package:training_app/models/exercise.dart';
import 'package:training_app/models/training_set.dart';

void main() {
  group('TrainingNote', () {
    test('should create TrainingNote with valid data', () {
      final date = DateTime(2024, 1, 1);
      final exercises = [
        Exercise(
          name: 'ベンチプレス',
          sets: [TrainingSet(weight: 80, reps: 10)],
          memo: null,
        ),
      ];

      final note = TrainingNote(
        id: '1',
        date: date,
        bodyWeight: 70.5,
        exercises: exercises,
      );

      expect(note.id, '1');
      expect(note.date, date);
      expect(note.bodyWeight, 70.5);
      expect(note.exercises.length, 1);
      expect(note.exercises.first.name, 'ベンチプレス');
    });

    test('should serialize to JSON correctly', () {
      final date = DateTime(2024, 1, 1);
      final exercises = [
        Exercise(
          name: 'ベンチプレス',
          sets: [TrainingSet(weight: 80, reps: 10)],
          memo: null,
        ),
      ];

      final note = TrainingNote(
        id: '1',
        date: date,
        bodyWeight: 70.5,
        exercises: exercises,
      );

      final json = note.toJson();

      expect(json['id'], '1');
      expect(json['date'], date.toIso8601String());
      expect(json['bodyWeight'], 70.5);
      expect(json['exercises'], isA<List>());
      expect(json['exercises'].length, 1);
    });

    test('should deserialize from JSON correctly', () {
      final json = {
        'id': '1',
        'date': '2024-01-01T00:00:00.000',
        'bodyWeight': 70.5,
        'exercises': [
          {
            'name': 'ベンチプレス',
            'sets': [
              {'weight': 80.0, 'reps': 10}
            ],
            'memo': null,
          }
        ],
      };

      final note = TrainingNote.fromJson(json);

      expect(note.id, '1');
      expect(note.date.year, 2024);
      expect(note.bodyWeight, 70.5);
      expect(note.exercises.length, 1);
      expect(note.exercises.first.name, 'ベンチプレス');
    });

    test('should handle null bodyWeight', () {
      final date = DateTime(2024, 1, 1);
      final note = TrainingNote(
        id: '1',
        date: date,
        bodyWeight: null,
        exercises: [],
      );

      expect(note.bodyWeight, null);

      final json = note.toJson();
      expect(json['bodyWeight'], null);

      final restoredNote = TrainingNote.fromJson(json);
      expect(restoredNote.bodyWeight, null);
    });
  });
}