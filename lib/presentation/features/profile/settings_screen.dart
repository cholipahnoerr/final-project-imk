import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/local_storage_service.dart';
import '../../../core/services/notification_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late bool _notificationsEnabled;

  @override
  void initState() {
    super.initState();
    _notificationsEnabled = LocalStorageService.notificationsEnabled;
  }

  Future<void> _toggleNotifications(bool value) async {
    setState(() => _notificationsEnabled = value);
    await LocalStorageService.setNotificationsEnabled(value);
    if (value) {
      await NotificationService.scheduleStreakReminder();
    } else {
      await NotificationService.cancelStreakReminder();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pengaturan'),
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        children: [
          _SettingsSection(
            title: 'Akun',
            items: [
              _SettingsItem(
                icon: Icons.school_outlined,
                label: 'Ubah Level Bahasa',
                onTap: () => context.push('/onboarding/level'),
              ),
              _SettingsItem(
                icon: Icons.flag_outlined,
                label: 'Ubah Tujuan Belajar',
                onTap: () => context.push('/onboarding/goals'),
              ),
            ],
          ),
          _SettingsSection(
            title: 'Notifikasi',
            items: [
              _SettingsSwitchItem(
                icon: Icons.notifications_outlined,
                label: 'Pengingat Streak Harian',
                subtitle: 'Ingatkan untuk belajar setiap hari',
                value: _notificationsEnabled,
                onChanged: _toggleNotifications,
              ),
            ],
          ),
          _SettingsSection(
            title: 'Lainnya',
            items: [
              _SettingsItem(
                icon: Icons.info_outline,
                label: 'Tentang Hayyarabic',
                onTap: () => _showAbout(context),
              ),
              _SettingsItem(icon: Icons.privacy_tip_outlined, label: 'Kebijakan Privasi', onTap: () {}),
              _SettingsItem(
                icon: Icons.logout_rounded,
                label: 'Keluar',
                color: AppColors.error,
                onTap: () => _confirmSignOut(context),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Center(
            child: Text(
              'Hayyarabic v1.0.0',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _confirmSignOut(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar?'),
        content: const Text('Kamu akan keluar dari akun Hayyarabic.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authRepositoryProvider).signOut();
              if (context.mounted) context.go('/auth/login');
            },
            child: Text('Keluar', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Hayyarabic',
      applicationVersion: '1.0.0',
      applicationLegalese: '© 2025 Hayyarabic. Final Project IMK.',
      children: [
        const SizedBox(height: 12),
        const Text('Aplikasi pembelajaran bahasa Arab bergaya Duolingo dengan gamifikasi lengkap.'),
      ],
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.items});
  final String title;
  final List<Widget> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Text(
            title.toUpperCase(),
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textMuted,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            children: [
              for (int i = 0; i < items.length; i++) ...[
                items[i],
                if (i < items.length - 1)
                  const Divider(height: 1, indent: 52),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsItem extends StatelessWidget {
  const _SettingsItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textPrimary;
    return ListTile(
      leading: Icon(icon, color: c, size: 22),
      title: Text(label, style: AppTypography.bodyLarge.copyWith(color: c)),
      trailing: Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    );
  }
}

class _SettingsSwitchItem extends StatelessWidget {
  const _SettingsSwitchItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      secondary: Icon(icon, color: AppColors.textPrimary, size: 22),
      title: Text(label, style: AppTypography.bodyLarge),
      subtitle: subtitle != null
          ? Text(subtitle!, style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted))
          : null,
      value: value,
      activeThumbColor: AppColors.primary,
      activeTrackColor: AppColors.primaryLight,
      onChanged: onChanged,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    );
  }
}
