class Workout {
  final int? id;
  final int goalId;
  final String date;
  final double value;
  final String? notes;

  Workout({
    this.id,
    required this.goalId,
    required this.date,
    required this.value,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'goalId': goalId,
      'date': date,
      'value': value,
      'notes': notes,
    };
  }

  factory Workout.fromMap(Map<String, dynamic> map) {
    return Workout(
      id: map['id'],
      goalId: map['goalId'],
      date: map['date'],
      value: map['value'],
      notes: map['notes'],
    );
  }
}