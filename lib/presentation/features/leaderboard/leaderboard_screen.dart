import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../data/models/leaderboard_entry_model.dart';
import '../../common_widgets/leaderboard_row.dart';
import '../../common_widgets/offline_banner.dart';
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
    final state = ref.watch(leaderboardViewModelProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Peringkat'),
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        actions: [const Padding(padding: EdgeInsets.only(right: 12), child: OfflineChip())],
      ),
      body: OfflineAwareBody(
        child: Column(
          children: [
            _LeagueBanner(state: state, gradients: _leagueGradients),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.schedule_rounded, size: 16, color: AppColors.textMuted),
                  const SizedBox(width: 6),
                  Text(
                    'Reset setiap Senin — ${state.entries.length} peserta di liga ini',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: state.entries.length,
                itemBuilder: (context, index) {
                  return LeaderboardRow(rank: index + 1, entry: state.entries[index]);
                },
              ),
            ),
            if (state.xpToPromotion > 0)
              _PromotionBanner(
                xpNeeded: state.xpToPromotion,
                nextLeague: state.league.next.labelId,
              ),
          ],
        ),
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
          Text(state.league.emoji, style: const TextStyle(fontSize: 48)),
          const SizedBox(height: 4),
          Text(state.league.labelId, style: AppTypography.headlineLarge.copyWith(color: Colors.white)),
          const SizedBox(height: 4),
          Text(
            'Peringkatmu: #${state.currentUserRank} dari ${state.entries.length}',
            style: AppTypography.bodyMedium.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              state.league.promotionText,
              style: AppTypography.bodySmall.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _PromotionBanner extends StatelessWidget {
  const _PromotionBanner({required this.xpNeeded, required this.nextLeague});
  final int xpNeeded;
  final String nextLeague;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        border: Border(top: BorderSide(color: AppColors.primary.withValues(alpha: 0.2))),
      ),
      child: Row(
        children: [
          const Icon(Icons.trending_up_rounded, color: AppColors.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Butuh $xpNeeded XP lagi untuk naik ke $nextLeague',
              style: AppTypography.bodySmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
