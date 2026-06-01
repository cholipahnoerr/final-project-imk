import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../common_widgets/primary_button.dart';

class PlacementResultScreen extends StatelessWidget {
  const PlacementResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🎉', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 24),
              Text('Hasilmu!', style: AppTypography.displayLarge, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.gold.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.gold, width: 2),
                ),
                child: Text(
                  'Level Menengah',
                  style: AppTypography.headlineLarge.copyWith(color: AppColors.gold),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Kamu sudah mengenal banyak kosakata dasar!\nMulai dari unit yang sesuai.',
                style: AppTypography.bodyLarge.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              PrimaryButton(
                label: 'Mulai Belajar',
                onPressed: () => context.go('/onboarding/daily-target'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}