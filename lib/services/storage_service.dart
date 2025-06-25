import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/training_note.dart';

class StorageService {
  static const String _notesKey = 'training_notes';

  Future<List<TrainingNote>> loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final notesJson = prefs.getStringList(_notesKey) ?? [];
    
    return notesJson
        .map((noteString) => TrainingNote.fromJson(jsonDecode(noteString)))
        .toList();
  }

  Future<void> saveNote(TrainingNote note) async {
    final prefs = await SharedPreferences.getInstance();
    final notes = await loadNotes();
    
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
}