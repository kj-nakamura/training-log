import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/exercise_report.dart';
import '../models/max_exercise.dart';
import '../services/report_service.dart';
import '../services/storage_service.dart';
import 'note_creation_screen.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({Key? key}) : super(key: key);

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final ReportService _reportService = ReportService();
  final StorageService _storageService = StorageService();
  List<ExerciseReport> _reports = [];
  List<MaxExercise> _maxExercises = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final reports = await _reportService.getExerciseReports();
      final maxExercises = await _storageService.getMaxExercises();
      setState(() {
        _reports = reports;
        _maxExercises = maxExercises;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _navigateToMaxWeightDate(ExerciseReport report) async {
    try {
      final existingNote = await _storageService.getNoteForDate(report.achievedDate);
      
      if (mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NoteCreationScreen(
              existingNote: existingNote,
              selectedDate: report.achievedDate,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('画面の遷移に失敗しました: $e')),
        );
      }
    }
  }

  Future<void> _showAddExerciseDialog() async {
    final nameController = TextEditingController();
    final goalController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('種目を登録'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: '種目名',
                hintText: 'ベンチプレス',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: goalController,
              decoration: const InputDecoration(
                labelText: '目標重量 (kg)',
                hintText: '100',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty && goalController.text.isNotEmpty) {
                final exercise = MaxExercise(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameController.text,
                  goalWeight: double.tryParse(goalController.text) ?? 0,
                  createdAt: DateTime.now(),
                );
                
                await _storageService.saveMaxExercise(exercise);
                await _loadReports();
                Navigator.pop(context);
              }
            },
            child: const Text('登録'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteMaxExercise(MaxExercise exercise) async {
    // Check if this exercise is used in any training notes
    final notesUsingExercise = await _storageService.getNotesUsingExercise(exercise.name);
    
    if (notesUsingExercise.isEmpty) {
      // Simple deletion if no training records exist
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('種目を削除'),
          content: Text('「${exercise.name}」を削除しますか？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('キャンセル'),
            ),
            TextButton(
              onPressed: () async {
                await _storageService.deleteMaxExercise(exercise.id);
                await _loadReports();
                Navigator.pop(context);
              },
              child: const Text('削除'),
            ),
          ],
        ),
      );
    } else {
      // Show options dialog if training records exist
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('種目の削除'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('「${exercise.name}」は${notesUsingExercise.length}件のトレーニング記録で使用されています。'),
              const SizedBox(height: 16),
              const Text('削除時の処理を選択してください：'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('キャンセル'),
            ),
            TextButton(
              onPressed: () async {
                await _storageService.deleteMaxExercise(exercise.id);
                await _storageService.removeExerciseFromNotes(exercise.name);
                await _loadReports();
                Navigator.pop(context);
              },
              child: const Text('種目と記録を削除'),
            ),
            TextButton(
              onPressed: () async {
                await _storageService.deleteMaxExercise(exercise.id);
                await _loadReports();
                Navigator.pop(context);
              },
              child: const Text('種目のみ削除'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📊 トレーニングレポート'),
        backgroundColor: const Color(0xFF8B4513),
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            onPressed: _showAddExerciseDialog,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      backgroundColor: const Color(0xFFFAF6F0),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF8B4513),
              ),
            )
          : Column(
              children: [
                if (_maxExercises.isNotEmpty) _buildMaxExercisesList(),
                if (_reports.isNotEmpty) 
                  Expanded(child: _buildReportList())
                else if (_maxExercises.isEmpty)
                  Expanded(child: _buildEmptyState()),
              ],
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'まだトレーニング記録がありません',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontFamily: 'serif',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'トレーニングを記録すると\nマックス重量のレポートが表示されます',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
              fontFamily: 'serif',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaxExercisesList() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
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
              const Icon(
                Icons.track_changes,
                color: Color(0xFF8B4513),
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                'マックス測定登録種目',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'serif',
                  color: Color(0xFF5D4037),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...(_maxExercises.map((exercise) => _buildMaxExerciseCard(exercise))),
        ],
      ),
    );
  }

  Widget _buildMaxExerciseCard(MaxExercise exercise) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF6F0),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFE8E1D9),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF5D4037),
                  ),
                ),
                Text(
                  '目標: ${exercise.goalWeight}kg',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF8B4513),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _deleteMaxExercise(exercise),
            icon: const Icon(
              Icons.delete_outline,
              color: Colors.red,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportList() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
          child: Row(
            children: [
              const Icon(
                Icons.emoji_events,
                color: Color(0xFF8B4513),
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                '種目別マックス重量レポート',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'serif',
                  color: Color(0xFF5D4037),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: _reports.length,
            itemBuilder: (context, index) {
              final report = _reports[index];
              return _buildReportCard(report);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildReportCard(ExerciseReport report) {
    return GestureDetector(
      onTap: () => _navigateToMaxWeightDate(report),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
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
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
          children: [
            // 種目アイコン
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Color(0xFF8B4513),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.fitness_center,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 16),
            // 種目情報
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    report.exerciseName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'serif',
                      color: Color(0xFF5D4037),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.fitness_center,
                        size: 16,
                        color: Color(0xFF8B4513),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'マックス: ${report.maxWeight}kg',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'serif',
                          color: Color(0xFF8B4513),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '達成日: ${DateFormat('yyyy/MM/dd').format(report.achievedDate)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'serif',
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(
                        Icons.repeat,
                        size: 14,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'この重量を上げた回数: ${report.totalSessions}回',
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'serif',
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // 矢印アイコン
            const Icon(
              Icons.arrow_forward_ios,
              color: Color(0xFF8B4513),
              size: 16,
            ),
          ],
        ),
      ),
    ),
    );
  }
}