class HabitStreakResult {
  final int currentStreak;
  final int longestStreak;
  final double completionRate30Days;
  final bool isCompletedToday;

  const HabitStreakResult({
    required this.currentStreak,
    required this.longestStreak,
    required this.completionRate30Days,
    required this.isCompletedToday,
  });
}

class HabitStreakCalculator {
  /// Menghitung streak saat ini dan streak terpanjang berdasarkan tanggal logis
  static HabitStreakResult calculate({
    required String frequencyType,
    required Map<String, dynamic> frequencyConfig,
    required Set<DateTime> completedDates,
    required DateTime logicalToday,
  }) {
    // Normalisasi semua tanggal ke DateTime(y, m, d)
    final normalizedDates =
        completedDates.map((d) => DateTime(d.year, d.month, d.day)).toSet();

    final today =
        DateTime(logicalToday.year, logicalToday.month, logicalToday.day);
    final isDoneToday = normalizedDates.contains(today);

    // Ambil daftar hari aktif jika specific_days (1 = Senin, 7 = Minggu)
    List<int> activeDays = [1, 2, 3, 4, 5, 6, 7];
    if (frequencyType == 'specific_days') {
      final days = frequencyConfig['days'];
      if (days is List) {
        activeDays = days.map((e) => int.tryParse(e.toString()) ?? 1).toList();
      }
    }

    // 1. Hitung Current Streak
    int currentStreak = 0;
    // Mulai dari hari ini (jika sudah dikerjakan) atau kemarin (jika hari ini belum ditandai)
    DateTime checkDate =
        isDoneToday ? today : today.subtract(const Duration(days: 1));

    // Jika hari ini belum dikerjakan, dan kemarin adalah hari aktif tapi tidak dikerjakan, streak = 0
    if (!isDoneToday) {
      if (activeDays.contains(checkDate.weekday) &&
          !normalizedDates.contains(checkDate)) {
        currentStreak = 0;
      }
    }

    while (true) {
      // Jika hari ini bukan hari aktif (pada specific_days), lewati tanpa merusak streak
      if (!activeDays.contains(checkDate.weekday)) {
        checkDate = checkDate.subtract(const Duration(days: 1));
        // Batasi pengecekan ke belakang maksimal 365 hari
        if (today.difference(checkDate).inDays > 365) break;
        continue;
      }

      if (normalizedDates.contains(checkDate)) {
        currentStreak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }

      if (today.difference(checkDate).inDays > 365) break;
    }

    // 2. Hitung Longest Streak (dari rentang 365 hari terakhir)
    int longestStreak = currentStreak;
    int tempStreak = 0;

    for (int i = 365; i >= 0; i--) {
      final d = today.subtract(Duration(days: i));
      if (!activeDays.contains(d.weekday)) {
        continue; // Lewati hari libur / non-aktif
      }

      if (normalizedDates.contains(d)) {
        tempStreak++;
        if (tempStreak > longestStreak) {
          longestStreak = tempStreak;
        }
      } else {
        tempStreak = 0;
      }
    }

    // 3. Tingkat Penyelesaian 30 Hari Terakhir
    int requiredDays30 = 0;
    int doneDays30 = 0;

    for (int i = 0; i < 30; i++) {
      final d = today.subtract(Duration(days: i));
      if (activeDays.contains(d.weekday)) {
        requiredDays30++;
        if (normalizedDates.contains(d)) {
          doneDays30++;
        }
      }
    }

    final rate = requiredDays30 == 0 ? 0.0 : (doneDays30 / requiredDays30);

    return HabitStreakResult(
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      completionRate30Days: rate,
      isCompletedToday: isDoneToday,
    );
  }
}
