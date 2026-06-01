import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../data/models/achievement_model.dart';

class AchievementBadge extends StatelessWidget {
  const AchievementBadge({
    super.key,
    required this.model,
    this.size = 64,
  });

  final AchievementModel model;
  final double size;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showDetail(context),
      child: Opacity(
        opacity: model.isUnlocked ? 1.0 : 0.45,
        child: ColorFiltered(
          colorFilter: model.isUnlocked
              ? const ColorFilter.mode(Colors.transparent, BlendMode.multiply)
              : const ColorFilter.matrix([
                  0.2126, 0.7152, 0.0722, 0, 0,
                  0.2126, 0.7152, 0.0722, 0, 0,
                  0.2126, 0.7152, 0.0722, 0, 0,
                  0, 0, 0, 1, 0,
                ]),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: model.isUnlocked ? AppColors.goldLight : AppColors.lockedBackground,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: model.isUnlocked ? AppColors.gold : AppColors.locked,
                    width: 2.5,
                  ),
                ),
                child: Icon(
                  model.isUnlocked ? model.definition.icon : Icons.lock_rounded,
                  color: model.isUnlocked ? AppColors.gold : AppColors.locked,
                  size: size * 0.42,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                model.definition.label,
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: model.isUnlocked ? FontWeight.w600 : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: model.isUnlocked ? AppColors.goldLight : AppColors.lockedBackground,
                shape: BoxShape.circle,
                border: Border.all(
                  color: model.isUnlocked ? AppColors.gold : AppColors.locked,
                  width: 3,
                ),
              ),
              child: Icon(
                model.isUnlocked ? model.definition.icon : Icons.lock_rounded,
                color: model.isUnlocked ? AppColors.gold : AppColors.locked,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            Text(model.definition.label, style: AppTypography.headlineMedium),
            const SizedBox(height: 8),
            Text(
              model.definition.description,
              style: AppTypography.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            if (model.isUnlocked && model.unlockedAt != null) ...[
              const SizedBox(height: 4),
              Text(
                'Terbuka pada ${_formatDate(model.unlockedAt!)}',
                style: AppTypography.bodySmall.copyWith(color: AppColors.gold),
              ),
            ] else if (!model.isUnlocked) ...[
              const SizedBox(height: 4),
              Text(
                'Belum terbuka',
                style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
}
