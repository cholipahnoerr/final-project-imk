import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/auth_service.dart';
import '../../domain/usecases/update_streak_usecase.dart';
import '../datasources/remote/firestore_datasource.dart';
import '../models/user_model.dart';

class GamificationRepository {
  GamificationRepository(this._ds);

  final FirestoreDataSource _ds;

  static const int _xpBonusLessonComplete = 50;
  static const int _gemsPerLesson = 5;

  Future<void> onLessonComplete({
    required UserModel user,
    required int earnedXp,       // XP already counted per-question in QuizViewModel
    required bool isPerfect,     // no wrong answers
    required int correctCount,
  }) async {
    final bonus = _xpBonusLessonComplete;
    final totalXp = earnedXp + bonus;
    final newXp = user.xp + totalXp;
    final newGems = user.gems + _gemsPerLesson;
    final newLeagueXp = user.leagueXpThisWeek + totalXp;

    final streak = UpdateStreakUseCase.calculate(
      lastPracticeDate: user.lastPracticeDate,
      currentStreak: user.currentStreak,
      longestStreak: user.longestStreak,
    );

    await _ds.updateUser(user.uid, {
      'xp': newXp,
      'gems': newGems,
      'currentStreak': streak.currentStreak,
      'longestStreak': streak.longestStreak,
      'lastPracticeDate': streak.lastPracticeDate,
      'leagueXpThisWeek': newLeagueXp,
    });

    await _checkAchievements(
      uid: user.uid,
      newXp: newXp,
      newStreak: streak.currentStreak,
      isPerfect: isPerfect,
      isFirstLesson: user.xp == 0,
    );
  }

  Future<void> decrementHeart(UserModel user) async {
    final newHearts = (user.hearts - 1).clamp(0, 5);
    await _ds.updateUser(user.uid, {'hearts': newHearts});
  }

  Future<void> regenHearts(UserModel user) async {
    if (user.hearts >= 5) return;
    await _ds.updateUser(user.uid, {'hearts': 5});
  }

  Future<void> _checkAchievements({
    required String uid,
    required int newXp,
    required int newStreak,
    required bool isPerfect,
    required bool isFirstLesson,
  }) async {
    final toUnlock = <String>[];

    if (isFirstLesson) toUnlock.add('first_lesson');
    if (isPerfect) toUnlock.add('perfect_quiz');
    if (newStreak >= 3) toUnlock.add('streak_3');
    if (newStreak >= 7) toUnlock.add('streak_7');
    if (newStreak >= 30) toUnlock.add('streak_30');
    if (newXp >= 500) toUnlock.add('xp_500');
    if (newXp >= 1000) toUnlock.add('xp_1000');

    for (final id in toUnlock) {
      await _ds.unlockAchievement(uid, id);
    }
  }
}

final gamificationRepositoryProvider = Provider<GamificationRepository>((ref) {
  return GamificationRepository(ref.read(firestoreDataSourceProvider));
});

// Stream of unlocked achievement IDs for current user
final unlockedAchievementsProvider = StreamProvider<List<String>>((ref) {
  final uid = ref.watch(firebaseAuthProvider).currentUser?.uid;
  if (uid == null) return Stream.value([]);
  return ref.watch(firestoreDataSourceProvider).watchUnlockedAchievementIds(uid);
});
