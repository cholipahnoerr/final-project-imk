import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../data/models/achievement_model.dart';
import '../../../data/models/leaderboard_entry_model.dart';
import '../../../data/repositories/gamification_repository.dart';
import '../../common_widgets/achievement_badge.dart';
import '../home/home_viewmodel.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final unlockedIds = ref.watch(unlockedAchievementsProvider).valueOrNull ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profil'),
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/profile/settings'),
          ),
        ],
      ),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (user) {
          final league = LeagueExtension.fromString(user?.currentLeague ?? 'bronze');
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar + name card
                Center(
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 48,
                            backgroundColor: AppColors.surfaceVariant,
                            backgroundImage: user?.photoUrl != null
                                ? CachedNetworkImageProvider(user!.photoUrl!)
                                : null,
                            child: user?.photoUrl == null
                                ? Text(
                                    (user?.displayName.isNotEmpty == true)
                                        ? user!.displayName[0].toUpperCase()
                                        : '?',
                                    style: AppTypography.displayLarge.copyWith(color: AppColors.primary),
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                league.emoji,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(user?.displayName ?? 'Nama Pengguna', style: AppTypography.headlineLarge),
                      Text(
                        user?.email ?? '',
                        style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          league.labelId,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 400.ms),

                const SizedBox(height: 24),

                // Primary stats
                Row(
                  children: [
                    _StatCard(
                      value: '${user?.currentStreak ?? 0}',
                      label: 'Streak',
                      icon: Icons.local_fire_department_rounded,
                      color: AppColors.streak,
                    ),
                    const SizedBox(width: 10),
                    _StatCard(
                      value: _formatXp(user?.xp ?? 0),
                      label: 'Total XP',
                      icon: Icons.bolt_rounded,
                      color: AppColors.gold,
                    ),
                    const SizedBox(width: 10),
                    _StatCard(
                      value: '${user?.gems ?? 0}',
                      label: 'Gems',
                      icon: Icons.diamond_rounded,
                      color: AppColors.gems,
                    ),
                  ],
                ).animate().fadeIn(delay: 100.ms, duration: 400.ms),

                const SizedBox(height: 10),

                // Secondary stats
                Row(
                  children: [
                    _StatCard(
                      value: '${user?.hearts ?? 5}/5',
                      label: 'Nyawa',
                      icon: Icons.favorite_rounded,
                      color: AppColors.hearts,
                    ),
                    const SizedBox(width: 10),
                    _StatCard(
                      value: '${user?.longestStreak ?? 0}',
                      label: 'Streak Terbaik',
                      icon: Icons.emoji_events_rounded,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 10),
                    _StatCard(
                      value: '${user?.leagueXpThisWeek ?? 0}',
                      label: 'XP Minggu Ini',
                      icon: Icons.calendar_today_rounded,
                      color: AppColors.gems,
                    ),
                  ],
                ).animate().fadeIn(delay: 150.ms, duration: 400.ms),

                const SizedBox(height: 24),

                // Achievement preview
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Pencapaian', style: AppTypography.headlineMedium),
                    TextButton(
                      onPressed: () => context.push('/profile/achievements'),
                      child: Text(
                        'Lihat Semua (${unlockedIds.length}/${kAllAchievements.length})',
                        style: AppTypography.bodyMedium.copyWith(color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                SizedBox(
                  height: 100,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: kAllAchievements.length.clamp(0, 5),
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final def = kAllAchievements[index];
                      final model = AchievementModel(
                        definition: def,
                        unlockedAt: unlockedIds.contains(def.id) ? DateTime.now() : null,
                      );
                      return AchievementBadge(model: model, size: 52);
                    },
                  ),
                ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatXp(int xp) {
    if (xp >= 1000) return '${(xp / 1000).toStringAsFixed(1)}K';
    return '$xp';
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(value, style: AppTypography.headlineMedium.copyWith(color: color)),
            Text(label, style: AppTypography.bodySmall, textAlign: TextAlign.center, maxLines: 2),
          ],
        ),
      ),
    );
  }
}
