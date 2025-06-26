import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:training_app/models/training_note.dart';
import 'package:training_app/models/exercise.dart';
import 'package:training_app/models/training_set.dart';
import 'package:training_app/models/exercise_report.dart';
import 'package:training_app/services/report_service.dart';
import 'package:training_app/services/storage_service.dart';

void main() {
  group('ReportService', () {
    late ReportService reportService;
    late StorageService storageService;

    setUp(() {
      reportService = ReportService();
      storageService = StorageService();
      SharedPreferences.setMockInitialValues({});
    });

    test('should generate exercise reports from training notes', () async {
      // Setup test data
      final exercise1 = Exercise(
        name: 'ベンチプレス',
        sets: [
          TrainingSet(weight: 80, reps: 10),
          TrainingSet(weight: 85, reps: 8),
        ],
        memo: null,
      );
      final exercise2 = Exercise(
        name: 'ベンチプレス',
        sets: [
          TrainingSet(weight: 90, reps: 6),
          TrainingSet(weight: 85, reps: 8),
        ],
        memo: null,
      );
      final exercise3 = Exercise(
        name: 'スクワット',
        sets: [
          TrainingSet(weight: 100, reps: 10),
        ],
        memo: null,
      );

      final note1 = TrainingNote(
        id: '1',
        date: DateTime(2024, 1, 1),
        bodyWeight: 70.0,
        exercises: [exercise1],
      );
      final note2 = TrainingNote(
        id: '2',
        date: DateTime(2024, 1, 2),
        bodyWeight: 70.0,
        exercises: [exercise2, exercise3],
      );

      await storageService.saveNote(note1);
      await storageService.saveNote(note2);

      // Test report generation
      final reports = await reportService.getExerciseReports();

      expect(reports.length, 2);

      // Check bench press report
      final benchReport = reports.firstWhere((r) => r.exerciseName == 'ベンチプレス');
      expect(benchReport.maxWeight, 90.0);
      expect(benchReport.achievedDate.day, 2);
      expect(benchReport.totalSessions, 2);

      // Check squat report
      final squatReport = reports.firstWhere((r) => r.exerciseName == 'スクワット');
      expect(squatReport.maxWeight, 100.0);
      expect(squatReport.achievedDate.day, 2);
      expect(squatReport.totalSessions, 1);
    });

    test('should handle empty training notes', () async {
      final reports = await reportService.getExerciseReports();
      expect(reports.length, 0);
    });

    test('should handle exercises with zero weight sets', () async {
      final exercise = Exercise(
        name: 'ベンチプレス',
        sets: [
          TrainingSet(weight: 0, reps: 10),
          TrainingSet(weight: 80, reps: 8),
        ],
        memo: null,
      );

      final note = TrainingNote(
        id: '1',
        date: DateTime(2024, 1, 1),
        bodyWeight: 70.0,
        exercises: [exercise],
      );

      await storageService.saveNote(note);
      final reports = await reportService.getExerciseReports();

      expect(reports.length, 1);
      expect(reports.first.maxWeight, 80.0);
      expect(reports.first.totalSessions, 1);
    });

    test('should group exercises by name case-insensitively', () async {
      final exercise1 = Exercise(
        name: 'ベンチプレス',
        sets: [TrainingSet(weight: 80, reps: 10)],
        memo: null,
      );
      final exercise2 = Exercise(
        name: 'ベンチプレス', // Same name
        sets: [TrainingSet(weight: 90, reps: 8)],
        memo: null,
      );

      final note1 = TrainingNote(
        id: '1',
        date: DateTime(2024, 1, 1),
        bodyWeight: 70.0,
        exercises: [exercise1],
      );
      final note2 = TrainingNote(
        id: '2',
        date: DateTime(2024, 1, 2),
        bodyWeight: 70.0,
        exercises: [exercise2],
      );

      await storageService.saveNote(note1);
      await storageService.saveNote(note2);

      final reports = await reportService.getExerciseReports();

      expect(reports.length, 1);
      expect(reports.first.maxWeight, 90.0);
      expect(reports.first.totalSessions, 2);
    });

    test('should track latest achievement date for max weight', () async {
      final exercise1 = Exercise(
        name: 'ベンチプレス',
        sets: [TrainingSet(weight: 90, reps: 8)],
        memo: null,
      );
      final exercise2 = Exercise(
        name: 'ベンチプレス',
        sets: [TrainingSet(weight: 85, reps: 10)], // Lower weight later
        memo: null,
      );

      final note1 = TrainingNote(
        id: '1',
        date: DateTime(2024, 1, 1),
        bodyWeight: 70.0,
        exercises: [exercise1],
      );
      final note2 = TrainingNote(
        id: '2',
        date: DateTime(2024, 1, 5), // Later date
        bodyWeight: 70.0,
        exercises: [exercise2],
      );

      await storageService.saveNote(note1);
      await storageService.saveNote(note2);

      final reports = await reportService.getExerciseReports();

      expect(reports.length, 1);
      expect(reports.first.maxWeight, 90.0);
      expect(reports.first.achievedDate.day, 1); // Should keep the original achievement date
    });
  });
}