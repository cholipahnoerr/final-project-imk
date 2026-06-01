import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../common_widgets/primary_button.dart';

class DailyQuestModal extends StatelessWidget {
  const DailyQuestModal({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black54,
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🎁', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 12),
              Text('Hadiah Harian!', style: AppTypography.displayMedium, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(
                'Selesaikan quest harian dan dapatkan hadiah spesial.',
                style: AppTypography.bodyLarge.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              _QuestItem(
                label: 'Selesaikan 1 Lesson',
                progress: 1,
                total: 1,
                reward: '+20 Gems',
                done: true,
              ),
              const SizedBox(height: 12),
              _QuestItem(
                label: 'Pelajari 5 Kata Baru',
                progress: 3,
                total: 5,
                reward: '+10 Gems',
                done: false,
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: 'Klaim Hadiah 🎉',
                onPressed: () {
                  // TODO: Claim via GamificationViewModel
                  context.pop();
                },
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => context.pop(),
                child: Text('Nanti Saja', style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuestItem extends StatelessWidget {
  const _QuestItem({required this.label, required this.progress, required this.total, required this.reward, required this.done});
  final String label;
  final int progress;
  final int total;
  final String reward;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(done ? Icons.check_circle : Icons.radio_button_unchecked, color: done ? AppColors.success : AppColors.textMuted),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTypography.bodyMedium),
              LinearProgressIndicator(
                value: progress / total,
                backgroundColor: AppColors.surfaceVariant,
                color: done ? AppColors.success : AppColors.primary,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(reward, style: AppTypography.bodySmall.copyWith(color: AppColors.gems, fontWeight: FontWeight.w700)),
      ],
    );
  }
}