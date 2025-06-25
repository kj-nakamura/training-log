class Goal {
  final int? id;
  final String name;
  final double targetValue;
  final String startDate;
  final String endDate;
  final String unit;

  Goal({
    this.id,
    required this.name,
    required this.targetValue,
    required this.startDate,
    required this.endDate,
    required this.unit,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'targetValue': targetValue,
      'startDate': startDate,
      'endDate': endDate,
      'unit': unit,
    };
  }

  factory Goal.fromMap(Map<String, dynamic> map) {
    return Goal(
      id: map['id'],
      name: map['name'],
      targetValue: map['targetValue'],
      startDate: map['startDate'],
      endDate: map['endDate'],
      unit: map['unit'],
    );
  }
}