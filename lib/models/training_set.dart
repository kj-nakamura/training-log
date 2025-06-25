class TrainingSet {
  final double weight;
  final int reps;

  TrainingSet({
    required this.weight,
    required this.reps,
  });

  Map<String, dynamic> toJson() {
    return {
      'weight': weight,
      'reps': reps,
    };
  }

  factory TrainingSet.fromJson(Map<String, dynamic> json) {
    return TrainingSet(
      weight: json['weight']?.toDouble() ?? 0.0,
      reps: json['reps']?.toInt() ?? 0,
    );
  }
}