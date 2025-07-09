
class CardioExercise {
  final double distanceInKm;
  final int durationInMinutes;

  CardioExercise({
    required this.distanceInKm,
    required this.durationInMinutes,
  });

  Map<String, dynamic> toJson() {
    return {
      'distanceInKm': distanceInKm,
      'durationInMinutes': durationInMinutes,
    };
  }

  factory CardioExercise.fromJson(Map<String, dynamic> json) {
    return CardioExercise(
      distanceInKm: json['distanceInKm']?.toDouble() ?? 0.0,
      durationInMinutes: json['durationInMinutes']?.toInt() ?? 0,
    );
  }
}
