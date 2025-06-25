import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/training_note.dart';
import '../models/exercise.dart';

class NoteDetailScreen extends StatelessWidget {
  final TrainingNote note;

  const NoteDetailScreen({Key? key, required this.note}) : super(key: key);

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
              // Date and body weight section
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
                          '日付: ${DateFormat('yyyy/MM/dd').format(note.date)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontFamily: 'serif',
                            color: Color(0xFF5D4037),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.monitor_weight, color: Color(0xFF8B4513)),
                        const SizedBox(width: 8),
                        Text(
                          '体重: ${note.bodyWeight.toString()} kg',
                          style: const TextStyle(
                            fontSize: 16,
                            fontFamily: 'serif',
                            color: Color(0xFF5D4037),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Exercises section header
              Container(
                margin: const EdgeInsets.only(left: 8),
                child: const Row(
                  children: [
                    Text(
                      '🏋️ 種目',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'serif',
                        color: Color(0xFF5D4037),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Exercise cards
              ...note.exercises.map((exercise) {
                return ExerciseDetailCard(exercise: exercise);
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }
}

class ExerciseDetailCard extends StatelessWidget {
  final Exercise exercise;

  const ExerciseDetailCard({Key? key, required this.exercise}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Filter out empty sets (weight and reps both 0)
    final activeSets = exercise.sets.where((set) => set.weight > 0 || set.reps > 0).toList();
    
    // Don't show exercise card if name is empty and no active sets
    if (exercise.name.isEmpty && activeSets.isEmpty) {
      return const SizedBox.shrink();
    }

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
          // Exercise name
          if (exercise.name.isNotEmpty)
            Text(
              exercise.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'serif',
                color: Color(0xFF5D4037),
              ),
            ),
          if (exercise.name.isNotEmpty) const SizedBox(height: 12),
          
          // Interval
          if (exercise.interval > 0) ...[
            Row(
              children: [
                const Icon(Icons.timer, color: Color(0xFF8B4513), size: 16),
                const SizedBox(width: 4),
                Text(
                  'インターバル: ${exercise.interval}秒',
                  style: const TextStyle(
                    fontSize: 14,
                    fontFamily: 'serif',
                    color: Color(0xFF8B4513),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          
          // Sets
          if (activeSets.isNotEmpty) ...[
            const Text(
              'セット',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'serif',
                color: Color(0xFF5D4037),
              ),
            ),
            const SizedBox(height: 8),
            ...activeSets.asMap().entries.map((entry) {
              final index = entry.key;
              final set = entry.value;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    SizedBox(
                      width: 30,
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontFamily: 'serif',
                          color: Color(0xFF5D4037),
                        ),
                      ),
                    ),
                    Text(
                      '${set.weight}kg × ${set.reps}回',
                      style: const TextStyle(
                        fontFamily: 'serif',
                        color: Color(0xFF5D4037),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            const SizedBox(height: 12),
          ],
          
          // Memo
          if (exercise.memo != null && exercise.memo!.isNotEmpty) ...[
            const Text(
              'メモ',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'serif',
                color: Color(0xFF5D4037),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFAF6F0),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: const Color(0xFFE8E1D9),
                  width: 1,
                ),
              ),
              child: Text(
                exercise.memo!,
                style: const TextStyle(
                  fontFamily: 'serif',
                  color: Color(0xFF5D4037),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}