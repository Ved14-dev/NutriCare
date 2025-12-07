class HydrationEvent {
  final DateTime timestamp;
  final int amountMl;
  final String source;

  HydrationEvent({
    required this.timestamp,
    required this.amountMl,
    required this.source,
  });

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toUtc().toIso8601String(),
        'amount_ml': amountMl,
        'source': source,
      };

  factory HydrationEvent.fromJson(Map<String, dynamic> json) => HydrationEvent(
        timestamp: DateTime.parse(json['timestamp']),
        amountMl: json['amount_ml'],
        source: json['source'],
      );
}
