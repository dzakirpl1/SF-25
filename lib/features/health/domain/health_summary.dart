class HealthSummary {
  final int todayWaterMl;
  final int targetWaterMl;
  final Duration? lastSleepDuration;
  final int? lastSleepQuality;
  final int weekWorkoutsCount;

  const HealthSummary({
    required this.todayWaterMl,
    this.targetWaterMl = 2000,
    this.lastSleepDuration,
    this.lastSleepQuality,
    this.weekWorkoutsCount = 0,
  });

  double get waterProgress {
    if (targetWaterMl <= 0) return 0.0;
    final p = todayWaterMl / targetWaterMl;
    return p > 1.0 ? 1.0 : p;
  }

  bool get isWaterTargetMet => todayWaterMl >= targetWaterMl;
}
