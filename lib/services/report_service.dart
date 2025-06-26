import '../models/exercise_report.dart';
import '../models/training_note.dart';
import 'storage_service.dart';

class ReportService {
  final StorageService _storageService = StorageService();

  Future<List<ExerciseReport>> getExerciseReports() async {
    final notes = await _storageService.getNotes();
    final Map<String, ExerciseData> exerciseMap = {};

    // 全ノートから種目データを集計
    for (final note in notes) {
      for (final exercise in note.exercises) {
        if (exercise.name.isEmpty) continue;

        final exerciseName = exercise.name;
        
        if (!exerciseMap.containsKey(exerciseName)) {
          exerciseMap[exerciseName] = ExerciseData(
            name: exerciseName,
            maxWeight: 0.0,
            achievedDate: note.date,
            maxWeightCount: 0,
          );
        }

        // 最大重量を計算（重量が同じ場合はより多くの回数を優先）
        for (final set in exercise.sets) {
          if (set.weight > exerciseMap[exerciseName]!.maxWeight || 
              (set.weight == exerciseMap[exerciseName]!.maxWeight && 
               set.reps > exerciseMap[exerciseName]!.maxWeightCount)) {
            exerciseMap[exerciseName]!.maxWeight = set.weight;
            exerciseMap[exerciseName]!.achievedDate = note.date;
            exerciseMap[exerciseName]!.maxWeightCount = set.reps; // そのセットでの回数
          }
        }
      }
    }

    // ExerciseReportのリストに変換
    final reports = exerciseMap.values
        .where((data) => data.maxWeight > 0) // 重量が0より大きいもののみ
        .map((data) => ExerciseReport(
              exerciseName: data.name,
              maxWeight: data.maxWeight,
              achievedDate: data.achievedDate,
              totalSessions: data.maxWeightCount,
            ))
        .toList();

    // 種目名のアルファベット順でソート
    reports.sort((a, b) => a.exerciseName.compareTo(b.exerciseName));

    return reports;
  }

  Future<double> getMaxWeightForExercise(String exerciseName) async {
    final notes = await _storageService.getNotes();
    double maxWeight = 0.0;

    for (final note in notes) {
      for (final exercise in note.exercises) {
        if (exercise.name.toLowerCase() == exerciseName.toLowerCase()) {
          for (final set in exercise.sets) {
            if (set.weight > maxWeight) {
              maxWeight = set.weight;
            }
          }
        }
      }
    }

    return maxWeight;
  }
}

class ExerciseData {
  String name;
  double maxWeight;
  DateTime achievedDate;
  int maxWeightCount;

  ExerciseData({
    required this.name,
    required this.maxWeight,
    required this.achievedDate,
    required this.maxWeightCount,
  });
}