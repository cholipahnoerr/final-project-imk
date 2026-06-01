import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../common_widgets/primary_button.dart';

class FriendProfileScreen extends StatelessWidget {
  const FriendProfileScreen({super.key, required this.userId});
  final String userId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Profil Teman')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 48,
              backgroundColor: AppColors.surfaceVariant,
              child: Icon(Icons.person, size: 48, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            Text('Partner Belajar', style: AppTypography.headlineLarge),
            Text('Level Menengah', style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.local_fire_department, color: AppColors.streak, size: 20),
                const SizedBox(width: 4),
                Text('Streak 12 hari', style: AppTypography.bodyMedium),
              ],
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Kirim Pesan',
              onPressed: () {
                context.pop();
                context.push('/talk/chat/$userId');
              },
              icon: Icons.chat_bubble_outline,
            ),
          ],
        ),
      ),
    );
  }
}