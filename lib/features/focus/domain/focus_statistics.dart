class FocusStatistics {
  final int todayFocusMinutes;
  final int todayCompletedSessions;
  final int weekFocusMinutes;
  final int weekTotalTimeMinutes;

  const FocusStatistics({
    required this.todayFocusMinutes,
    required this.todayCompletedSessions,
    required this.weekFocusMinutes,
    required this.weekTotalTimeMinutes,
  });

  String get formattedTodayFocus {
    final h = todayFocusMinutes ~/ 60;
    final m = todayFocusMinutes % 60;
    if (h > 0) return '${h}j ${m}m';
    return '${m}m';
  }

  String get formattedWeekFocus {
    final h = weekFocusMinutes ~/ 60;
    final m = weekFocusMinutes % 60;
    if (h > 0) return '${h}j ${m}m';
    return '${m}m';
  }

  String get formattedWeekTotalTime {
    final h = weekTotalTimeMinutes ~/ 60;
    final m = weekTotalTimeMinutes % 60;
    if (h > 0) return '${h}j ${m}m';
    return '${m}m';
  }
}
