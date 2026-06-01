import 'package:flutter/material.dart';

class AchievementDefinition {
  const AchievementDefinition({
    required this.id,
    required this.label,
    required this.description,
    required this.icon,
    required this.trigger,
  });

  final String id;
  final String label;
  final String description;
  final IconData icon;
  final String trigger; // matches a trigger key fired by GamificationRepository
}

class AchievementModel {
  const AchievementModel({
    required this.definition,
    this.unlockedAt,
  });

  final AchievementDefinition definition;
  final DateTime? unlockedAt;

  bool get isUnlocked => unlockedAt != null;

  factory AchievementModel.fromMap(AchievementDefinition def, Map<String, dynamic> map) {
    final ts = map['unlockedAt'];
    return AchievementModel(
      definition: def,
      unlockedAt: ts != null ? DateTime.fromMillisecondsSinceEpoch(ts as int) : null,
    );
  }
}

// Static achievement registry — single source of truth
const List<AchievementDefinition> kAllAchievements = [
  AchievementDefinition(
    id: 'first_lesson',
    label: 'Langkah Pertama',
    description: 'Selesaikan lesson pertama',
    icon: Icons.star_rounded,
    trigger: 'lesson_complete',
  ),
  AchievementDefinition(
    id: 'perfect_quiz',
    label: 'Sempurna!',
    description: 'Selesaikan kuis tanpa jawaban salah',
    icon: Icons.check_circle_rounded,
    trigger: 'perfect_lesson',
  ),
  AchievementDefinition(
    id: 'streak_3',
    label: '3 Hari Berturut',
    description: 'Belajar 3 hari berturut-turut',
    icon: Icons.local_fire_department_rounded,
    trigger: 'streak_3',
  ),
  AchievementDefinition(
    id: 'streak_7',
    label: '7 Hari Berturut',
    description: 'Belajar 7 hari berturut-turut',
    icon: Icons.whatshot_rounded,
    trigger: 'streak_7',
  ),
  AchievementDefinition(
    id: 'streak_30',
    label: '30 Hari Berturut',
    description: 'Belajar 30 hari berturut-turut',
    icon: Icons.emoji_events_rounded,
    trigger: 'streak_30',
  ),
  AchievementDefinition(
    id: 'xp_500',
    label: 'Rajin Belajar',
    description: 'Kumpulkan 500 XP',
    icon: Icons.bolt_rounded,
    trigger: 'xp_500',
  ),
  AchievementDefinition(
    id: 'xp_1000',
    label: 'Ahli Arab',
    description: 'Kumpulkan 1.000 XP',
    icon: Icons.military_tech_rounded,
    trigger: 'xp_1000',
  ),
  AchievementDefinition(
    id: 'social_butterfly',
    label: 'Kupu-kupu Sosial',
    description: 'Kirim 10 pesan ke partner',
    icon: Icons.chat_bubble_rounded,
    trigger: 'messages_10',
  ),
  AchievementDefinition(
    id: 'league_silver',
    label: 'Naik Liga!',
    description: 'Naik ke Liga Perak',
    icon: Icons.workspace_premium_rounded,
    trigger: 'league_silver',
  ),
];
