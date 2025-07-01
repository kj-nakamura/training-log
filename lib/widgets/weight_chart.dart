import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/training_note.dart';
import '../services/storage_service.dart';

class WeightChart extends StatefulWidget {
  const WeightChart({Key? key}) : super(key: key);

  @override
  State<WeightChart> createState() => _WeightChartState();
}

class _WeightChartState extends State<WeightChart> {
  final StorageService _storageService = StorageService();
  List<TrainingNote> _notes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    try {
      final notes = await _storageService.loadNotes();
      setState(() {
        _notes = notes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<FlSpot> _generateWeightData() {
    if (_notes.isEmpty) return [];

    final weightNotes = _notes
        .where((note) => note.bodyWeight != null)
        .toList();

    if (weightNotes.isEmpty) return [];

    // Sort by date to ensure proper chronological order
    weightNotes.sort((a, b) => a.date.compareTo(b.date));

    return weightNotes.asMap().entries.map((entry) {
      final index = entry.key;
      final note = entry.value;
      return FlSpot(index.toDouble(), note.bodyWeight!);
    }).toList();
  }

  Widget _buildBottomTitles(double value, TitleMeta meta) {
    final weightNotes = _notes
        .where((note) => note.bodyWeight != null)
        .toList();

    if (weightNotes.isEmpty) return const SizedBox.shrink();

    // Sort by date to match the data generation
    weightNotes.sort((a, b) => a.date.compareTo(b.date));

    if (value.toInt() >= weightNotes.length) {
      return const SizedBox.shrink();
    }

    final note = weightNotes[value.toInt()];
    final formattedDate = DateFormat('M/d').format(note.date);

    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Text(
        formattedDate,
        style: const TextStyle(fontSize: 10),
      ),
    );
  }

  Widget _buildLeftTitles(double value, TitleMeta meta) {
    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Text(
        '${value.toStringAsFixed(1)}kg',
        style: const TextStyle(fontSize: 10),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final chartData = _generateWeightData();
    if (chartData.isEmpty) {
      return const Center(
        child: Text(
          '体重データがありません',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    final minWeight = chartData.map((spot) => spot.y).reduce((a, b) => a < b ? a : b);
    final maxWeight = chartData.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);
    final weightRange = maxWeight - minWeight;
    final padding = weightRange > 0 ? weightRange * 0.1 : 1.0;

    return Container(
      padding: const EdgeInsets.all(16),
      height: 300,
      child: Column(
        children: [
          const Text(
            '体重推移',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: true),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: _buildLeftTitles,
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: _buildBottomTitles,
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: const Border(
                    bottom: BorderSide(color: Colors.grey),
                    left: BorderSide(color: Colors.grey),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: chartData,
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.blue.withOpacity(0.2),
                    ),
                  ),
                ],
                minX: 0,
                maxX: (chartData.length - 1).toDouble(),
                minY: minWeight - padding,
                maxY: maxWeight + padding,
              ),
            ),
          ),
        ],
      ),
    );
  }
}