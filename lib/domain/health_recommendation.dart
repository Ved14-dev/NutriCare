class HealthRecommendation {
  final String id;
  final String userId;
  final String type; // e.g., 'hydration', 'nutrition', 'activity'
  final String message;
  final DateTime createdAt;

  HealthRecommendation({
    required this.id,
    required this.userId,
    required this.type,
    required this.message,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'type': type,
        'message': message,
        'created_at': createdAt.toUtc().toIso8601String(),
      };

  factory HealthRecommendation.fromJson(Map<String, dynamic> json) => HealthRecommendation(
        id: json['id'],
        userId: json['user_id'],
        type: json['type'],
        message: json['message'],
        createdAt: DateTime.parse(json['created_at']),
      );
}
