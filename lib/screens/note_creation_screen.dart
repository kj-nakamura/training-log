import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/training_note.dart';
import '../models/exercise.dart';
import '../models/cardio_exercise.dart';
import '../models/training_set.dart';
import '../models/max_exercise.dart';
import '../services/storage_service.dart';
import '../widgets/progress_chart.dart';
import 'calendar_screen.dart';
import 'report_screen.dart';

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
  CardioExercise? _cardioExercise;
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  bool _isInitialLoad = true;
  bool _isEditingBodyWeight = false;

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
      _bodyWeightController.text = existingNote.bodyWeight?.toString() ?? '';
      _exercises = List.from(existingNote.exercises);
      _cardioExercise = existingNote.cardioExercise ?? CardioExercise(distanceInKm: 0, durationInMinutes: 0);
    } else {
      // Initialize with 1 empty exercise and clear body weight
      _bodyWeightController.clear();
      _exercises.clear();
      _exercises.add(Exercise(
        name: '',
        sets: [TrainingSet(weight: 0, reps: 0)], // Start with 1 set
        memo: '',
      ));
      _cardioExercise = CardioExercise(distanceInKm: 0, durationInMinutes: 0);
    }
    // Clear editing states
    _isEditingBodyWeight = _bodyWeightController.text.isEmpty;
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
    
    // Show brief feedback removed
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
        bodyWeight: _bodyWeightController.text.isEmpty ? null : double.parse(_bodyWeightController.text),
        exercises: _exercises,
        cardioExercise: _cardioExercise,
      );

      await _storageService.saveNote(note);

      // Note saved
    }
  }

  Future<void> _saveBodyWeightUnified() async {
    if (_bodyWeightController.text.isNotEmpty) {
      final weight = double.tryParse(_bodyWeightController.text);
      if (weight != null && weight > 0) {
        final existingNote = await _storageService.getNoteForDate(_selectedDate);
        
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
          bodyWeight: weight,
          exercises: existingNote?.exercises ?? _exercises,
          cardioExercise: existingNote?.cardioExercise ?? _cardioExercise,
        );
        
        await _storageService.saveNote(note);
        // Body weight saved
      }
    }
  }




  Future<void> _saveExerciseUnified(int index) async {
    final exercise = _exercises[index];
    if (exercise.name.trim().isEmpty) {
      // Show validation error but don't save
      return;
    }
    
    final existingNote = await _storageService.getNoteForDate(_selectedDate);
    
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
      bodyWeight: existingNote?.bodyWeight ?? (_bodyWeightController.text.isNotEmpty ? double.tryParse(_bodyWeightController.text) : null),
      exercises: _exercises,
      cardioExercise: existingNote?.cardioExercise ?? _cardioExercise,
    );
    
    await _storageService.saveNote(note);
    // Exercise saved
  }

  void _addExerciseUnified() {
    // Check exercise limit (maximum 5 exercises)
    if (_exercises.length >= 5) {
      return;
    }

    setState(() {
      _exercises.add(Exercise(
        name: '',
        sets: [TrainingSet(weight: 0, reps: 0)],
        memo: '',
      ));
    });
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

    // Exercise deleted
  }

  void _showReport() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ReportScreen(),
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
          icon: const Icon(Icons.analytics),
          onPressed: _showReport,
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
      body: Container(
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
                  child: _buildDisplayMode(),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCardioSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '🏃 有酸素運動',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'serif',
            color: Color(0xFF5D4037),
          ),
        ),
        const SizedBox(height: 16),
        if (_cardioExercise != null)
          CardioExerciseCard(
            key: ValueKey('cardio_${_selectedDate.toIso8601String()}'),
            cardioExercise: _cardioExercise!,
            onChanged: (updatedCardio) {
              setState(() {
                _cardioExercise = updatedCardio;
              });
            },
            onSave: _saveNote,
          )
        else
          Container(
            padding: const EdgeInsets.all(20),
            child: const Text(
              '有酸素運動は記録されていません',
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
                    // Left arrow button
                    GestureDetector(
                      onTap: () {
                        final previousDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day - 1);
                        _switchToDate(previousDay, true);
                      },
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B4513).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: const Color(0xFF8B4513),
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.chevron_left,
                          color: Color(0xFF8B4513),
                          size: 32,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.calendar_today, color: Color(0xFF8B4513)),
                              const SizedBox(width: 8),
                              Text(
                                '${DateFormat('yyyy年MM月dd日').format(_selectedDate)}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'serif',
                                  color: Color(0xFF5D4037),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'のトレーニング',
                            style: TextStyle(
                              fontSize: 16,
                              fontFamily: 'serif',
                              color: Color(0xFF5D4037),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Right arrow button
                    GestureDetector(
                      onTap: () {
                        final nextDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day + 1);
                        _switchToDate(nextDay, false);
                      },
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B4513).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: const Color(0xFF8B4513),
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.chevron_right,
                          color: Color(0xFF8B4513),
                          size: 32,
                        ),
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
                                    textInputAction: TextInputAction.done,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.check, color: Colors.green),
                                  onPressed: () {
                                    _saveBodyWeightUnified();
                                    setState(() => _isEditingBodyWeight = false);
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, color: Colors.red),
                                  onPressed: () => setState(() => _isEditingBodyWeight = false),
                                ),
                              ],
                            )
                          : Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _bodyWeightController.text.isNotEmpty 
                                        ? '体重: ${_bodyWeightController.text}kg'
                                        : '体重: 記録なし',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontFamily: 'serif',
                                      color: _bodyWeightController.text.isNotEmpty 
                                          ? const Color(0xFF5D4037) 
                                          : Colors.grey,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 18),
                                  color: const Color(0xFF8B4513),
                                  onPressed: () => setState(() => _isEditingBodyWeight = true),
                                ),
                              ],
                            ),
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
          ..._exercises.asMap().entries.map((exerciseEntry) {
            final exerciseIndex = exerciseEntry.key;
            final exercise = exerciseEntry.value;
            
            return EditModeExerciseCard(
              key: ValueKey('unified_${_selectedDate.toIso8601String()}_$exerciseIndex'),
              exercise: exercise,
              selectedDate: _selectedDate,
              onChanged: (updatedExercise) {
                setState(() {
                  _exercises[exerciseIndex] = updatedExercise;
                });
              },
              onSave: () => _saveExerciseUnified(exerciseIndex),
              onDelete: () => _deleteExerciseWithConfirmation(exerciseIndex),
            );
          }).toList(),
          // Show message when no exercises recorded
          if (_exercises.where((exercise) => exercise.name.isNotEmpty).toList().isEmpty)
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
          // Add exercise button (show when less than 5 exercises)
          if (_exercises.length < 5)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: OutlinedButton.icon(
                onPressed: _addExerciseUnified,
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
          const SizedBox(height: 16),
          _buildCardioSection(),
        ],
      ),
    );
  }
}

class EditModeExerciseCard extends StatefulWidget {
  final Exercise exercise;
  final DateTime selectedDate;
  final Function(Exercise) onChanged;
  final VoidCallback onSave;
  final VoidCallback onDelete;

  const EditModeExerciseCard({
    Key? key,
    required this.exercise,
    required this.selectedDate,
    required this.onChanged,
    required this.onSave,
    required this.onDelete,
  }) : super(key: key);

  @override
  State<EditModeExerciseCard> createState() => _EditModeExerciseCardState();
}

class _EditModeExerciseCardState extends State<EditModeExerciseCard> {
  late final TextEditingController _nameController;
  late List<TrainingSet> _sets;
  final _formKey = GlobalKey<FormState>();
  bool _isEditing = false;
  List<String> _exerciseSuggestions = [];
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.exercise.name);
    _sets = List.from(widget.exercise.sets);
    _isEditing = widget.exercise.name.isEmpty; // Start in edit mode if name is empty
  }

  @override
  void didUpdateWidget(EditModeExerciseCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _nameController.text = widget.exercise.name;
    _sets = List.from(widget.exercise.sets);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _updateExercise() {
    final exercise = Exercise(
      name: _nameController.text.trim(),
      sets: _sets,
      memo: null,
    );
    widget.onChanged(exercise);
  }

  Future<void> _searchExercises(String query) async {
    final storageService = StorageService();
    final suggestions = await storageService.searchMaxExercises(query);
    setState(() {
      _exerciseSuggestions = suggestions;
      _showSuggestions = query.isNotEmpty && suggestions.isNotEmpty;
    });
  }

  void _selectExercise(String exerciseName) {
    _nameController.text = exerciseName;
    setState(() {
      _showSuggestions = false;
    });
    _updateExercise();
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
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _isEditing 
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: '種目名 *',
                              hintText: '登録種目から検索または手動入力',
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
                            textInputAction: TextInputAction.done,
                            onChanged: (value) {
                              _searchExercises(value);
                            },
                            onFieldSubmitted: (_) {
                              setState(() => _showSuggestions = false);
                              _updateExercise();
                            },
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return '種目名を入力してください';
                              }
                              return null;
                            },
                          ),
                          if (_showSuggestions) ...[
                            const SizedBox(height: 4),
                            Container(
                              constraints: const BoxConstraints(maxHeight: 120),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFD7CCC8)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: _exerciseSuggestions.length,
                                itemBuilder: (context, index) {
                                  final suggestion = _exerciseSuggestions[index];
                                  return ListTile(
                                    dense: true,
                                    title: Text(
                                      suggestion,
                                      style: const TextStyle(
                                        fontFamily: 'serif',
                                        color: Color(0xFF5D4037),
                                      ),
                                    ),
                                    onTap: () => _selectExercise(suggestion),
                                  );
                                },
                              ),
                            ),
                          ],
                        ],
                      )
                    : Text(
                        _nameController.text.isNotEmpty ? _nameController.text : '種目名未設定',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'serif',
                          color: _nameController.text.isNotEmpty ? const Color(0xFF5D4037) : Colors.grey,
                        ),
                      ),
                ),
                const SizedBox(width: 8),
                if (_isEditing) ...[
                  IconButton(
                    icon: const Icon(Icons.check, color: Colors.green),
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        _updateExercise();
                        widget.onSave();
                        setState(() => _isEditing = false);
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () => setState(() => _isEditing = false),
                  ),
                ] else ...[
                  IconButton(
                    icon: const Icon(Icons.edit, size: 18),
                    color: const Color(0xFF8B4513),
                    onPressed: () => setState(() => _isEditing = true),
                  ),
                ],
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: widget.onDelete,
                ),
              ],
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
                onSave: () {
                  _updateExercise();
                  widget.onSave();
                },
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}


class SetRow extends StatefulWidget {
  final int setNumber;
  final TrainingSet set;
  final Function(TrainingSet) onChanged;
  final VoidCallback? onRemove;
  final VoidCallback onSave;

  const SetRow({
    Key? key,
    required this.setNumber,
    required this.set,
    required this.onChanged,
    this.onRemove,
    required this.onSave,
  }) : super(key: key);

  @override
  State<SetRow> createState() => _SetRowState();
}

class _SetRowState extends State<SetRow> {
  bool _isEditing = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Start in edit mode if both weight and reps are 0
    _isEditing = widget.set.weight == 0 && widget.set.reps == 0;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              '${widget.setNumber}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'serif',
                color: Color(0xFF5D4037),
              ),
            ),
          ),
          if (_isEditing) ...[
            Expanded(
              child: Form(
                key: _formKey,
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: widget.set.weight == 0 ? '' : widget.set.weight.toString(),
                        decoration: InputDecoration(
                          labelText: 'kg *',
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
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return '重量を入力';
                          }
                          final weight = double.tryParse(value);
                          if (weight == null) {
                            return '正しい数値を入力';
                          }
                          if (weight <= 0) {
                            return '0より大きい値を入力';
                          }
                          return null;
                        },
                        onChanged: (value) {
                          final weight = double.tryParse(value) ?? 0;
                          widget.onChanged(TrainingSet(weight: weight, reps: widget.set.reps));
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        initialValue: widget.set.reps == 0 ? '' : widget.set.reps.toString(),
                        decoration: InputDecoration(
                          labelText: '回 *',
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
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return '回数を入力';
                          }
                          final reps = int.tryParse(value);
                          if (reps == null) {
                            return '正しい数値を入力';
                          }
                          if (reps <= 0) {
                            return '0より大きい値を入力';
                          }
                          return null;
                        },
                        onChanged: (value) {
                          final reps = int.tryParse(value) ?? 0;
                          widget.onChanged(TrainingSet(weight: widget.set.weight, reps: reps));
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.check, color: Colors.green),
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  setState(() => _isEditing = false);
                  widget.onSave();
                }
              },
            ),
          ] else ...[
            Expanded(
              child: Text(
                widget.set.weight > 0 || widget.set.reps > 0 
                    ? '${widget.set.weight}kg × ${widget.set.reps}回'
                    : '未入力',
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: 'serif',
                  color: widget.set.weight > 0 || widget.set.reps > 0 
                      ? const Color(0xFF5D4037) 
                      : Colors.grey,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit, size: 16),
              color: const Color(0xFF8B4513),
              onPressed: () => setState(() => _isEditing = true),
            ),
          ],
          if (widget.onRemove != null)
            IconButton(
              onPressed: widget.onRemove,
              icon: const Icon(Icons.remove_circle_outline),
              color: Colors.red,
            ),
        ],
      ),
    );
  }
}

class CardioExerciseCard extends StatefulWidget {
  final CardioExercise cardioExercise;
  final Function(CardioExercise) onChanged;
  final VoidCallback onSave;

  const CardioExerciseCard({
    Key? key,
    required this.cardioExercise,
    required this.onChanged,
    required this.onSave,
  }) : super(key: key);

  @override
  State<CardioExerciseCard> createState() => _CardioExerciseCardState();
}

class _CardioExerciseCardState extends State<CardioExerciseCard> {
  late final TextEditingController _kmController;
  late final TextEditingController _minutesController;
  final _formKey = GlobalKey<FormState>();
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _kmController = TextEditingController(text: widget.cardioExercise.distanceInKm == 0 ? '' : widget.cardioExercise.distanceInKm.toString());
    _minutesController = TextEditingController(text: widget.cardioExercise.durationInMinutes == 0 ? '' : widget.cardioExercise.durationInMinutes.toString());
    _isEditing = widget.cardioExercise.distanceInKm == 0 && widget.cardioExercise.durationInMinutes == 0;
  }

  @override
  void dispose() {
    _kmController.dispose();
    _minutesController.dispose();
    super.dispose();
  }

  void _updateCardio() {
    final km = double.tryParse(_kmController.text) ?? 0;
    final minutes = int.tryParse(_minutesController.text) ?? 0;
    widget.onChanged(CardioExercise(distanceInKm: km, durationInMinutes: minutes));
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
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _isEditing
                      ? Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _kmController,
                                decoration: InputDecoration(
                                  labelText: '距離 (km)',
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
                                textInputAction: TextInputAction.next,
                                onChanged: (_) => _updateCardio(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                controller: _minutesController,
                                decoration: InputDecoration(
                                  labelText: '時間 (分)',
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
                                keyboardType: TextInputType.number,
                                textInputAction: TextInputAction.done,
                                onChanged: (_) => _updateCardio(),
                              ),
                            ),
                          ],
                        )
                      : Text(
                          '${widget.cardioExercise.distanceInKm} km / ${widget.cardioExercise.durationInMinutes} 分',
                          style: const TextStyle(
                            fontSize: 16,
                            fontFamily: 'serif',
                            color: Color(0xFF5D4037),
                          ),
                        ),
                ),
                const SizedBox(width: 8),
                if (_isEditing) ...[
                  IconButton(
                    icon: const Icon(Icons.check, color: Colors.green),
                    onPressed: () {
                      _updateCardio();
                      widget.onSave();
                      setState(() => _isEditing = false);
                    },
                  ),
                ] else ...[
                  IconButton(
                    icon: const Icon(Icons.edit, size: 18),
                    color: const Color(0xFF8B4513),
                    onPressed: () => setState(() => _isEditing = true),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}