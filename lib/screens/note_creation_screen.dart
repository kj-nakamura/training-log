import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/training_note.dart';
import '../models/exercise.dart';
import '../models/training_set.dart';
import '../services/storage_service.dart';

class NoteCreationScreen extends StatefulWidget {
  const NoteCreationScreen({Key? key}) : super(key: key);

  @override
  State<NoteCreationScreen> createState() => _NoteCreationScreenState();
}

class _NoteCreationScreenState extends State<NoteCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bodyWeightController = TextEditingController();
  final StorageService _storageService = StorageService();
  
  DateTime _selectedDate = DateTime.now();
  List<Exercise> _exercises = [];

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
        Navigator.pop(context);
      }
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ノート作成'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.calendar_today),
                                const SizedBox(width: 8),
                                Text(
                                  '日付: ${DateFormat('yyyy/MM/dd').format(_selectedDate)}',
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const Spacer(),
                                TextButton(
                                  onPressed: _selectDate,
                                  child: const Text('変更'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _bodyWeightController,
                              decoration: const InputDecoration(
                                labelText: '体重 (kg)',
                                border: OutlineInputBorder(),
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
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text(
                          '種目',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: _addExercise,
                          icon: const Icon(Icons.add_circle),
                          color: Theme.of(context).primaryColor,
                        ),
                      ],
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
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: _saveNote,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('ノートを保存'),
              ),
            ),
          ],
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
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: '種目名',
                      border: OutlineInputBorder(),
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
              decoration: const InputDecoration(
                labelText: 'インターバル (秒)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (_) => _updateExercise(),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('セット', style: TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                if (_sets.length < 5)
                  IconButton(
                    onPressed: _addSet,
                    icon: const Icon(Icons.add),
                    color: Theme.of(context).primaryColor,
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
              decoration: const InputDecoration(
                labelText: 'メモ',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              onChanged: (_) => _updateExercise(),
            ),
          ],
        ),
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
            child: Text('$setNumber', style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: TextFormField(
              initialValue: set.weight.toString(),
              decoration: const InputDecoration(
                labelText: 'kg',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
              decoration: const InputDecoration(
                labelText: '回',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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