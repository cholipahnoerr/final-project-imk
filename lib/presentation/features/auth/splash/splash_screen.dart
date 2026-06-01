import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/services/auth_service.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user == null) {
      context.go('/auth/login');
      return;
    }

    try {
      final userData = await ref.read(firestoreDataSourceProvider).getUser(user.uid);
      if (!mounted) return;
      if (userData == null || !userData.onboardingCompleted) {
        context.go('/onboarding/goals');
      } else {
        context.go('/home');
      }
    } catch (_) {
      if (mounted) context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // TODO: Replace with actual logo asset from Figma
            const Icon(Icons.language, size: 80, color: Colors.white),
            const SizedBox(height: 16),
            Text(
              'حَيَّ عَرَبِيك',
              style: AppTypography.displayLarge.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              'Hayyarabic',
              style: AppTypography.headlineMedium.copyWith(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}