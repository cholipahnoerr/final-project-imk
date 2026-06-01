class UserModel {
  const UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.onboardingCompleted = false,
    this.learningGoal,
    this.proficiencyLevel,
    this.dailyTargetMinutes = 10,
    this.xp = 0,
    this.gems = 0,
    this.hearts = 5,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastPracticeDate,
    this.currentLeague = 'bronze',
    this.leagueXpThisWeek = 0,
  });

  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final bool onboardingCompleted;
  final String? learningGoal;
  final String? proficiencyLevel;
  final int dailyTargetMinutes;
  final int xp;
  final int gems;
  final int hearts;
  final int currentStreak;
  final int longestStreak;
  final String? lastPracticeDate;
  final String currentLeague;
  final int leagueXpThisWeek;

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      email: map['email'] as String? ?? '',
      displayName: map['displayName'] as String? ?? '',
      photoUrl: map['photoUrl'] as String?,
      onboardingCompleted: map['onboardingCompleted'] as bool? ?? false,
      learningGoal: map['learningGoal'] as String?,
      proficiencyLevel: map['proficiencyLevel'] as String?,
      dailyTargetMinutes: map['dailyTargetMinutes'] as int? ?? 10,
      xp: map['xp'] as int? ?? 0,
      gems: map['gems'] as int? ?? 0,
      hearts: map['hearts'] as int? ?? 5,
      currentStreak: map['currentStreak'] as int? ?? 0,
      longestStreak: map['longestStreak'] as int? ?? 0,
      lastPracticeDate: map['lastPracticeDate'] as String?,
      currentLeague: map['currentLeague'] as String? ?? 'bronze',
      leagueXpThisWeek: map['leagueXpThisWeek'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'onboardingCompleted': onboardingCompleted,
      'learningGoal': learningGoal,
      'proficiencyLevel': proficiencyLevel,
      'dailyTargetMinutes': dailyTargetMinutes,
      'xp': xp,
      'gems': gems,
      'hearts': hearts,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lastPracticeDate': lastPracticeDate,
      'currentLeague': currentLeague,
      'leagueXpThisWeek': leagueXpThisWeek,
    };
  }

  UserModel copyWith({
    String? displayName,
    String? photoUrl,
    bool? onboardingCompleted,
    String? learningGoal,
    String? proficiencyLevel,
    int? dailyTargetMinutes,
    int? xp,
    int? gems,
    int? hearts,
    int? currentStreak,
    int? longestStreak,
    String? lastPracticeDate,
    String? currentLeague,
    int? leagueXpThisWeek,
  }) {
    return UserModel(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      learningGoal: learningGoal ?? this.learningGoal,
      proficiencyLevel: proficiencyLevel ?? this.proficiencyLevel,
      dailyTargetMinutes: dailyTargetMinutes ?? this.dailyTargetMinutes,
      xp: xp ?? this.xp,
      gems: gems ?? this.gems,
      hearts: hearts ?? this.hearts,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastPracticeDate: lastPracticeDate ?? this.lastPracticeDate,
      currentLeague: currentLeague ?? this.currentLeague,
      leagueXpThisWeek: leagueXpThisWeek ?? this.leagueXpThisWeek,
    );
  }
}