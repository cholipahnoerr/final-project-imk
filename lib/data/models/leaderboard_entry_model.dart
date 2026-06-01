enum League { bronze, silver, gold, diamond }

extension LeagueExtension on League {
  String get name => switch (this) {
    League.bronze  => 'Bronze',
    League.silver  => 'Silver',
    League.gold    => 'Gold',
    League.diamond => 'Diamond',
  };

  String get labelId => switch (this) {
    League.bronze  => 'Liga Perunggu',
    League.silver  => 'Liga Perak',
    League.gold    => 'Liga Emas',
    League.diamond => 'Liga Berlian',
  };

  String get emoji => switch (this) {
    League.bronze  => '🥉',
    League.silver  => '🥈',
    League.gold    => '🥇',
    League.diamond => '💎',
  };

  String get promotionText => switch (this) {
    League.bronze  => 'Top 10 naik ke Liga Perak',
    League.silver  => 'Top 10 naik ke Liga Emas',
    League.gold    => 'Top 10 naik ke Liga Berlian',
    League.diamond => 'Pertahankan posisi teratas!',
  };

  League get next => switch (this) {
    League.bronze  => League.silver,
    League.silver  => League.gold,
    League.gold    => League.diamond,
    League.diamond => League.diamond,
  };

  static League fromString(String value) {
    return switch (value.toLowerCase()) {
      'silver'  => League.silver,
      'gold'    => League.gold,
      'diamond' => League.diamond,
      _         => League.bronze,
    };
  }
}

class LeaderboardEntry {
  const LeaderboardEntry({
    required this.uid,
    required this.displayName,
    this.photoUrl,
    required this.xpThisWeek,
    this.isCurrentUser = false,
  });

  final String uid;
  final String displayName;
  final String? photoUrl;
  final int xpThisWeek;
  final bool isCurrentUser;

  factory LeaderboardEntry.fromMap(Map<String, dynamic> map, String uid, {bool isCurrentUser = false}) {
    return LeaderboardEntry(
      uid: uid,
      displayName: map['displayName'] as String? ?? 'Pengguna',
      photoUrl: map['photoUrl'] as String?,
      xpThisWeek: map['leagueXpThisWeek'] as int? ?? 0,
      isCurrentUser: isCurrentUser,
    );
  }
}
