import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../common_widgets/primary_button.dart';

class LessonCompleteScreen extends StatelessWidget {
  const LessonCompleteScreen({
    super.key,
    this.earnedXp = 0,
    this.stars = 1,
    this.correctCount = 0,
    this.totalCount = 0,
  });

  final int earnedXp;
  final int stars;
  final int correctCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    final accuracy = totalCount > 0 ? (correctCount / totalCount * 100).round() : 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Mascot animation — uses network Lottie for demo; swap to asset in production
              SizedBox(
                width: 160,
                height: 160,
                child: Lottie.network(
                  'https://assets5.lottiefiles.com/packages/lf20_touohxv0.json',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Text('🐪', style: TextStyle(fontSize: 80)),
                  ),
                ),
              ).animate().fadeIn(duration: 500.ms).scaleXY(begin: 0.7, end: 1, duration: 500.ms, curve: Curves.elasticOut),

              const SizedBox(height: 16),

              Text(
                stars == 3 ? 'Luar Biasa!' : stars == 2 ? 'Bagus Sekali!' : 'Tetap Semangat!',
                style: AppTypography.displayLarge,
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 300.ms, duration: 400.ms).slideY(begin: 0.3, end: 0),

              const SizedBox(height: 6),

              Text(
                'Lesson selesai!',
                style: AppTypography.bodyLarge.copyWith(color: AppColors.textSecondary),
              ).animate().fadeIn(delay: 400.ms, duration: 400.ms),

              const SizedBox(height: 28),

              // Star rating
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) {
                  final filled = i < stars;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(
                      filled ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: filled ? AppColors.gold : AppColors.border,
                      size: 48,
                    ).animate(delay: Duration(milliseconds: 500 + i * 120))
                     .fadeIn(duration: 300.ms)
                     .scaleXY(begin: 0, end: 1, curve: Curves.elasticOut, duration: 400.ms),
                  );
                }),
              ),

              const SizedBox(height: 32),

              // Stats row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _ResultStat(icon: Icons.bolt_rounded, color: AppColors.gold, value: '+$earnedXp', label: 'XP'),
                  _ResultStat(icon: Icons.check_circle_rounded, color: AppColors.success, value: '$correctCount/$totalCount', label: 'Benar'),
                  _ResultStat(icon: Icons.percent_rounded, color: AppColors.primary, value: '$accuracy%', label: 'Akurasi'),
                ],
              ).animate().fadeIn(delay: 900.ms, duration: 400.ms).slideY(begin: 0.2, end: 0),

              const Spacer(),

              PrimaryButton(
                label: 'Lanjutkan',
                onPressed: () => context.go('/home'),
              ).animate().fadeIn(delay: 1100.ms, duration: 400.ms),

              const SizedBox(height: 12),

              TextButton(
                onPressed: () => context.go('/home'),
                child: Text(
                  'Kembali ke Beranda',
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                ),
              ).animate().fadeIn(delay: 1200.ms, duration: 400.ms),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultStat extends StatelessWidget {
  const _ResultStat({required this.icon, required this.color, required this.value, required this.label});
  final IconData icon;
  final Color color;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 8),
        Text(value, style: AppTypography.headlineLarge.copyWith(color: color)),
        Text(label, style: AppTypography.bodySmall),
      ],
    );
  }
}
