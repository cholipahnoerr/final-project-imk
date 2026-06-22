import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/auth_service.dart';
import '../../../data/models/leaderboard_entry_model.dart';
import '../../features/home/home_viewmodel.dart';

class LeaderboardState {
  const LeaderboardState({
    required this.league,
    required this.entries,
    required this.currentUserRank,
    required this.xpToPromotion,
  });

  final League league;
  final List<LeaderboardEntry> entries;
  final int currentUserRank;
  final int xpToPromotion;
}

final leaderboardProvider =
    StreamProvider.autoDispose<LeaderboardState>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  final user = userAsync.valueOrNull;

  if (user == null) {
    return Stream.value(LeaderboardState(
      league: League.bronze,
      entries: const [],
      currentUserRank: 0,
      xpToPromotion: 0,
    ));
  }

  final league = LeagueExtension.fromString(user.currentLeague);

  return ref
      .watch(firestoreDataSourceProvider)
      .watchLeaderboard(user.currentLeague)
      .map((users) {
    final entries = users
        .map((u) => LeaderboardEntry(
              uid: u.uid,
              displayName: u.displayName.isNotEmpty ? u.displayName : 'Pengguna',
              photoUrl: u.photoUrl,
              xpThisWeek: u.leagueXpThisWeek,
              isCurrentUser: u.uid == user.uid,
            ))
        .toList();

    // sort already done in datasource, but ensure consistency
    entries.sort((a, b) => b.xpThisWeek.compareTo(a.xpThisWeek));

    final rankIndex = entries.indexWhere((e) => e.isCurrentUser);
    final currentUserRank = rankIndex >= 0 ? rankIndex + 1 : entries.length + 1;

    final top10Xp =
        entries.length >= 10 ? entries[9].xpThisWeek : 0;
    final xpNeeded =
        (top10Xp - user.leagueXpThisWeek).clamp(0, 99999);

    return LeaderboardState(
      league: league,
      entries: entries,
      currentUserRank: currentUserRank,
      xpToPromotion: xpNeeded,
    );
  });
});
