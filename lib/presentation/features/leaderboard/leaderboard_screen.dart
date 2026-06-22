import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../data/models/leaderboard_entry_model.dart';
import '../../common_widgets/leaderboard_row.dart';
import '../home/home_viewmodel.dart';
import 'leaderboard_viewmodel.dart';

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  static const Map<League, List<Color>> _leagueGradients = {
    League.bronze:  [Color(0xFFCD7F32), Color(0xFF8B4513)],
    League.silver:  [Color(0xFFB0B0B0), Color(0xFF6A6A6A)],
    League.gold:    [Color(0xFFFFD700), Color(0xFFC8960C)],
    League.diamond: [Color(0xFF74E4F3), Color(0xFF1A6EBE)],
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboardAsync = ref.watch(leaderboardProvider);
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 80,
        leading: userAsync.when(
          data: (user) => Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.local_fire_department_rounded, color: AppColors.streak, size: 22),
              const SizedBox(width: 3),
              Text('${user?.currentStreak ?? 0}',
                  style: AppTypography.titleMedium
                      .copyWith(color: AppColors.streak, fontWeight: FontWeight.w800)),
            ]),
          ),
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const SizedBox.shrink(),
        ),
        title: Text('Papan Peringkat',
            style: AppTypography.titleLarge
                .copyWith(color: AppColors.primary, fontWeight: FontWeight.w800)),
        centerTitle: true,
        actions: [
          userAsync.when(
            data: (user) => Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text('${user?.gems ?? 0}',
                    style: AppTypography.titleMedium
                        .copyWith(color: AppColors.gems, fontWeight: FontWeight.w800)),
                const SizedBox(width: 3),
                Icon(Icons.diamond_rounded, color: AppColors.gems, size: 20),
              ]),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: leaderboardAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (_, _) => Center(
          child: Text('Gagal memuat papan peringkat',
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.textSecondary)),
        ),
        data: (state) => _LeaderboardBody(
          state: state,
          gradients: _leagueGradients,
        ),
      ),
    );
  }
}

class _LeaderboardBody extends StatelessWidget {
  const _LeaderboardBody({required this.state, required this.gradients});
  final LeaderboardState state;
  final Map<League, List<Color>> gradients;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _LeagueBanner(state: state, gradients: gradients),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Icon(Icons.schedule_rounded,
                  size: 16, color: AppColors.textMuted),
              const SizedBox(width: 6),
              Text(
                'Reset setiap Senin — ${state.entries.length} peserta di liga ini',
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.textMuted),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: state.entries.isEmpty
              ? _EmptyLeague(league: state.league)
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: state.entries.length,
                  itemBuilder: (context, index) => LeaderboardRow(
                    rank: index + 1,
                    entry: state.entries[index],
                  ),
                ),
        ),
        if (state.xpToPromotion > 0)
          _PromotionBanner(
            xpNeeded: state.xpToPromotion,
            nextLeague: state.league.next.labelId,
          ),
      ],
    );
  }
}

class _EmptyLeague extends StatelessWidget {
  const _EmptyLeague({required this.league});
  final League league;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(league.emoji, style: const TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          Text('Jadilah yang pertama!',
              style: AppTypography.titleMedium
                  .copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Text('Belum ada peserta di ${league.labelId} minggu ini',
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.textMuted),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _LeagueBanner extends StatelessWidget {
  const _LeagueBanner({required this.state, required this.gradients});
  final LeaderboardState state;
  final Map<League, List<Color>> gradients;

  @override
  Widget build(BuildContext context) {
    final colors = gradients[state.league]!;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(state.league.emoji,
              style: const TextStyle(fontSize: 48)),
          const SizedBox(height: 4),
          Text(state.league.labelId,
              style: AppTypography.headlineLarge
                  .copyWith(color: Colors.white)),
          const SizedBox(height: 4),
          Text(
            state.currentUserRank > 0
                ? 'Peringkatmu: #${state.currentUserRank} dari ${state.entries.length}'
                : 'Mulai belajar untuk masuk peringkat!',
            style: AppTypography.bodyMedium
                .copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              state.league.promotionText,
              style: AppTypography.bodySmall
                  .copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _PromotionBanner extends StatelessWidget {
  const _PromotionBanner(
      {required this.xpNeeded, required this.nextLeague});
  final int xpNeeded;
  final String nextLeague;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        border: Border(
            top: BorderSide(
                color: AppColors.primary.withValues(alpha: 0.2))),
      ),
      child: Row(
        children: [
          const Icon(Icons.trending_up_rounded,
              color: AppColors.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Butuh $xpNeeded XP lagi untuk naik ke $nextLeague',
              style: AppTypography.bodySmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
