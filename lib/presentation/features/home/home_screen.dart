import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../data/models/learning_path_model.dart';
import 'home_viewmodel.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final units = ref.watch(learningPathProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            snap: true,
            backgroundColor: AppColors.background,
            titleSpacing: 16,
            title: userAsync.when(
              data: (user) => Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.primaryLight,
                    backgroundImage:
                        user?.photoUrl != null ? NetworkImage(user!.photoUrl!) : null,
                    child: user?.photoUrl == null
                        ? const Icon(Icons.person, size: 20, color: AppColors.textOnPrimary)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Halo, ${user?.displayName.split(' ').first ?? 'Pelajar'}!',
                        style: AppTypography.titleMedium,
                      ),
                      Text('Ayo belajar hari ini', style: AppTypography.bodySmall),
                    ],
                  ),
                ],
              ),
              loading: () => const SizedBox(width: 120, height: 20),
              error: (_, __) => const Text('Hayyarabic'),
            ),
            actions: [
              userAsync.when(
                data: (user) => Row(
                  children: [
                    _StatChip(Icons.favorite, '${user?.hearts ?? 5}', AppColors.hearts),
                    const SizedBox(width: 8),
                    _StatChip(Icons.local_fire_department, '${user?.currentStreak ?? 0}', AppColors.streak),
                    const SizedBox(width: 8),
                    _StatChip(Icons.diamond_outlined, '${user?.gems ?? 0}', AppColors.gems),
                    const SizedBox(width: 16),
                  ],
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _UnitSection(unit: units[index]),
                childCount: units.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip(this.icon, this.value, this.color);
  final IconData icon;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 3),
        Text(value, style: AppTypography.titleMedium.copyWith(color: color)),
      ],
    );
  }
}

class _UnitSection extends StatelessWidget {
  const _UnitSection({required this.unit});
  final LearningUnit unit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: unit.isUnlocked ? AppColors.primary : AppColors.locked,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(unit.title, style: AppTypography.bodySmall.copyWith(color: Colors.white70)),
              Text(unit.description, style: AppTypography.titleLarge.copyWith(color: Colors.white)),
            ],
          ),
        ),
        _LearningPathNodes(unit: unit),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _LearningPathNodes extends StatelessWidget {
  const _LearningPathNodes({required this.unit});
  final LearningUnit unit;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(unit.nodes.length, (i) {
        final node = unit.nodes[i];
        // Alternate left/right for snake layout
        final offsetLeft = i % 2 == 0 ? 0.0 : 80.0;
        final offsetRight = i % 2 == 0 ? 80.0 : 0.0;

        return Padding(
          padding: EdgeInsets.only(left: offsetLeft, right: offsetRight, bottom: 12),
          child: _NodeButton(node: node, unitId: unit.id),
        );
      }),
    );
  }
}

class _NodeButton extends StatelessWidget {
  const _NodeButton({required this.node, required this.unitId});
  final LessonNode node;
  final String unitId;

  @override
  Widget build(BuildContext context) {
    final isActive = node.state == NodeState.active;
    final isCompleted = node.state == NodeState.completed;
    final isLocked = node.state == NodeState.locked;

    Color bgColor;
    Color borderColor;
    Color iconColor = Colors.white;

    if (isCompleted) {
      bgColor = AppColors.success;
      borderColor = AppColors.success;
    } else if (isActive) {
      bgColor = AppColors.primary;
      borderColor = AppColors.primaryDark;
    } else {
      bgColor = AppColors.lockedBackground;
      borderColor = AppColors.locked;
      iconColor = AppColors.locked;
    }

    return GestureDetector(
      onTap: isActive
          ? () => context.push('/home/lesson/$unitId/${node.id}')
          : null,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: bgColor,
          border: Border.all(color: borderColor, width: 3),
          boxShadow: isActive
              ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.35), blurRadius: 14, offset: const Offset(0, 5))]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isCompleted ? Icons.star_rounded : isLocked ? Icons.lock : Icons.play_arrow_rounded,
              color: iconColor,
              size: 28,
            ),
            if (isCompleted && node.stars > 0)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  node.stars,
                  (_) => const Icon(Icons.star, color: AppColors.gold, size: 10),
                ),
              ),
          ],
        ),
      ),
    );
  }
}