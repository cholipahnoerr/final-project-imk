import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/services/auth_service.dart';
import '../../../data/models/leaderboard_entry_model.dart';
import '../../../data/models/user_model.dart';
import '../../common_widgets/primary_button.dart';

final _friendUserProvider =
    FutureProvider.autoDispose.family<UserModel?, String>((ref, userId) {
  return ref.read(firestoreDataSourceProvider).getUser(userId);
});

class FriendProfileScreen extends ConsumerWidget {
  const FriendProfileScreen({super.key, required this.userId});
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(_friendUserProvider(userId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
                color: AppColors.surfaceVariant, shape: BoxShape.circle),
            child: const Icon(Icons.arrow_back_rounded,
                color: AppColors.textPrimary, size: 20),
          ),
          onPressed: () => context.pop(),
        ),
        title: Text('Profil Teman',
            style: AppTypography.titleLarge.copyWith(
                color: AppColors.primary, fontWeight: FontWeight.w800)),
        centerTitle: true,
      ),
      body: userAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(
          child: Text('Gagal memuat profil',
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.textSecondary)),
        ),
        data: (user) {
          if (user == null) {
            return Center(
              child: Text('Pengguna tidak ditemukan',
                  style: AppTypography.bodyMedium
                      .copyWith(color: AppColors.textSecondary)),
            );
          }
          return _FriendProfileBody(user: user);
        },
      ),
    );
  }
}

class _FriendProfileBody extends StatelessWidget {
  const _FriendProfileBody({required this.user});
  final UserModel user;

  @override
  Widget build(BuildContext context) {
    final league = LeagueExtension.fromString(user.currentLeague);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      child: Column(
        children: [
          // Avatar
          CircleAvatar(
            radius: 52,
            backgroundColor: AppColors.surfaceVariant,
            child: Text(
              user.displayName.isNotEmpty
                  ? user.displayName[0].toUpperCase()
                  : '?',
              style:
                  AppTypography.displayLarge.copyWith(color: AppColors.primary),
            ),
          ),
          const SizedBox(height: 14),

          // Name & handle
          Text(
            user.displayName.isNotEmpty ? user.displayName : 'Pengguna',
            style: AppTypography.headlineLarge
                .copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            user.handle,
            style: AppTypography.bodyMedium
                .copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),

          // League badge
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${league.emoji} ${league.labelId}',
              style: AppTypography.bodySmall.copyWith(
                  color: AppColors.primary, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 24),

          // Stats row
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  icon: Icons.local_fire_department_rounded,
                  color: AppColors.streak,
                  value: '${user.currentStreak}',
                  label: 'Streak',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniStat(
                  icon: Icons.bolt_rounded,
                  color: AppColors.gold,
                  value: _formatXp(user.xp),
                  label: 'Total XP',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniStat(
                  icon: Icons.menu_book_rounded,
                  color: AppColors.gems,
                  value: '${user.wordsLearned}',
                  label: 'Kata',
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // CTA
          PrimaryButton(
            label: 'Kirim Pesan',
            onPressed: () {
              context.pop();
              context.push(
                '/talk/chat/${user.uid}',
                extra: {'partnerName': user.displayName},
              );
            },
            icon: Icons.chat_bubble_outline_rounded,
          ),
        ],
      ),
    );
  }

  String _formatXp(int xp) {
    if (xp >= 1000) return '${(xp / 1000).toStringAsFixed(1)}K';
    return '$xp';
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(value,
              style: AppTypography.titleLarge
                  .copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label,
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
