import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../common_widgets/primary_button.dart';
import 'onboarding_viewmodel.dart';

class DailyTargetScreen extends ConsumerWidget {
  const DailyTargetScreen({super.key});

  static const List<_TargetOption> _targets = [
    _TargetOption(minutes: 5, label: 'Santai', description: '5 menit/hari', emoji: '🌙'),
    _TargetOption(minutes: 10, label: 'Reguler', description: '10 menit/hari', emoji: '🎯'),
    _TargetOption(minutes: 15, label: 'Serius', description: '15 menit/hari', emoji: '💪'),
    _TargetOption(minutes: 20, label: 'Intensif', description: '20 menit/hari', emoji: '🔥'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingViewModelProvider);
    final vm = ref.read(onboardingViewModelProvider.notifier);

    ref.listen(onboardingViewModelProvider, (_, next) {
      if (next.isCompleted) context.go('/home');
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!), backgroundColor: AppColors.error),
        );
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text('Berapa target\nbelajar harianmu?', style: AppTypography.displayMedium),
              const SizedBox(height: 8),
              Text(
                'Konsistensi kecil lebih baik daripada belajar besar tapi jarang.',
                style: AppTypography.bodyLarge.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: ListView.separated(
                  itemCount: _targets.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final target = _targets[index];
                    final isSelected = state.dailyTargetMinutes == target.minutes;
                    return GestureDetector(
                      onTap: () => vm.setDailyTarget(target.minutes),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withValues(alpha: 0.08)
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : AppColors.border,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(target.emoji, style: const TextStyle(fontSize: 32)),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(target.label, style: AppTypography.titleLarge),
                                  Text(target.description, style: AppTypography.bodySmall),
                                ],
                              ),
                            ),
                            if (isSelected)
                              const Icon(Icons.check_circle, color: AppColors.primary),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                label: 'Mulai Belajar! 🚀',
                isLoading: state.isLoading,
                onPressed: state.isLoading ? null : vm.completeOnboarding,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TargetOption {
  const _TargetOption({
    required this.minutes,
    required this.label,
    required this.description,
    required this.emoji,
  });
  final int minutes;
  final String label;
  final String description;
  final String emoji;
}