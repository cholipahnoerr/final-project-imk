import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../data/models/learning_path_model.dart';
import 'home_viewmodel.dart';

// Dark olive-green for active learning node (matches Figma)
const _kNodeActiveColor = Color(0xFF3D5247);
const _kNodeActiveShadow = Color(0x663D5247);
const _kDashColor = Color(0xFFD4C5B8);

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final unitsAsync = ref.watch(learningPathProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            snap: true,
            backgroundColor: AppColors.background,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            leadingWidth: 80,
            leading: userAsync.when(
              data: (user) => Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.local_fire_department_rounded,
                        color: AppColors.streak, size: 22),
                    const SizedBox(width: 3),
                    Text(
                      '${user?.currentStreak ?? 0}',
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.streak,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
            ),
            title: Text(
              'Beranda',
              style: AppTypography.titleLarge.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
            centerTitle: true,
            actions: [
              userAsync.when(
                data: (user) => Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${user?.gems ?? 0}',
                        style: AppTypography.titleMedium.copyWith(
                          color: AppColors.gems,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Icon(Icons.diamond_rounded,
                          color: AppColors.gems, size: 20),
                    ],
                  ),
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
              ),
            ],
          ),
          unitsAsync.when(
            loading: () => const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
            error: (e, _) => SliverFillRemaining(
              child: Center(
                child: Text(
                  'Gagal memuat pelajaran',
                  style: AppTypography.bodyMedium
                      .copyWith(color: AppColors.textSecondary),
                ),
              ),
            ),
            data: (units) => SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _UnitSection(unit: units[index]),
                  childCount: units.length,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Unit Section ────────────────────────────────────────────────────────────

class _UnitSection extends StatelessWidget {
  const _UnitSection({required this.unit});
  final LearningUnit unit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _UnitHeaderCard(unit: unit),
        const SizedBox(height: 4),
        _LearningPath(unit: unit),
        const SizedBox(height: 24),
      ],
    );
  }
}

// ─── Unit Header Card ────────────────────────────────────────────────────────

class _UnitHeaderCard extends StatelessWidget {
  const _UnitHeaderCard({required this.unit});
  final LearningUnit unit;

  @override
  Widget build(BuildContext context) {
    final color = unit.isUnlocked ? AppColors.primary : AppColors.locked;
    final darkColor = unit.isUnlocked ? AppColors.primaryDark : AppColors.textMuted;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                unit.title,
                style: AppTypography.headlineMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                unit.description,
                style: AppTypography.bodyMedium.copyWith(
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 14),
              _BukuPanduanButton(color: darkColor),
            ],
          ),
          Positioned(
            right: -4,
            top: -4,
            child: Text(
              '文',
              style: TextStyle(
                fontSize: 72,
                color: Colors.white.withValues(alpha: 0.11),
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BukuPanduanButton extends StatelessWidget {
  const _BukuPanduanButton({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/home/guide'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.menu_book_rounded, color: Colors.white, size: 16),
            const SizedBox(width: 6),
            Text(
              'Buku Panduan',
              style: AppTypography.bodyMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Learning Path ────────────────────────────────────────────────────────────

class _LearningPath extends StatelessWidget {
  const _LearningPath({required this.unit});
  final LearningUnit unit;

  @override
  Widget build(BuildContext context) {
    final nodes = unit.nodes;
    final activeIndex = nodes.indexWhere((n) => n.state == NodeState.active);

    final List<Widget> items = [];

    for (int i = 0; i < nodes.length; i++) {
      final node = nodes[i];
      // Alternate center-right → center-left for snake feel
      final alignment =
          i % 2 == 0 ? Alignment.center : Alignment.centerLeft;
      final horizontalPad =
          i % 2 == 0 ? const EdgeInsets.only(left: 40.0) : EdgeInsets.zero;

      final isActiveNode = node.state == NodeState.active;

      Widget nodeWidget = Padding(
        padding: horizontalPad,
        child: _NodeButton(node: node, unitId: unit.id),
      );

      if (isActiveNode) {
        // Mascot bubble to the right of the active node
        nodeWidget = Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Padding(
              padding: horizontalPad,
              child: _NodeButton(node: node, unitId: unit.id),
            ),
            const SizedBox(width: 8),
            const _MascotArea(),
          ],
        );
      }

      items.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Align(alignment: alignment, child: nodeWidget),
        ),
      );

      // Gift bonus appears after the first active node
      if (i == activeIndex) {
        items.add(
          Padding(
            padding: const EdgeInsets.only(right: 60, bottom: 2),
            child: Align(
              alignment: Alignment.centerRight,
              child: const _GiftBonus(),
            ),
          ),
        );
      }
    }

    return Stack(
      children: [
        // Dashed trail behind the nodes
        Positioned.fill(
          child: CustomPaint(painter: _DashedTrailPainter()),
        ),
        Column(children: items),
      ],
    );
  }
}

// ─── Dashed Trail Painter ─────────────────────────────────────────────────────

class _DashedTrailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _kDashColor
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    const dashLen = 7.0;
    const gapLen = 5.0;
    final cx = size.width / 2;
    double y = 0;

    while (y < size.height) {
      canvas.drawLine(Offset(cx, y), Offset(cx, y + dashLen), paint);
      y += dashLen + gapLen;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─── Node Button ──────────────────────────────────────────────────────────────

class _NodeButton extends StatelessWidget {
  const _NodeButton({required this.node, required this.unitId});
  final LessonNode node;
  final String unitId;

  @override
  Widget build(BuildContext context) {
    final isActive = node.state == NodeState.active;
    final isCompleted = node.state == NodeState.completed;

    Color bg;
    Color border;
    List<BoxShadow>? shadow;
    Widget icon;

    if (isCompleted) {
      bg = _kNodeActiveColor;
      border = _kNodeActiveColor;
      shadow = [
        BoxShadow(
            color: _kNodeActiveShadow, blurRadius: 16, offset: const Offset(0, 6))
      ];
      icon = const Icon(Icons.star_rounded, color: Colors.white, size: 32);
    } else if (isActive) {
      bg = _kNodeActiveColor;
      border = _kNodeActiveColor;
      shadow = [
        BoxShadow(
            color: _kNodeActiveShadow, blurRadius: 16, offset: const Offset(0, 6))
      ];
      icon = const Icon(Icons.star_rounded, color: Colors.white, size: 32);
    } else {
      bg = const Color(0xFFE8E0D8);
      border = const Color(0xFFCEC5BC);
      icon = const Icon(Icons.lock_rounded, color: Color(0xFFB0A89E), size: 26);
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
          color: bg,
          border: Border.all(color: border, width: 3),
          boxShadow: shadow,
        ),
        child: Center(child: icon),
      ),
    );
  }
}

// ─── Gift Bonus Node ──────────────────────────────────────────────────────────

class _GiftBonus extends ConsumerWidget {
  const _GiftBonus();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final claimed = ref.watch(dailyGiftProvider);

    return Tooltip(
      message: claimed ? 'Sudah diklaim hari ini' : 'Klaim +10 XP gratis!',
      child: GestureDetector(
        onTap: claimed
            ? null
            : () async {
                final success =
                    await ref.read(dailyGiftProvider.notifier).claim();
                if (success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Row(
                        children: [
                          Text('🎁  '),
                          Text('+10 XP! Klaim lagi besok ya.',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: claimed ? AppColors.locked : AppColors.primary,
            borderRadius: BorderRadius.circular(14),
            boxShadow: claimed
                ? null
                : [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Center(
            child: Icon(
              claimed
                  ? Icons.check_circle_rounded
                  : Icons.card_giftcard_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Mascot Area ─────────────────────────────────────────────────────────────

class _MascotArea extends StatelessWidget {
  const _MascotArea();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Speech bubble
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
              bottomRight: Radius.circular(12),
              bottomLeft: Radius.circular(2),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            'Ayo Mulai!',
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 2),
        // Camel emoji mascot
        const Text('🐪', style: TextStyle(fontSize: 48)),
      ],
    );
  }
}
