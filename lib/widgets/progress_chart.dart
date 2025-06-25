import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/training_note.dart';
import '../services/storage_service.dart';

class ProgressChart extends StatefulWidget {
  const ProgressChart({Key? key}) : super(key: key);

  @override
  State<ProgressChart> createState() => _ProgressChartState();
}

class _ProgressChartState extends State<ProgressChart> {
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

  List<FlSpot> _generateChartData() {
    if (_notes.isEmpty) return [];

    return _notes.asMap().entries.map((entry) {
      final index = entry.key;
      final note = entry.value;
      return FlSpot(index.toDouble(), note.bodyWeight);
    }).toList();
  }

  Widget _buildBottomTitles(double value, TitleMeta meta) {
    if (_notes.isEmpty || value.toInt() >= _notes.length) {
      return const SizedBox.shrink();
    }

    final note = _notes[value.toInt()];
    final formattedDate = DateFormat('M/d').format(note.date);

    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Text(
        formattedDate,
        style: const TextStyle(fontSize: 10),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_notes.isEmpty) {
      return const Center(
        child: Text(
          'データがありません',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    final chartData = _generateChartData();
    if (chartData.isEmpty) {
      return const Center(
        child: Text(
          'データがありません',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      height: 300,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: true),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 40),
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
              color: Theme.of(context).primaryColor,
              barWidth: 3,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: Theme.of(context).primaryColor.withOpacity(0.2),
              ),
            ),
          ],
          minX: 0,
          maxX: (chartData.length - 1).toDouble(),
          minY: chartData.map((spot) => spot.y).reduce((a, b) => a < b ? a : b) * 0.9,
          maxY: chartData.map((spot) => spot.y).reduce((a, b) => a > b ? a : b) * 1.1,
        ),
      ),
    );
  }
}