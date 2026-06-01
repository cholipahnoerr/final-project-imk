import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';

// Static mock partner list — Sprint 6 replaces with Firestore query
class _Partner {
  const _Partner({
    required this.id,
    required this.name,
    required this.lastMessage,
    required this.time,
    this.unread = 0,
    this.isOnline = false,
    this.level = 'Pemula',
  });
  final String id;
  final String name;
  final String lastMessage;
  final String time;
  final int unread;
  final bool isOnline;
  final String level;
}

const _mockPartners = [
  _Partner(
    id: 'user-0',
    name: 'Ahmad Fauzi',
    lastMessage: 'مرحبا! أهلاً وسهلاً',
    time: '10:32',
    unread: 2,
    isOnline: true,
    level: 'Menengah',
  ),
  _Partner(
    id: 'user-1',
    name: 'Siti Rahayu',
    lastMessage: 'شكراً على المساعدة',
    time: '09:15',
    unread: 0,
    isOnline: true,
    level: 'Pemula',
  ),
  _Partner(
    id: 'user-2',
    name: 'Budi Santoso',
    lastMessage: 'كيف حالك؟',
    time: 'Kemarin',
    unread: 0,
    isOnline: false,
    level: 'Lanjutan',
  ),
  _Partner(
    id: 'user-3',
    name: 'Dewi Lestari',
    lastMessage: 'ممتاز! أفهم الآن',
    time: 'Kemarin',
    unread: 1,
    isOnline: false,
    level: 'Pemula',
  ),
  _Partner(
    id: 'user-4',
    name: 'Reza Pratama',
    lastMessage: 'إلى اللقاء!',
    time: 'Sen',
    unread: 0,
    isOnline: false,
    level: 'Menengah',
  ),
];

class TalkScreen extends StatelessWidget {
  const TalkScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Bincang'),
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Online partners strip
          _OnlineStrip(partners: _mockPartners.where((p) => p.isOnline).toList()),
          const Divider(height: 1),
          // Conversation list
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _mockPartners.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, indent: 80, endIndent: 16),
              itemBuilder: (context, index) {
                final partner = _mockPartners[index];
                return _ConversationTile(
                  partner: partner,
                  onTap: () => context.push('/talk/chat/${partner.id}'),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () {
          _showFindPartnerSheet(context);
        },
        child: const Icon(Icons.person_add_rounded, color: Colors.white),
      ),
    );
  }
}

class _OnlineStrip extends StatelessWidget {
  const _OnlineStrip({required this.partners});
  final List<_Partner> partners;

  @override
  Widget build(BuildContext context) {
    if (partners.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 88,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: partners.length,
        itemBuilder: (context, i) {
          final p = partners[i];
          return GestureDetector(
            onTap: () => context.push('/talk/chat/${p.id}'),
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                        child: Text(
                          p.name[0],
                          style: AppTypography.titleLarge.copyWith(color: AppColors.primary),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.background, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    p.name.split(' ').first,
                    style: AppTypography.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({required this.partner, required this.onTap});
  final _Partner partner;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.surfaceVariant,
            child: Text(
              partner.name[0],
              style: AppTypography.titleLarge.copyWith(color: AppColors.textSecondary),
            ),
          ),
          if (partner.isOnline)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.background, width: 2),
                ),
              ),
            ),
        ],
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              partner.name,
              style: AppTypography.titleMedium.copyWith(
                fontWeight: partner.unread > 0 ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ),
          Text(
            partner.time,
            style: AppTypography.bodySmall.copyWith(
              color: partner.unread > 0 ? AppColors.primary : AppColors.textMuted,
              fontWeight: partner.unread > 0 ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: Text(
              partner.lastMessage,
              style: AppTypography.arabicMedium.copyWith(
                fontSize: 13,
                color: partner.unread > 0 ? AppColors.textPrimary : AppColors.textSecondary,
                fontWeight: partner.unread > 0 ? FontWeight.w600 : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (partner.unread > 0)
            Container(
              margin: const EdgeInsets.only(left: 6),
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${partner.unread}',
                style: AppTypography.bodySmall.copyWith(color: Colors.white, fontSize: 11),
              ),
            ),
        ],
      ),
      onTap: onTap,
    );
  }
}

void _showFindPartnerSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Temukan Partner Belajar', style: AppTypography.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'Fitur pencarian partner akan tersedia segera.',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
        ],
      ),
    ),
  );
}
