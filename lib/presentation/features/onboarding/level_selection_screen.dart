import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../common_widgets/primary_button.dart';
import 'onboarding_viewmodel.dart';

class LevelSelectionScreen extends ConsumerStatefulWidget {
  const LevelSelectionScreen({super.key});

  @override
  ConsumerState<LevelSelectionScreen> createState() => _LevelSelectionScreenState();
}

class _LevelSelectionScreenState extends ConsumerState<LevelSelectionScreen> {
  String? _selectedLevel;

  static const List<_LevelOption> _levels = [
    _LevelOption(id: 'beginner', label: 'Pemula', description: 'Belum pernah belajar bahasa Arab', icon: '🌱'),
    _LevelOption(id: 'elementary', label: 'Dasar', description: 'Tahu beberapa kata dan frasa', icon: '🌿'),
    _LevelOption(id: 'intermediate', label: 'Menengah', description: 'Bisa percakapan sederhana', icon: '🌳'),
    _LevelOption(id: 'advanced', label: 'Lanjutan', description: 'Fasih berbicara dan membaca', icon: '🏆'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _OnboardingHeader(step: 2, total: 3),
              const SizedBox(height: 24),
              Text('Seberapa lancar bahasa Arabmu?', style: AppTypography.displayMedium),
              const SizedBox(height: 8),
              Text(
                'Pilih level atau ikuti tes penempatan untuk hasil yang lebih akurat.',
                style: AppTypography.bodyLarge.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.separated(
                  itemCount: _levels.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final level = _levels[index];
                    final isSelected = _selectedLevel == level.id;
                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedLevel = level.id);
                        ref.read(onboardingViewModelProvider.notifier).setLevel(level.id);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary.withValues(alpha: 0.08) : AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : AppColors.border,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(level.icon, style: const TextStyle(fontSize: 28)),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    level.label,
                                    style: AppTypography.titleLarge.copyWith(
                                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(level.description, style: AppTypography.bodySmall),
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
              const SizedBox(height: 12),
              PrimaryButton(
                label: 'Lanjut',
                onPressed: _selectedLevel == null
                    ? null
                    : () => context.push('/onboarding/daily-target'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.push('/onboarding/placement-test'),
                child: SizedBox(
                  width: double.infinity,
                  child: Text(
                    'Ikuti Tes Penempatan',
                    textAlign: TextAlign.center,
                    style: AppTypography.labelLarge.copyWith(color: AppColors.textSecondary),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LevelOption {
  const _LevelOption({required this.id, required this.label, required this.description, required this.icon});
  final String id;
  final String label;
  final String description;
  final String icon;
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
