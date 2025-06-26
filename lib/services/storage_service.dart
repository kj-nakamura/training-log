import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/training_note.dart';
import '../models/max_exercise.dart';
import '../models/exercise.dart';

class StorageService {
  static const String _notesKey = 'training_notes';
  static const String _maxExercisesKey = 'max_exercises';

  Future<List<TrainingNote>> loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final notesJson = prefs.getStringList(_notesKey) ?? [];
    
    return notesJson
        .map((noteString) => TrainingNote.fromJson(jsonDecode(noteString)))
        .toList();
  }

  Future<List<TrainingNote>> getNotes() async {
    return await loadNotes();
  }

  Future<List<TrainingNote>> getNotesForDate(DateTime date) async {
    final notes = await loadNotes();
    final targetDate = DateTime(date.year, date.month, date.day);
    
    return notes.where((note) {
      final noteDate = DateTime(note.date.year, note.date.month, note.date.day);
      return noteDate.isAtSameMomentAs(targetDate);
    }).toList();
  }

  Future<TrainingNote?> getNoteForDate(DateTime date) async {
    final notes = await getNotesForDate(date);
    return notes.isNotEmpty ? notes.first : null;
  }

  Future<void> cleanupDuplicateDates() async {
    final notes = await loadNotes();
    final Map<String, List<TrainingNote>> groupedByDate = {};
    
    // Group notes by date
    for (final note in notes) {
      final dateKey = '${note.date.year}-${note.date.month}-${note.date.day}';
      if (groupedByDate[dateKey] == null) {
        groupedByDate[dateKey] = [];
      }
      groupedByDate[dateKey]!.add(note);
    }
    
    // Keep only the latest note for each date
    final List<TrainingNote> cleanedNotes = [];
    for (final dateNotes in groupedByDate.values) {
      if (dateNotes.length > 1) {
        // Sort by creation time (assuming ID contains timestamp)
        dateNotes.sort((a, b) => b.id.compareTo(a.id));
      }
      cleanedNotes.add(dateNotes.first);
    }
    
    // Save cleaned notes
    final prefs = await SharedPreferences.getInstance();
    final notesJson = cleanedNotes
        .map((note) => jsonEncode(note.toJson()))
        .toList();
    
    await prefs.setStringList(_notesKey, notesJson);
  }

  Future<void> saveNote(TrainingNote note) async {
    final prefs = await SharedPreferences.getInstance();
    final notes = await loadNotes();
    
    // Remove any existing notes for the same date (except if it's the same note being updated)
    final noteDate = DateTime(note.date.year, note.date.month, note.date.day);
    notes.removeWhere((existingNote) {
      final existingDate = DateTime(existingNote.date.year, existingNote.date.month, existingNote.date.day);
      return existingDate.isAtSameMomentAs(noteDate) && existingNote.id != note.id;
    });
    
    final existingIndex = notes.indexWhere((n) => n.id == note.id);
    if (existingIndex != -1) {
      notes[existingIndex] = note;
    } else {
      notes.add(note);
    }
    
    final notesJson = notes
        .map((note) => jsonEncode(note.toJson()))
        .toList();
    
    await prefs.setStringList(_notesKey, notesJson);
  }

  Future<void> deleteNote(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final notes = await loadNotes();
    
    notes.removeWhere((note) => note.id == id);
    
    final notesJson = notes
        .map((note) => jsonEncode(note.toJson()))
        .toList();
    
    await prefs.setStringList(_notesKey, notesJson);
  }

  // Max exercise methods
  Future<List<MaxExercise>> loadMaxExercises() async {
    final prefs = await SharedPreferences.getInstance();
    final exercisesJson = prefs.getStringList(_maxExercisesKey) ?? [];
    
    return exercisesJson
        .map((exerciseString) => MaxExercise.fromJson(jsonDecode(exerciseString)))
        .toList();
  }

  Future<List<MaxExercise>> getMaxExercises() async {
    return await loadMaxExercises();
  }

  Future<void> saveMaxExercise(MaxExercise exercise) async {
    final prefs = await SharedPreferences.getInstance();
    final exercises = await loadMaxExercises();
    
    final existingIndex = exercises.indexWhere((e) => e.id == exercise.id);
    if (existingIndex != -1) {
      exercises[existingIndex] = exercise;
    } else {
      exercises.add(exercise);
    }
    
    final exercisesJson = exercises
        .map((exercise) => jsonEncode(exercise.toJson()))
        .toList();
    
    await prefs.setStringList(_maxExercisesKey, exercisesJson);
  }

  Future<void> deleteMaxExercise(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final exercises = await loadMaxExercises();
    
    exercises.removeWhere((exercise) => exercise.id == id);
    
    final exercisesJson = exercises
        .map((exercise) => jsonEncode(exercise.toJson()))
        .toList();
    
    await prefs.setStringList(_maxExercisesKey, exercisesJson);
  }

  Future<List<String>> searchMaxExercises(String query) async {
    final exercises = await loadMaxExercises();
    
    if (query.isEmpty) {
      return exercises.map((e) => e.name).toList();
    }
    
    return exercises
        .where((exercise) => exercise.name.toLowerCase().contains(query.toLowerCase()))
        .map((e) => e.name)
        .toList();
  }

  Future<List<TrainingNote>> getNotesUsingExercise(String exerciseName) async {
    final notes = await loadNotes();
    
    return notes.where((note) {
      return note.exercises.any((exercise) => 
          exercise.name.toLowerCase() == exerciseName.toLowerCase());
    }).toList();
  }

  Future<void> renameExerciseInNotes(String oldName, String newName) async {
    final notes = await loadNotes();
    bool hasChanges = false;
    
    for (final note in notes) {
      for (int i = 0; i < note.exercises.length; i++) {
        if (note.exercises[i].name.toLowerCase() == oldName.toLowerCase()) {
          final exercise = note.exercises[i];
          note.exercises[i] = Exercise(
            name: newName,
            sets: exercise.sets,
            memo: exercise.memo,
          );
          hasChanges = true;
        }
      }
    }
    
    if (hasChanges) {
      final prefs = await SharedPreferences.getInstance();
      final notesJson = notes
          .map((note) => jsonEncode(note.toJson()))
          .toList();
      
      await prefs.setStringList(_notesKey, notesJson);
    }
  }

  Future<void> removeExerciseFromNotes(String exerciseName) async {
    final notes = await loadNotes();
    bool hasChanges = false;
    
    for (final note in notes) {
      final originalLength = note.exercises.length;
      note.exercises.removeWhere((exercise) => 
          exercise.name.toLowerCase() == exerciseName.toLowerCase());
      
      if (note.exercises.length != originalLength) {
        hasChanges = true;
      }
    }
    
    if (hasChanges) {
      final prefs = await SharedPreferences.getInstance();
      final notesJson = notes
          .map((note) => jsonEncode(note.toJson()))
          .toList();
      
      await prefs.setStringList(_notesKey, notesJson);
    }
  }
}