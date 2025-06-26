class MaxExercise {
  final String id;
  final String name;
  final double goalWeight;
  final DateTime createdAt;

  MaxExercise({
    required this.id,
    required this.name,
    required this.goalWeight,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'goalWeight': goalWeight,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory MaxExercise.fromJson(Map<String, dynamic> json) {
    return MaxExercise(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      goalWeight: (json['goalWeight'] ?? 0.0).toDouble(),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}