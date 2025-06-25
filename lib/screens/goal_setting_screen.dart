import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/goal.dart';
import '../database/database_helper.dart';

class GoalSettingScreen extends StatefulWidget {
  const GoalSettingScreen({Key? key}) : super(key: key);

  @override
  State<GoalSettingScreen> createState() => _GoalSettingScreenState();
}

class _GoalSettingScreenState extends State<GoalSettingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _targetValueController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedUnit;

  final List<String> _units = ['kg', '回', '分', 'km', 'セット'];
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  @override
  void dispose() {
    _nameController.dispose();
    _targetValueController.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  Future<void> _selectEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  Future<void> _saveGoal() async {
    if (_formKey.currentState!.validate()) {
      final goal = Goal(
        name: _nameController.text,
        targetValue: double.parse(_targetValueController.text),
        startDate: DateFormat('yyyy-MM-dd').format(_startDate!),
        endDate: DateFormat('yyyy-MM-dd').format(_endDate!),
        unit: _selectedUnit!,
      );

      await _databaseHelper.insertGoal(goal);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ノートが保存されました')),
        );
        Navigator.pop(context);
      }
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'トレーニング名',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'トレーニング名を入力してください';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _targetValueController,
                decoration: const InputDecoration(
                  labelText: '記録値',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '記録値を入力してください';
                  }
                  if (double.tryParse(value) == null) {
                    return '正しい数値を入力してください';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedUnit,
                decoration: const InputDecoration(
                  labelText: '単位',
                  border: OutlineInputBorder(),
                ),
                items: _units.map((String unit) {
                  return DropdownMenuItem<String>(
                    value: unit,
                    child: Text(unit),
                  );
                }).toList(),
                onChanged: (String? value) {
                  setState(() {
                    _selectedUnit = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return '単位を選択してください';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: _selectStartDate,
                      child: Text(
                        _startDate == null
                            ? 'トレーニング開始日を選択'
                            : '開始日: ${DateFormat('yyyy/MM/dd').format(_startDate!)}',
                      ),
                    ),
                  ),
                ],
              ),
              if (_startDate == null)
                const Text(
                  '開始日を選択してください',
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: _selectEndDate,
                      child: Text(
                        _endDate == null
                            ? 'トレーニング終了日を選択'
                            : '終了日: ${DateFormat('yyyy/MM/dd').format(_endDate!)}',
                      ),
                    ),
                  ),
                ],
              ),
              if (_endDate == null)
                const Text(
                  '終了日を選択してください',
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _startDate != null && _endDate != null ? _saveGoal : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('ノートを保存'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}