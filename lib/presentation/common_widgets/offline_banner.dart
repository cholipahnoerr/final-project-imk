import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../core/services/connectivity_service.dart';

/// Wraps any screen body and inserts a sliding offline banner when disconnected.
class OfflineAwareBody extends ConsumerWidget {
  const OfflineAwareBody({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnlineAsync = ref.watch(connectivityProvider);

    // If still loading the stream, just show the child (assume online)
    final isOnline = isOnlineAsync.valueOrNull ?? true;

    return Column(
      children: [
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 300),
          crossFadeState: isOnline ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          firstChild: _OfflineBanner(),
          secondChild: const SizedBox.shrink(),
        ),
        Expanded(child: child),
      ],
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppColors.textSecondary,
      child: Row(
        children: [
          const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Tidak ada koneksi internet. Beberapa fitur mungkin tidak tersedia.',
              style: AppTypography.bodySmall.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    ).animate().slideY(begin: -1, end: 0, duration: 300.ms, curve: Curves.easeOut);
  }
}

/// Compact chip version — use inline within existing AppBar or body.
class OfflineChip extends ConsumerWidget {
  const OfflineChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(connectivityProvider).valueOrNull ?? true;
    if (isOnline) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.wifi_off_rounded, size: 13, color: AppColors.error),
          const SizedBox(width: 4),
          Text('Offline', style: AppTypography.bodySmall.copyWith(color: AppColors.error, fontSize: 11)),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}
