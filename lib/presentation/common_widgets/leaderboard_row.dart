import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../data/models/leaderboard_entry_model.dart';

class LeaderboardRow extends StatelessWidget {
  const LeaderboardRow({
    super.key,
    required this.rank,
    required this.entry,
  });

  final int rank;
  final LeaderboardEntry entry;

  @override
  Widget build(BuildContext context) {
    final isTop3 = rank <= 3;
    final medalEmoji = isTop3 ? ['🥇', '🥈', '🥉'][rank - 1] : '';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: entry.isCurrentUser
            ? AppColors.primary.withValues(alpha: 0.08)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border(
          left: BorderSide(
            color: entry.isCurrentUser ? AppColors.primary : Colors.transparent,
            width: 4,
          ),
        ),
        boxShadow: entry.isCurrentUser
            ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.1), blurRadius: 8, spreadRadius: 1)]
            : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(
              isTop3 ? medalEmoji : '$rank',
              style: isTop3
                  ? const TextStyle(fontSize: 22)
                  : AppTypography.titleLarge.copyWith(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            radius: 20,
            backgroundColor: entry.isCurrentUser ? AppColors.primary : AppColors.surfaceVariant,
            child: Text(
              entry.displayName.isNotEmpty ? entry.displayName[0].toUpperCase() : '?',
              style: AppTypography.titleMedium.copyWith(
                color: entry.isCurrentUser ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.isCurrentUser ? '${entry.displayName} (Kamu)' : entry.displayName,
                  style: AppTypography.titleMedium.copyWith(
                    color: entry.isCurrentUser ? AppColors.primary : AppColors.textPrimary,
                    fontWeight: entry.isCurrentUser ? FontWeight.w800 : FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Row(
            children: [
              const Icon(Icons.bolt_rounded, color: AppColors.gold, size: 18),
              const SizedBox(width: 2),
              Text(
                '${entry.xpThisWeek} XP',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.gold,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
