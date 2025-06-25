import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/training_note.dart';
import '../models/exercise.dart';
import '../models/training_set.dart';
import '../services/storage_service.dart';
import '../widgets/progress_chart.dart';
import 'calendar_screen.dart';

class NoteCreationScreen extends StatefulWidget {
  final TrainingNote? existingNote;
  final DateTime? selectedDate;
  
  const NoteCreationScreen({Key? key, this.existingNote, this.selectedDate}) : super(key: key);

  @override
  State<NoteCreationScreen> createState() => _NoteCreationScreenState();
}

class _NoteCreationScreenState extends State<NoteCreationScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _bodyWeightController = TextEditingController();
  final StorageService _storageService = StorageService();
  
  late DateTime _selectedDate;
  List<Exercise> _exercises = [];
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  bool _isEditMode = true;
  bool _isEditingBodyWeight = false;
  Set<int> _editingExerciseIndices = {};
  bool _isInitialLoad = true;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.selectedDate ?? DateTime.now();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward();
    _loadSelectedDateNote();
  }

  Future<void> _loadSelectedDateNote() async {
    final existingNote = _isInitialLoad && widget.existingNote != null 
        ? widget.existingNote 
        : await _storageService.getNoteForDate(_selectedDate);
    
    _isInitialLoad = false;
    
    if (existingNote != null) {
      // Load existing note data
      _bodyWeightController.text = existingNote.bodyWeight == 0 ? '' : existingNote.bodyWeight.toString();
      _exercises = List.from(existingNote.exercises);
      _isEditMode = false; // Show in display mode for existing notes
    } else {
      // Initialize with 1 empty exercise and clear body weight
      _bodyWeightController.clear();
      _exercises.clear();
      _exercises.add(Exercise(
        name: '',
        sets: [TrainingSet(weight: 0, reps: 0)], // Start with 1 set
        memo: '',
      ));
      _isEditMode = true; // Start in edit mode for new notes
    }
    // Clear editing states
    _isEditingBodyWeight = false;
    _editingExerciseIndices.clear();
    setState(() {});
  }

  Future<void> _switchToDate(DateTime newDate, bool isSwipeRight) async {
    // Start slide out animation
    await _animationController.reverse();
    
    setState(() {
      _selectedDate = newDate;
    });
    await _loadSelectedDateNote();
    
    // Start slide in animation
    _animationController.forward();
    
    // Show brief feedback
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${DateFormat('yyyy/MM/dd').format(_selectedDate)}のノートに切り替えました'),
          duration: const Duration(milliseconds: 1500),
          backgroundColor: const Color(0xFF8B4513),
        ),
      );
    }
  }

  @override
  void dispose() {
    _bodyWeightController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _addExercise() {
    // Check exercise limit (maximum 5 exercises)
    if (_exercises.length >= 5) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('種目は最大5つまで追加できます')),
        );
      }
      return;
    }

    setState(() {
      _exercises.add(Exercise(
        name: '',
        sets: [TrainingSet(weight: 0, reps: 0)], // Initialize with 1 empty set
        memo: '',
      ));
    });
  }

  Future<void> _saveNote() async {
    if (_formKey.currentState!.validate()) {
      final existingNote = await _storageService.getNoteForDate(_selectedDate);
      
      // 選択した日付に現在の時刻を適用
      final now = DateTime.now();
      final dateWithCurrentTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        now.hour,
        now.minute,
        now.second,
      );
      
      final note = TrainingNote(
        id: existingNote?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        date: dateWithCurrentTime,
        bodyWeight: double.parse(_bodyWeightController.text),
        exercises: _exercises,
      );

      await _storageService.saveNote(note);

      if (mounted) {
        setState(() {
          _isEditMode = false; // Switch to display mode after saving
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(existingNote != null ? 'ノートが更新されました' : 'ノートが保存されました')),
        );
      }
    }
  }

  void _toggleBodyWeightEdit() {
    setState(() {
      _isEditingBodyWeight = !_isEditingBodyWeight;
    });
  }

  void _toggleExerciseEdit(int index) {
    setState(() {
      if (_editingExerciseIndices.contains(index)) {
        _editingExerciseIndices.remove(index);
      } else {
        _editingExerciseIndices.add(index);
      }
    });
  }

  Future<void> _saveBodyWeight() async {
    if (_bodyWeightController.text.isNotEmpty) {
      final weight = double.tryParse(_bodyWeightController.text);
      if (weight != null && weight > 0) {
        // Get existing note and update only body weight
        final existingNote = await _storageService.getNoteForDate(_selectedDate);
        if (existingNote != null) {
          final updatedNote = TrainingNote(
            id: existingNote.id,
            date: existingNote.date,
            bodyWeight: weight,
            exercises: existingNote.exercises,
          );
          await _storageService.saveNote(updatedNote);
        }
        setState(() {
          _isEditingBodyWeight = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('体重が更新されました')),
          );
        }
      }
    }
  }

  Future<void> _saveExercise(int index) async {
    final existingNote = await _storageService.getNoteForDate(_selectedDate);
    if (existingNote != null) {
      final updatedNote = TrainingNote(
        id: existingNote.id,
        date: existingNote.date,
        bodyWeight: existingNote.bodyWeight,
        exercises: _exercises,
      );
      await _storageService.saveNote(updatedNote);
      setState(() {
        _editingExerciseIndices.remove(index);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('種目が更新されました')),
        );
      }
    }
  }

  Future<void> _addExerciseInDisplayMode() async {
    // Check exercise limit (maximum 5 exercises)
    if (_exercises.length >= 5) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('種目は最大5つまで追加できます')),
        );
      }
      return;
    }

    // Add new empty exercise
    final newExercise = Exercise(
      name: '',
      sets: [TrainingSet(weight: 0, reps: 0)],
      memo: '',
    );
    
    setState(() {
      _exercises.add(newExercise);
      _editingExerciseIndices.add(_exercises.length - 1); // Put new exercise in edit mode
    });

    // Save to database
    final existingNote = await _storageService.getNoteForDate(_selectedDate);
    if (existingNote != null) {
      final updatedNote = TrainingNote(
        id: existingNote.id,
        date: existingNote.date,
        bodyWeight: existingNote.bodyWeight,
        exercises: _exercises,
      );
      await _storageService.saveNote(updatedNote);
    } else {
      // Create new note if none exists
      final now = DateTime.now();
      final dateWithCurrentTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        now.hour,
        now.minute,
        now.second,
      );
      
      final newNote = TrainingNote(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        date: dateWithCurrentTime,
        bodyWeight: double.tryParse(_bodyWeightController.text) ?? 0.0,
        exercises: _exercises,
      );
      await _storageService.saveNote(newNote);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('新しい種目が追加されました')),
      );
    }
  }

  Future<void> _deleteExerciseWithConfirmation(int index) async {
    final exercise = _exercises[index];
    final exerciseName = exercise.name.isNotEmpty ? exercise.name : '新しい種目';
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          '種目を削除',
          style: TextStyle(
            fontFamily: 'serif',
            color: Color(0xFF5D4037),
          ),
        ),
        content: Text(
          '「$exerciseName」を削除しますか？\n\nこの操作は取り消せません。',
          style: const TextStyle(
            fontFamily: 'serif',
            color: Color(0xFF5D4037),
          ),
        ),
        backgroundColor: const Color(0xFFFAF6F0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(
            color: Color(0xFFE8E1D9),
            width: 1,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'キャンセル',
              style: TextStyle(
                color: Color(0xFF8B4513),
                fontFamily: 'serif',
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text(
              '削除',
              style: TextStyle(
                fontFamily: 'serif',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteExercise(index);
    }
  }

  Future<void> _deleteExercise(int index) async {
    setState(() {
      _exercises.removeAt(index);
      _editingExerciseIndices.remove(index);
      // Adjust indices for remaining exercises
      final newEditingIndices = <int>{};
      for (final editingIndex in _editingExerciseIndices) {
        if (editingIndex > index) {
          newEditingIndices.add(editingIndex - 1);
        } else {
          newEditingIndices.add(editingIndex);
        }
      }
      _editingExerciseIndices = newEditingIndices;
    });

    // Save to database
    final existingNote = await _storageService.getNoteForDate(_selectedDate);
    if (existingNote != null) {
      final updatedNote = TrainingNote(
        id: existingNote.id,
        date: existingNote.date,
        bodyWeight: existingNote.bodyWeight,
        exercises: _exercises,
      );
      await _storageService.saveNote(updatedNote);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('種目が削除されました')),
      );
    }
  }

  void _showProgressChart() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('体重グラフ'),
        content: const SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ProgressChart(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📝 トレーニングノート'),
        backgroundColor: const Color(0xFF8B4513),
        foregroundColor: Colors.white,
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.bar_chart),
          onPressed: _showProgressChart,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CalendarScreen(),
                ),
              );
            },
          ),
        ],
      ),
      backgroundColor: const Color(0xFFFAF6F0),
      body: GestureDetector(
        onPanUpdate: (details) {
          // Detect horizontal swipe direction
        },
        onPanEnd: (details) {
          // Handle swipe completion
          if (details.velocity.pixelsPerSecond.dx > 500) {
            // Right swipe - go to previous day
            final previousDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day - 1);
            _switchToDate(previousDay, true);
          } else if (details.velocity.pixelsPerSecond.dx < -500) {
            // Left swipe - go to next day
            final nextDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day + 1);
            _switchToDate(nextDay, false);
          }
        },
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFFFAF6F0),
          ),
          child: AnimatedBuilder(
            animation: _slideAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(
                  (1.0 - _slideAnimation.value) * MediaQuery.of(context).size.width * 0.3,
                  0.0,
                ),
                child: Transform.scale(
                  scale: 0.8 + (_slideAnimation.value * 0.2),
                  child: Opacity(
                    opacity: _slideAnimation.value,
                    child: _isEditMode ? _buildEditMode() : _buildDisplayMode(),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEditMode() {
    return Form(
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
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return '体重を入力してください';
                                }
                                final weight = double.tryParse(value);
                                if (weight == null) {
                                  return '正しい数値を入力してください';
                                }
                                if (weight <= 0) {
                                  return '正しい体重を入力してください';
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
                            if (_exercises.length < 5)
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
                          key: ValueKey('edit_${_selectedDate.toIso8601String()}_$index'),
                          exercise: entry.value,
                          onChanged: (exercise) {
                            setState(() {
                              _exercises[index] = exercise;
                            });
                          },
                        );
                      }).toList(),
                    ],
                  ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(16.0),
                            decoration: const BoxDecoration(
                              color: Color(0xFFFAF6F0),
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
                                elevation: 2,
                              ),
                              child: const Text(
                                '保存',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
        ],
      ),
    );
  }

  Widget _buildDisplayMode() {
    return SingleChildScrollView(
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
          // Date and body weight display
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Color(0xFF8B4513)),
                    const SizedBox(width: 8),
                    Text(
                      '${DateFormat('yyyy年MM月dd日').format(_selectedDate)}のトレーニング',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'serif',
                        color: Color(0xFF5D4037),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.monitor_weight, color: Color(0xFF8B4513)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _isEditingBodyWeight
                          ? Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _bodyWeightController,
                                    decoration: InputDecoration(
                                      labelText: '体重 (kg)',
                                      labelStyle: const TextStyle(
                                        color: Color(0xFF8B4513),
                                        fontFamily: 'serif',
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 8,
                                      ),
                                    ),
                                    style: const TextStyle(
                                      fontFamily: 'serif',
                                      color: Color(0xFF5D4037),
                                    ),
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.check, color: Colors.green),
                                  onPressed: _saveBodyWeight,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, color: Colors.red),
                                  onPressed: _toggleBodyWeightEdit,
                                ),
                              ],
                            )
                          : Text(
                              '体重: ${_bodyWeightController.text.isNotEmpty ? _bodyWeightController.text : "記録なし"}kg',
                              style: const TextStyle(
                                fontSize: 16,
                                fontFamily: 'serif',
                                color: Color(0xFF5D4037),
                              ),
                            ),
                    ),
                    if (!_isEditingBodyWeight)
                      IconButton(
                        icon: const Icon(Icons.edit, size: 18),
                        color: const Color(0xFF8B4513),
                        onPressed: _toggleBodyWeightEdit,
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Exercise display
          const Text(
            '🏋️ トレーニング内容',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'serif',
              color: Color(0xFF5D4037),
            ),
          ),
          const SizedBox(height: 16),
          ..._exercises.asMap().entries.where((entry) => entry.value.name.isNotEmpty || _editingExerciseIndices.contains(entry.key)).map((exerciseEntry) {
            final exerciseIndex = exerciseEntry.key;
            final exercise = exerciseEntry.value;
            final isEditing = _editingExerciseIndices.contains(exerciseIndex);
            
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          exercise.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'serif',
                            color: Color(0xFF5D4037),
                          ),
                        ),
                      ),
                      if (!isEditing)
                        IconButton(
                          icon: const Icon(Icons.edit, size: 18),
                          color: const Color(0xFF8B4513),
                          onPressed: () => _toggleExerciseEdit(exerciseIndex),
                        ),
                      if (isEditing) ...[
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18),
                          color: Colors.red.withOpacity(0.7),
                          onPressed: () => _deleteExerciseWithConfirmation(exerciseIndex),
                          tooltip: '種目を削除',
                        ),
                        IconButton(
                          icon: const Icon(Icons.check, color: Colors.green),
                          onPressed: () => _saveExercise(exerciseIndex),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () => _toggleExerciseEdit(exerciseIndex),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (isEditing)
                    ExerciseCard(
                      key: ValueKey('display_${_selectedDate.toIso8601String()}_$exerciseIndex'),
                      exercise: exercise,
                      onChanged: (updatedExercise) {
                        setState(() {
                          _exercises[exerciseIndex] = updatedExercise;
                        });
                      },
                    )
                  else ...[
                    ...exercise.sets.asMap().entries.map((entry) {
                      final index = entry.key;
                      final set = entry.value;
                      if (set.weight == 0 && set.reps == 0) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          '${index + 1}セット目: ${set.weight}kg × ${set.reps}回',
                          style: const TextStyle(
                            fontSize: 14,
                            fontFamily: 'serif',
                            color: Color(0xFF8B4513),
                          ),
                        ),
                      );
                    }).toList(),
                    if (exercise.memo != null && exercise.memo!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF8E1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: const Color(0xFFFFCC02),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'メモ: ${exercise.memo}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontFamily: 'serif',
                            color: Color(0xFF5D4037),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            );
          }).toList(),
          // Add exercise button (show when less than 5 exercises)
          if (_exercises.length < 5)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: OutlinedButton.icon(
                onPressed: _addExerciseInDisplayMode,
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('種目を追加'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(
                    color: Color(0xFF8B4513),
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                  foregroundColor: const Color(0xFF8B4513),
                  backgroundColor: Colors.white.withOpacity(0.8),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  textStyle: const TextStyle(
                    fontFamily: 'serif',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          if (_exercises.where((exercise) => exercise.name.isNotEmpty).toList().isEmpty && _editingExerciseIndices.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              child: const Text(
                'トレーニング内容が記録されていません',
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'serif',
                  color: Color(0xFF999999),
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}

class ExerciseCard extends StatefulWidget {
  final Exercise exercise;
  final Function(Exercise) onChanged;

  const ExerciseCard({
    Key? key,
    required this.exercise,
    required this.onChanged,
  }) : super(key: key);

  @override
  State<ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends State<ExerciseCard> {
  late final TextEditingController _nameController;
  late final TextEditingController _memoController;
  late List<TrainingSet> _sets;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.exercise.name);
    _memoController = TextEditingController(text: widget.exercise.memo ?? '');
    _sets = List.from(widget.exercise.sets);
  }

  @override
  void didUpdateWidget(ExerciseCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update controllers when exercise data changes (e.g., when swiping dates)
    // Always update to ensure data consistency when parent updates
    _nameController.text = widget.exercise.name;
    _memoController.text = widget.exercise.memo ?? '';
    _sets = List.from(widget.exercise.sets);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  void _updateExercise() {
    final exercise = Exercise(
      name: _nameController.text,
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
          TextFormField(
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
              initialValue: set.weight == 0 ? '' : set.weight.toString(),
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
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (value) {
                final weight = double.tryParse(value) ?? 0;
                onChanged(TrainingSet(weight: weight, reps: set.reps));
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              initialValue: set.reps == 0 ? '' : set.reps.toString(),
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