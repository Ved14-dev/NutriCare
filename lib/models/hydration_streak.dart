class HydrationStreak {
  final int currentStreak;
  final int maxStreak;
  final DateTime lastHydrated;

  HydrationStreak({
    required this.currentStreak,
    required this.maxStreak,
    required this.lastHydrated,
  });

  Map<String, dynamic> toJson() => {
        'current_streak': currentStreak,
        'max_streak': maxStreak,
        'last_hydrated': lastHydrated.toUtc().toIso8601String(),
      };

  factory HydrationStreak.fromJson(Map<String, dynamic> json) => HydrationStreak(
        currentStreak: json['current_streak'],
        maxStreak: json['max_streak'],
        lastHydrated: DateTime.parse(json['last_hydrated']),
      );
}
