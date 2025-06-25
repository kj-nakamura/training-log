import 'training_set.dart';

class Exercise {
  final String name;
  final List<TrainingSet> sets;
  final String? memo;

  Exercise({
    required this.name,
    required this.sets,
    this.memo,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'sets': sets.map((set) => set.toJson()).toList(),
      'memo': memo,
    };
  }

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      name: json['name'] ?? '',
      sets: (json['sets'] as List<dynamic>?)
          ?.map((setJson) => TrainingSet.fromJson(setJson))
          .toList() ?? [],
      memo: json['memo'],
    );
  }
}