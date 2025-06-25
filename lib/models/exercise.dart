import 'training_set.dart';

class Exercise {
  final String name;
  final int interval;
  final List<TrainingSet> sets;
  final String? memo;

  Exercise({
    required this.name,
    required this.interval,
    required this.sets,
    this.memo,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'interval': interval,
      'sets': sets.map((set) => set.toJson()).toList(),
      'memo': memo,
    };
  }

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      name: json['name'] ?? '',
      interval: json['interval']?.toInt() ?? 0,
      sets: (json['sets'] as List<dynamic>?)
          ?.map((setJson) => TrainingSet.fromJson(setJson))
          .toList() ?? [],
      memo: json['memo'],
    );
  }
}