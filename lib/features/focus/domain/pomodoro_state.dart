class PomodoroState {
  final String mode; // 'pomodoro', 'short_break', 'long_break'
  final int totalSeconds;
  final int remainingSeconds;
  final bool isRunning;
  final String? selectedTaskId;
  final String? selectedProjectId;
  final DateTime? startedAt;

  const PomodoroState({
    required this.mode,
    required this.totalSeconds,
    required this.remainingSeconds,
    this.isRunning = false,
    this.selectedTaskId,
    this.selectedProjectId,
    this.startedAt,
  });

  double get progress {
    if (totalSeconds == 0) return 0.0;
    return (totalSeconds - remainingSeconds) / totalSeconds;
  }

  String get formattedTime {
    final m = remainingSeconds ~/ 60;
    final s = remainingSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  PomodoroState copyWith({
    String? mode,
    int? totalSeconds,
    int? remainingSeconds,
    bool? isRunning,
    String? selectedTaskId,
    String? selectedProjectId,
    DateTime? startedAt,
    bool clearTask = false,
    bool clearProject = false,
  }) {
    return PomodoroState(
      mode: mode ?? this.mode,
      totalSeconds: totalSeconds ?? this.totalSeconds,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      isRunning: isRunning ?? this.isRunning,
      selectedTaskId:
          clearTask ? null : (selectedTaskId ?? this.selectedTaskId),
      selectedProjectId:
          clearProject ? null : (selectedProjectId ?? this.selectedProjectId),
      startedAt: startedAt ?? this.startedAt,
    );
  }
}
