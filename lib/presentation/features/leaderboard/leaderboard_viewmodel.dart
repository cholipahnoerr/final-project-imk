import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/leaderboard_entry_model.dart';
import '../../../data/models/user_model.dart';
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
  final int xpToPromotion; // XP needed to reach top 10 from current position
}

class LeaderboardViewModel extends Notifier<LeaderboardState> {
  @override
  LeaderboardState build() {
    final user = ref.watch(currentUserProvider).valueOrNull;
    return _computeState(user);
  }

  LeaderboardState _computeState(UserModel? user) {
    final league = LeagueExtension.fromString(user?.currentLeague ?? 'bronze');
    final currentUserXp = user?.leagueXpThisWeek ?? 0;
    final currentUserName = user?.displayName ?? 'Kamu';

    final entries = _generateEntries(currentUserXp, currentUserName, league);
    entries.sort((a, b) => b.xpThisWeek.compareTo(a.xpThisWeek));

    final rank = entries.indexWhere((e) => e.isCurrentUser) + 1;
    final top10Xp = entries.length >= 10 ? entries[9].xpThisWeek : 0;
    final xpNeeded = (top10Xp - currentUserXp).clamp(0, 9999);

    return LeaderboardState(
      league: league,
      entries: entries,
      currentUserRank: rank,
      xpToPromotion: xpNeeded,
    );
  }

  // Generates realistic mock entries with the current user mixed in
  List<LeaderboardEntry> _generateEntries(int userXp, String userName, League league) {
    final baseXp = switch (league) {
      League.bronze  => 800,
      League.silver  => 1500,
      League.gold    => 2500,
      League.diamond => 4000,
    };

    final mockNames = [
      'Ahmad Fauzi', 'Siti Rahayu', 'Budi Santoso', 'Dewi Lestari',
      'Reza Pratama', 'Nurul Hidayah', 'Fajar Kurniawan', 'Indah Permata',
      'Rizky Ramadhan', 'Lena Susanti', 'Dani Wahyudi', 'Mega Putri',
      'Hendra Gunawan', 'Yuli Astuti',
    ];

    final entries = <LeaderboardEntry>[];
    for (int i = 0; i < mockNames.length; i++) {
      entries.add(LeaderboardEntry(
        uid: 'mock_$i',
        displayName: mockNames[i],
        xpThisWeek: baseXp - (i * (baseXp ~/ 15)),
      ));
    }

    entries.add(LeaderboardEntry(
      uid: 'current_user',
      displayName: userName,
      xpThisWeek: userXp,
      isCurrentUser: true,
    ));

    return entries;
  }
}

final leaderboardViewModelProvider =
    NotifierProvider<LeaderboardViewModel, LeaderboardState>(LeaderboardViewModel.new);
