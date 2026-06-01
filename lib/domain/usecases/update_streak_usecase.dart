class StreakResult {
  const StreakResult({
    required this.currentStreak,
    required this.longestStreak,
    required this.lastPracticeDate,
    required this.isNewDay,
  });

  final int currentStreak;
  final int longestStreak;
  final String lastPracticeDate;
  final bool isNewDay; // true when streak was incremented
}

abstract class UpdateStreakUseCase {
  static StreakResult calculate({
    required String? lastPracticeDate,
    required int currentStreak,
    required int longestStreak,
  }) {
    final now = DateTime.now();
    final todayStr = _dateStr(now);

    if (lastPracticeDate == null) {
      return StreakResult(
        currentStreak: 1,
        longestStreak: longestStreak < 1 ? 1 : longestStreak,
        lastPracticeDate: todayStr,
        isNewDay: true,
      );
    }

    // Already practiced today — don't double-count
    if (lastPracticeDate == todayStr) {
      return StreakResult(
        currentStreak: currentStreak,
        longestStreak: longestStreak,
        lastPracticeDate: todayStr,
        isNewDay: false,
      );
    }

    final last = DateTime.parse(lastPracticeDate);
    final yesterday = now.subtract(const Duration(days: 1));
    final wasYesterday = last.year == yesterday.year &&
        last.month == yesterday.month &&
        last.day == yesterday.day;

    final newStreak = wasYesterday ? currentStreak + 1 : 1;
    final newLongest = newStreak > longestStreak ? newStreak : longestStreak;

    return StreakResult(
      currentStreak: newStreak,
      longestStreak: newLongest,
      lastPracticeDate: todayStr,
      isNewDay: true,
    );
  }

  static String _dateStr(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}
