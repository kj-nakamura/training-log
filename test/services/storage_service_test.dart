import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:training_app/models/training_note.dart';
import 'package:training_app/models/exercise.dart';
import 'package:training_app/models/training_set.dart';
import 'package:training_app/models/max_exercise.dart';
import 'package:training_app/services/storage_service.dart';

void main() {
  group('StorageService', () {
    late StorageService storageService;

    setUp(() {
      storageService = StorageService();
      SharedPreferences.setMockInitialValues({});
    });

    group('TrainingNote operations', () {
      test('should save and load training note', () async {
        final date = DateTime(2024, 1, 1);
        final exercise = Exercise(
          name: 'ベンチプレス',
          sets: [TrainingSet(weight: 80, reps: 10)],
          memo: null,
        );
        final note = TrainingNote(
          id: '1',
          date: date,
          bodyWeight: 70.5,
          exercises: [exercise],
        );

        await storageService.saveNote(note);
        final loadedNotes = await storageService.loadNotes();

        expect(loadedNotes.length, 1);
        expect(loadedNotes.first.id, '1');
        expect(loadedNotes.first.bodyWeight, 70.5);
        expect(loadedNotes.first.exercises.length, 1);
      });

      test('should get note for specific date', () async {
        final date = DateTime(2024, 1, 1);
        final note = TrainingNote(
          id: '1',
          date: date,
          bodyWeight: 70.5,
          exercises: [],
        );

        await storageService.saveNote(note);
        final retrievedNote = await storageService.getNoteForDate(date);

        expect(retrievedNote, isNotNull);
        expect(retrievedNote!.id, '1');
        expect(retrievedNote.bodyWeight, 70.5);
      });

      test('should return null for date with no note', () async {
        final date = DateTime(2024, 1, 1);
        final retrievedNote = await storageService.getNoteForDate(date);

        expect(retrievedNote, isNull);
      });

      test('should delete note by id', () async {
        final note = TrainingNote(
          id: '1',
          date: DateTime(2024, 1, 1),
          bodyWeight: 70.5,
          exercises: [],
        );

        await storageService.saveNote(note);
        await storageService.deleteNote('1');
        final notes = await storageService.loadNotes();

        expect(notes.length, 0);
      });

      test('should replace note with same date', () async {
        final date = DateTime(2024, 1, 1);
        final note1 = TrainingNote(
          id: '1',
          date: date,
          bodyWeight: 70.0,
          exercises: [],
        );
        final note2 = TrainingNote(
          id: '2',
          date: date,
          bodyWeight: 75.0,
          exercises: [],
        );

        await storageService.saveNote(note1);
        await storageService.saveNote(note2);
        final notes = await storageService.loadNotes();

        expect(notes.length, 1);
        expect(notes.first.id, '2');
        expect(notes.first.bodyWeight, 75.0);
      });
    });

    group('MaxExercise operations', () {
      test('should save and load max exercise', () async {
        final exercise = MaxExercise(
          id: '1',
          name: 'ベンチプレス',
          goalWeight: 100.0,
          createdAt: DateTime(2024, 1, 1),
        );

        await storageService.saveMaxExercise(exercise);
        final exercises = await storageService.getMaxExercises();

        expect(exercises.length, 1);
        expect(exercises.first.id, '1');
        expect(exercises.first.name, 'ベンチプレス');
        expect(exercises.first.goalWeight, 100.0);
      });

      test('should update existing max exercise', () async {
        final exercise1 = MaxExercise(
          id: '1',
          name: 'ベンチプレス',
          goalWeight: 100.0,
          createdAt: DateTime(2024, 1, 1),
        );
        final exercise2 = MaxExercise(
          id: '1',
          name: 'ベンチプレス',
          goalWeight: 120.0,
          createdAt: DateTime(2024, 1, 1),
        );

        await storageService.saveMaxExercise(exercise1);
        await storageService.saveMaxExercise(exercise2);
        final exercises = await storageService.getMaxExercises();

        expect(exercises.length, 1);
        expect(exercises.first.goalWeight, 120.0);
      });

      test('should delete max exercise', () async {
        final exercise = MaxExercise(
          id: '1',
          name: 'ベンチプレス',
          goalWeight: 100.0,
          createdAt: DateTime(2024, 1, 1),
        );

        await storageService.saveMaxExercise(exercise);
        await storageService.deleteMaxExercise('1');
        final exercises = await storageService.getMaxExercises();

        expect(exercises.length, 0);
      });

      test('should search max exercises', () async {
        final exercise1 = MaxExercise(
          id: '1',
          name: 'ベンチプレス',
          goalWeight: 100.0,
          createdAt: DateTime(2024, 1, 1),
        );
        final exercise2 = MaxExercise(
          id: '2',
          name: 'スクワット',
          goalWeight: 120.0,
          createdAt: DateTime(2024, 1, 1),
        );

        await storageService.saveMaxExercise(exercise1);
        await storageService.saveMaxExercise(exercise2);

        final results = await storageService.searchMaxExercises('ベンチ');
        expect(results.length, 1);
        expect(results.first, 'ベンチプレス');

        final allResults = await storageService.searchMaxExercises('');
        expect(allResults.length, 2);
      });
    });

    group('Exercise management in notes', () {
      test('should find notes using specific exercise', () async {
        final exercise1 = Exercise(
          name: 'ベンチプレス',
          sets: [TrainingSet(weight: 80, reps: 10)],
          memo: null,
        );
        final exercise2 = Exercise(
          name: 'スクワット',
          sets: [TrainingSet(weight: 100, reps: 8)],
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

        final notesWithBench = await storageService.getNotesUsingExercise('ベンチプレス');
        expect(notesWithBench.length, 1);
        expect(notesWithBench.first.id, '1');

        final notesWithSquat = await storageService.getNotesUsingExercise('スクワット');
        expect(notesWithSquat.length, 1);
        expect(notesWithSquat.first.id, '2');
      });

      test('should rename exercise in notes', () async {
        final exercise = Exercise(
          name: 'ベンチプレス',
          sets: [TrainingSet(weight: 80, reps: 10)],
          memo: null,
        );
        final note = TrainingNote(
          id: '1',
          date: DateTime(2024, 1, 1),
          bodyWeight: 70.0,
          exercises: [exercise],
        );

        await storageService.saveNote(note);
        await storageService.renameExerciseInNotes('ベンチプレス', 'インクラインベンチプレス');

        final notes = await storageService.loadNotes();
        expect(notes.first.exercises.first.name, 'インクラインベンチプレス');
      });

      test('should remove exercise from notes', () async {
        final exercise1 = Exercise(
          name: 'ベンチプレス',
          sets: [TrainingSet(weight: 80, reps: 10)],
          memo: null,
        );
        final exercise2 = Exercise(
          name: 'スクワット',
          sets: [TrainingSet(weight: 100, reps: 8)],
          memo: null,
        );
        final note = TrainingNote(
          id: '1',
          date: DateTime(2024, 1, 1),
          bodyWeight: 70.0,
          exercises: [exercise1, exercise2],
        );

        await storageService.saveNote(note);
        await storageService.removeExerciseFromNotes('ベンチプレス');

        final notes = await storageService.loadNotes();
        expect(notes.first.exercises.length, 1);
        expect(notes.first.exercises.first.name, 'スクワット');
      });
    });
  });
}