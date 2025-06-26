import 'package:flutter_test/flutter_test.dart';
import 'package:training_app/models/exercise_report.dart';

void main() {
  group('ExerciseReport', () {
    test('should create ExerciseReport with valid data', () {
      final achievedDate = DateTime(2024, 1, 1);
      final report = ExerciseReport(
        exerciseName: 'ベンチプレス',
        maxWeight: 100.0,
        achievedDate: achievedDate,
        totalSessions: 5,
      );

      expect(report.exerciseName, 'ベンチプレス');
      expect(report.maxWeight, 100.0);
      expect(report.achievedDate, achievedDate);
      expect(report.totalSessions, 5);
    });

    test('should serialize to JSON correctly', () {
      final achievedDate = DateTime(2024, 1, 1);
      final report = ExerciseReport(
        exerciseName: 'ベンチプレス',
        maxWeight: 100.0,
        achievedDate: achievedDate,
        totalSessions: 5,
      );

      final json = report.toJson();

      expect(json['exerciseName'], 'ベンチプレス');
      expect(json['maxWeight'], 100.0);
      expect(json['achievedDate'], achievedDate.toIso8601String());
      expect(json['totalSessions'], 5);
    });

    test('should deserialize from JSON correctly', () {
      final json = {
        'exerciseName': 'ベンチプレス',
        'maxWeight': 100.0,
        'achievedDate': '2024-01-01T00:00:00.000',
        'totalSessions': 5,
      };

      final report = ExerciseReport.fromJson(json);

      expect(report.exerciseName, 'ベンチプレス');
      expect(report.maxWeight, 100.0);
      expect(report.achievedDate.year, 2024);
      expect(report.achievedDate.month, 1);
      expect(report.achievedDate.day, 1);
      expect(report.totalSessions, 5);
    });

    test('should handle zero values', () {
      final achievedDate = DateTime(2024, 1, 1);
      final report = ExerciseReport(
        exerciseName: '',
        maxWeight: 0.0,
        achievedDate: achievedDate,
        totalSessions: 0,
      );

      expect(report.exerciseName, '');
      expect(report.maxWeight, 0.0);
      expect(report.totalSessions, 0);

      final json = report.toJson();
      final restoredReport = ExerciseReport.fromJson(json);

      expect(restoredReport.exerciseName, '');
      expect(restoredReport.maxWeight, 0.0);
      expect(restoredReport.totalSessions, 0);
    });

    test('should handle integer maxWeight as double', () {
      final json = {
        'exerciseName': 'ベンチプレス',
        'maxWeight': 100, // integer
        'achievedDate': '2024-01-01T00:00:00.000',
        'totalSessions': 5,
      };

      final report = ExerciseReport.fromJson(json);

      expect(report.maxWeight, 100.0);
    });
  });
}