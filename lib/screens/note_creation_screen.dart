import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/training_note.dart';
import '../models/exercise.dart';
import '../models/training_set.dart';
import '../services/storage_service.dart';
import 'note_detail_screen.dart';

class NoteCreationScreen extends StatefulWidget {
  const NoteCreationScreen({Key? key}) : super(key: key);

  @override
  State<NoteCreationScreen> createState() => _NoteCreationScreenState();
}

class _NoteCreationScreenState extends State<NoteCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bodyWeightController = TextEditingController();
  final StorageService _storageService = StorageService();
  
  final DateTime _selectedDate = DateTime.now();
  List<Exercise> _exercises = [];

  @override
  void initState() {
    super.initState();
    // Initialize with 3 empty exercises
    for (int i = 0; i < 3; i++) {
      _exercises.add(Exercise(
        name: '',
        interval: 0,
        sets: [TrainingSet(weight: 0, reps: 0)], // Start with 1 set
        memo: '',
      ));
    }
  }

  @override
  void dispose() {
    _bodyWeightController.dispose();
    super.dispose();
  }

  void _addExercise() {
    setState(() {
      _exercises.add(Exercise(
        name: '',
        interval: 0,
        sets: List.generate(5, (_) => TrainingSet(weight: 0, reps: 0)), // Initialize with 5 empty sets
        memo: '',
      ));
    });
  }

  void _removeExercise(int index) {
    setState(() {
      _exercises.removeAt(index);
    });
  }

  Future<void> _saveNote() async {
    if (_formKey.currentState!.validate()) {
      final note = TrainingNote(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        date: _selectedDate,
        bodyWeight: double.parse(_bodyWeightController.text),
        exercises: _exercises,
      );

      await _storageService.saveNote(note);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ノートが保存されました')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => NoteDetailScreen(note: note),
          ),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📝 トレーニングノート'),
        backgroundColor: const Color(0xFF8B4513),
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      backgroundColor: const Color(0xFFFAF6F0),
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFFAF6F0),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(32.0, 16.0, 24.0, 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Red margin line (like notebook paper)
                      Container(
                        height: 2,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF6B6B),
                          borderRadius: BorderRadius.all(Radius.circular(1)),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(20.0),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                          border: Border.all(
                            color: const Color(0xFFE8E1D9),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.calendar_today, color: Color(0xFF8B4513)),
                                const SizedBox(width: 8),
                                Text(
                                  '日付: ${DateFormat('yyyy/MM/dd').format(_selectedDate)}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontFamily: 'serif',
                                    color: Color(0xFF5D4037),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _bodyWeightController,
                              decoration: InputDecoration(
                                labelText: '体重 (kg)',
                                labelStyle: const TextStyle(
                                  color: Color(0xFF8B4513),
                                  fontFamily: 'serif',
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFD7CCC8),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF8B4513),
                                    width: 2,
                                  ),
                                ),
                                fillColor: Colors.white,
                                filled: true,
                              ),
                              style: const TextStyle(
                                fontFamily: 'serif',
                                color: Color(0xFF5D4037),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return '体重を入力してください';
                                }
                                if (double.tryParse(value) == null) {
                                  return '正しい数値を入力してください';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        child: Row(
                          children: [
                            const Text(
                              '🏋️ 種目',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'serif',
                                color: Color(0xFF5D4037),
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: _addExercise,
                              icon: const Icon(Icons.add_circle),
                              color: const Color(0xFF8B4513),
                              iconSize: 28,
                            ),
                          ],
                        ),
                      ),
                      ..._exercises.asMap().entries.map((entry) {
                        final index = entry.key;
                        return ExerciseCard(
                          exercise: entry.value,
                          onChanged: (exercise) {
                            setState(() {
                              _exercises[index] = exercise;
                            });
                          },
                          onRemove: () => _removeExercise(index),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _saveNote,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B4513),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 4,
                  ),
                  child: const Text(
                    '📖 ノートを保存',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ExerciseCard extends StatefulWidget {
  final Exercise exercise;
  final Function(Exercise) onChanged;
  final VoidCallback onRemove;

  const ExerciseCard({
    Key? key,
    required this.exercise,
    required this.onChanged,
    required this.onRemove,
  }) : super(key: key);

  @override
  State<ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends State<ExerciseCard> {
  late final TextEditingController _nameController;
  late final TextEditingController _intervalController;
  late final TextEditingController _memoController;
  late List<TrainingSet> _sets;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.exercise.name);
    _intervalController = TextEditingController(text: widget.exercise.interval.toString());
    _memoController = TextEditingController(text: widget.exercise.memo ?? '');
    _sets = List.from(widget.exercise.sets);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _intervalController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  void _updateExercise() {
    final exercise = Exercise(
      name: _nameController.text,
      interval: int.tryParse(_intervalController.text) ?? 0,
      sets: _sets,
      memo: _memoController.text.isEmpty ? null : _memoController.text,
    );
    widget.onChanged(exercise);
  }

  void _addSet() {
    if (_sets.length < 5) {
      setState(() {
        _sets.add(TrainingSet(weight: 0, reps: 0));
        _updateExercise();
      });
    }
  }

  void _removeSet(int index) {
    if (_sets.length > 1) {
      setState(() {
        _sets.removeAt(index);
        _updateExercise();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: const Color(0xFFE8E1D9),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: '種目名',
                    labelStyle: const TextStyle(
                      color: Color(0xFF8B4513),
                      fontFamily: 'serif',
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: Color(0xFFD7CCC8),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: Color(0xFF8B4513),
                        width: 2,
                      ),
                    ),
                    fillColor: Colors.white,
                    filled: true,
                  ),
                  style: const TextStyle(
                    fontFamily: 'serif',
                    color: Color(0xFF5D4037),
                  ),
                  onChanged: (_) => _updateExercise(),
                ),
              ),
              IconButton(
                onPressed: widget.onRemove,
                icon: const Icon(Icons.delete),
                color: Colors.red,
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _intervalController,
            decoration: InputDecoration(
              labelText: 'インターバル (秒)',
              labelStyle: const TextStyle(
                color: Color(0xFF8B4513),
                fontFamily: 'serif',
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Color(0xFFD7CCC8),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Color(0xFF8B4513),
                  width: 2,
                ),
              ),
              fillColor: Colors.white,
              filled: true,
            ),
            style: const TextStyle(
              fontFamily: 'serif',
              color: Color(0xFF5D4037),
            ),
            keyboardType: TextInputType.number,
            onChanged: (_) => _updateExercise(),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text(
                'セット',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'serif',
                  color: Color(0xFF5D4037),
                ),
              ),
              const Spacer(),
              if (_sets.length < 5)
                IconButton(
                  onPressed: _addSet,
                  icon: const Icon(Icons.add),
                  color: const Color(0xFF8B4513),
                ),
            ],
          ),
          ..._sets.asMap().entries.map((entry) {
            final index = entry.key;
            final set = entry.value;
            return SetRow(
              setNumber: index + 1,
              set: set,
              onChanged: (newSet) {
                setState(() {
                  _sets[index] = newSet;
                  _updateExercise();
                });
              },
              onRemove: _sets.length > 1 ? () => _removeSet(index) : null,
            );
          }).toList(),
          const SizedBox(height: 16),
          TextFormField(
            controller: _memoController,
            decoration: InputDecoration(
              labelText: 'メモ',
              labelStyle: const TextStyle(
                color: Color(0xFF8B4513),
                fontFamily: 'serif',
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Color(0xFFD7CCC8),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Color(0xFF8B4513),
                  width: 2,
                ),
              ),
              fillColor: Colors.white,
              filled: true,
            ),
            style: const TextStyle(
              fontFamily: 'serif',
              color: Color(0xFF5D4037),
            ),
            maxLines: 2,
            onChanged: (_) => _updateExercise(),
          ),
        ],
      ),
    );
  }
}

class SetRow extends StatelessWidget {
  final int setNumber;
  final TrainingSet set;
  final Function(TrainingSet) onChanged;
  final VoidCallback? onRemove;

  const SetRow({
    Key? key,
    required this.setNumber,
    required this.set,
    required this.onChanged,
    this.onRemove,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              '$setNumber',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'serif',
                color: Color(0xFF5D4037),
              ),
            ),
          ),
          Expanded(
            child: TextFormField(
              initialValue: set.weight.toString(),
              decoration: InputDecoration(
                labelText: 'kg',
                labelStyle: const TextStyle(
                  color: Color(0xFF8B4513),
                  fontFamily: 'serif',
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(
                    color: Color(0xFFD7CCC8),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(
                    color: Color(0xFF8B4513),
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                fillColor: Colors.white,
                filled: true,
              ),
              style: const TextStyle(
                fontFamily: 'serif',
                color: Color(0xFF5D4037),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                final weight = double.tryParse(value) ?? 0;
                onChanged(TrainingSet(weight: weight, reps: set.reps));
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              initialValue: set.reps.toString(),
              decoration: InputDecoration(
                labelText: '回',
                labelStyle: const TextStyle(
                  color: Color(0xFF8B4513),
                  fontFamily: 'serif',
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(
                    color: Color(0xFFD7CCC8),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(
                    color: Color(0xFF8B4513),
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                fillColor: Colors.white,
                filled: true,
              ),
              style: const TextStyle(
                fontFamily: 'serif',
                color: Color(0xFF5D4037),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                final reps = int.tryParse(value) ?? 0;
                onChanged(TrainingSet(weight: set.weight, reps: reps));
              },
            ),
          ),
          if (onRemove != null)
            IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.remove_circle_outline),
              color: Colors.red,
            ),
        ],
      ),
    );
  }
}