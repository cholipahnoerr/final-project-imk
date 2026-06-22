import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../data/models/achievement_model.dart';
import '../../../data/models/leaderboard_entry_model.dart';
import '../../../data/models/user_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../data/repositories/gamification_repository.dart';
import '../../common_widgets/achievement_badge.dart';
import '../home/home_viewmodel.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final unlockedIds = ref.watch(unlockedAchievementsProvider).valueOrNull ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 80,
        leading: userAsync.when(
          data: (user) => Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.local_fire_department_rounded,
                  color: AppColors.streak, size: 22),
              const SizedBox(width: 3),
              Text('${user?.currentStreak ?? 0}',
                  style: AppTypography.titleMedium.copyWith(
                      color: AppColors.streak, fontWeight: FontWeight.w800)),
            ]),
          ),
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const SizedBox.shrink(),
        ),
        title: Text('Profil',
            style: AppTypography.titleLarge
                .copyWith(color: AppColors.primary, fontWeight: FontWeight.w800)),
        centerTitle: true,
        actions: [
          userAsync.when(
            data: (user) => Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text('${user?.gems ?? 0}',
                    style: AppTypography.titleMedium.copyWith(
                        color: AppColors.gems, fontWeight: FontWeight.w800)),
                const SizedBox(width: 3),
                Icon(Icons.diamond_rounded, color: AppColors.gems, size: 20),
              ]),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: userAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (user) {
          if (user == null) return const SizedBox.shrink();
          final league = LeagueExtension.fromString(user.currentLeague);

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ── Avatar ────────────────────────────────────────────────
                CircleAvatar(
                  radius: 52,
                  backgroundColor: AppColors.surfaceVariant,
                  backgroundImage: user.photoUrl != null
                      ? CachedNetworkImageProvider(user.photoUrl!)
                      : null,
                  child: user.photoUrl == null
                      ? Text(
                          user.displayName.isNotEmpty
                              ? user.displayName[0].toUpperCase()
                              : '?',
                          style: AppTypography.displayLarge
                              .copyWith(color: AppColors.primary),
                        )
                      : null,
                ),
                const SizedBox(height: 14),

                // ── Name + edit ──────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      user.displayName.isNotEmpty ? user.displayName : 'Pelajar',
                      style: AppTypography.headlineLarge
                          .copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _showEditProfileSheet(context, ref, user),
                      child: const Icon(Icons.edit_rounded,
                          color: AppColors.textSecondary, size: 18),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  user.handle,
                  style: AppTypography.bodyMedium
                      .copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),

                // ── Settings gear ────────────────────────────────────────
                GestureDetector(
                  onTap: () => context.push('/profile/settings'),
                  child: const Icon(Icons.settings_rounded,
                      color: AppColors.textSecondary, size: 24),
                ),
                const SizedBox(height: 16),

                // ── Language dropdown ────────────────────────────────────
                GestureDetector(
                  onTap: () => context.push('/profile/settings'),
                  child: _LanguageDropdown(proficiencyLevel: user.proficiencyLevel),
                ),
                const SizedBox(height: 20),

                // ── Stats 2×2 ────────────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        value: '${user.longestStreak} Hari',
                        label: 'STREAK TERLAMA',
                        icon: Icons.local_fire_department_rounded,
                        color: AppColors.streak,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        value: _formatXp(user.xp),
                        label: 'TOTAL XP',
                        icon: Icons.bolt_rounded,
                        color: AppColors.gold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        value: league.labelId,
                        label: 'LIGA SAAT INI',
                        icon: Icons.shield_rounded,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        value: '${user.wordsLearned}',
                        label: 'KATA DIPELAJARI',
                        icon: Icons.menu_book_rounded,
                        color: AppColors.gems,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // ── Lencana ───────────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Lencana',
                        style: AppTypography.headlineMedium
                            .copyWith(fontWeight: FontWeight.w800)),
                    GestureDetector(
                      onTap: () => context.push('/profile/achievements'),
                      child: Text('Lihat Semua',
                          style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 96,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: kAllAchievements.length.clamp(0, 5),
                    separatorBuilder: (_, _) => const SizedBox(width: 14),
                    itemBuilder: (context, index) {
                      final def = kAllAchievements[index];
                      final model = AchievementModel(
                        definition: def,
                        unlockedAt:
                            unlockedIds.contains(def.id) ? DateTime.now() : null,
                      );
                      return AchievementBadge(model: model, size: 56);
                    },
                  ),
                ),
                const SizedBox(height: 28),

                // ── Menu ──────────────────────────────────────────────────
                if (user.isAdmin) ...[
                  _MenuItem(
                    icon: Icons.admin_panel_settings_rounded,
                    label: 'Admin Panel',
                    onTap: () => context.push('/admin'),
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 10),
                ],
                _MenuItem(
                  icon: Icons.person_add_outlined,
                  label: 'Cari Teman',
                  onTap: () => context.push('/talk'),
                ),
                const SizedBox(height: 10),
                _MenuItem(
                  icon: Icons.share_outlined,
                  label: 'Bagikan Profil',
                  onTap: () => _shareProfile(context, user),
                ),
                const SizedBox(height: 10),
                _MenuItem(
                  icon: Icons.logout_rounded,
                  label: 'Keluar',
                  isDestructive: true,
                  onTap: () => _confirmLogout(context, ref),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatXp(int xp) {
    if (xp >= 1000) return '${(xp / 1000).toStringAsFixed(1)}K';
    return '$xp';
  }

  void _showEditProfileSheet(BuildContext context, WidgetRef ref, UserModel user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _EditProfileSheet(user: user, ref: ref),
    );
  }

  Future<void> _shareProfile(BuildContext context, UserModel user) async {
    final text =
        '${user.displayName} ${user.handle}\n'
        '🔥 Streak: ${user.currentStreak} hari\n'
        '⚡ Total XP: ${user.xp}\n'
        '📚 Kata dipelajari: ${user.wordsLearned}\n\n'
        'Belajar bahasa Arab bersama di Hayyarabic!';
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Info profil disalin ke clipboard!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar'),
        content: const Text('Yakin ingin keluar dari akunmu?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await ref.read(firebaseAuthProvider).signOut();
      if (context.mounted) context.go('/auth/login');
    }
  }
}

// ─── Edit Profile Sheet ───────────────────────────────────────────────────────

class _EditProfileSheet extends ConsumerStatefulWidget {
  const _EditProfileSheet({required this.user, required this.ref});
  final UserModel user;
  final WidgetRef ref;

  @override
  ConsumerState<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<_EditProfileSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _usernameCtrl;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.user.displayName);
    _usernameCtrl = TextEditingController(text: widget.user.username ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() => _isSaving = true);
    try {
      final updates = <String, dynamic>{'displayName': name};
      final username = _usernameCtrl.text.trim();
      if (username.isNotEmpty) updates['username'] = username;
      await ref
          .read(firestoreDataSourceProvider)
          .updateUser(widget.user.uid, updates);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Edit Profil', style: AppTypography.headlineMedium),
          const SizedBox(height: 20),
          TextField(
            controller: _nameCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: 'Nama Lengkap',
              prefixIcon: const Icon(Icons.person_outline_rounded),
              filled: true,
              fillColor: AppColors.surfaceVariant,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _usernameCtrl,
            decoration: InputDecoration(
              labelText: 'Username (opsional)',
              prefixIcon: const Icon(Icons.alternate_email_rounded),
              hintText: 'contoh: ahmad123',
              filled: true,
              fillColor: AppColors.surfaceVariant,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _isSaving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Simpan'),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Language Dropdown ────────────────────────────────────────────────────────

class _LanguageDropdown extends StatelessWidget {
  const _LanguageDropdown({this.proficiencyLevel});
  final String? proficiencyLevel;

  String get _label => switch (proficiencyLevel?.toLowerCase()) {
        'beginner' => 'Bahasa Arab — Pemula',
        'intermediate' => 'Bahasa Arab — Menengah',
        'advanced' => 'Bahasa Arab — Mahir',
        _ => 'Bahasa Arab — Pemula',
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Text('🏳️', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(_label,
                style: AppTypography.bodyMedium
                    .copyWith(fontWeight: FontWeight.w500)),
          ),
          const Icon(Icons.keyboard_arrow_down_rounded,
              color: AppColors.textSecondary, size: 22),
        ],
      ),
    );
  }
}

// ─── Stat Card ────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(value,
              style: AppTypography.headlineMedium
                  .copyWith(fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          const SizedBox(height: 2),
          Text(label,
              style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5)),
        ],
      ),
    );
  }
}

// ─── Menu Item ────────────────────────────────────────────────────────────────

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final fgColor =
        isDestructive ? AppColors.error : color ?? AppColors.textPrimary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Icon(icon, color: fgColor, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label,
                  style: AppTypography.bodyMedium.copyWith(
                      color: fgColor, fontWeight: FontWeight.w600)),
            ),
            Icon(Icons.chevron_right_rounded,
                color: isDestructive ? AppColors.error : AppColors.textMuted,
                size: 22),
          ],
        ),
      ),
    );
  }
}
