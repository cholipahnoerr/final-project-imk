import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../common_widgets/primary_button.dart';
import 'onboarding_viewmodel.dart';

class GoalSelectionScreen extends ConsumerWidget {
  const GoalSelectionScreen({super.key});

  static const List<_GoalOption> _goals = [
    _GoalOption(id: 'quran', label: 'Memahami Al-Qur\'an', icon: Icons.book_outlined),
    _GoalOption(id: 'travel', label: 'Perjalanan & Wisata', icon: Icons.flight_outlined),
    _GoalOption(id: 'career', label: 'Karir & Bisnis', icon: Icons.work_outline),
    _GoalOption(id: 'culture', label: 'Budaya & Seni', icon: Icons.palette_outlined),
    _GoalOption(id: 'academic', label: 'Akademik', icon: Icons.school_outlined),
    _GoalOption(id: 'fun', label: 'Hobi & Kesenangan', icon: Icons.star_outline),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingViewModelProvider);
    final vm = ref.read(onboardingViewModelProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _OnboardingHeader(step: 1, total: 3),
              const SizedBox(height: 24),
              Text('Apa tujuan belajarmu?', style: AppTypography.displayMedium),
              const SizedBox(height: 8),
              Text(
                'Pilih satu atau lebih untuk menyesuaikan pengalaman belajarmu.',
                style: AppTypography.bodyLarge.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.1,
                  ),
                  itemCount: _goals.length,
                  itemBuilder: (context, index) {
                    final goal = _goals[index];
                    final isSelected = state.selectedGoals.contains(goal.id);
                    return GestureDetector(
                      onTap: () => vm.toggleGoal(goal.id),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withValues(alpha: 0.1)
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : AppColors.border,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              goal.icon,
                              size: 36,
                              color: isSelected ? AppColors.primary : AppColors.textSecondary,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              goal.label,
                              style: AppTypography.bodyMedium.copyWith(
                                color: isSelected ? AppColors.primary : AppColors.textPrimary,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                label: 'Lanjut',
                onPressed: state.selectedGoals.isEmpty
                    ? null
                    : () => context.push('/onboarding/level'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoalOption {
  const _GoalOption({required this.id, required this.label, required this.icon});
  final String id;
  final String label;
  final IconData icon;
}

class _OnboardingHeader extends StatelessWidget {
  const _OnboardingHeader({required this.step, required this.total});
  final int step;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            if (step > 1)
              GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: AppColors.surfaceVariant, shape: BoxShape.circle),
                  child: const Icon(Icons.arrow_back_rounded, size: 20),
                ),
              )
            else
              const SizedBox(width: 32),
            const Spacer(),
            Image.asset('assets/images/large_logo.png', height: 32),
            const Spacer(),
            Text('$step/$total', style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary)),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: step / total,
            minHeight: 6,
            backgroundColor: AppColors.divider,
            valueColor: AlwaysStoppedAnimation(AppColors.primary),
          ),
        ),
      ],
    );
  }
}
