import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/services/auth_service.dart';
import '../../../data/models/chat_message_model.dart';
import '../../../data/models/user_model.dart';
import '../home/home_viewmodel.dart';
import 'talk_viewmodel.dart';

class TalkScreen extends ConsumerWidget {
  const TalkScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final conversationsAsync = ref.watch(conversationsProvider);
    final myUid = ref.watch(firebaseAuthProvider).currentUser?.uid ?? '';

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
              Icon(Icons.local_fire_department_rounded, color: AppColors.streak, size: 22),
              const SizedBox(width: 3),
              Text('${user?.currentStreak ?? 0}',
                  style: AppTypography.titleMedium
                      .copyWith(color: AppColors.streak, fontWeight: FontWeight.w800)),
            ]),
          ),
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const SizedBox.shrink(),
        ),
        title: Text('Bincang',
            style: AppTypography.titleLarge
                .copyWith(color: AppColors.primary, fontWeight: FontWeight.w800)),
        centerTitle: true,
        actions: [
          userAsync.when(
            data: (user) => Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text('${user?.gems ?? 0}',
                    style: AppTypography.titleMedium
                        .copyWith(color: AppColors.gems, fontWeight: FontWeight.w800)),
                const SizedBox(width: 3),
                Icon(Icons.diamond_rounded, color: AppColors.gems, size: 20),
              ]),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: conversationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (_, _) => Center(
          child: Text('Gagal memuat percakapan',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary)),
        ),
        data: (conversations) {
          if (conversations.isEmpty) {
            return _EmptyState(onFindPartner: () => _showFindPartnerSheet(context, ref));
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: conversations.length,
            separatorBuilder: (_, _) =>
                const Divider(height: 1, indent: 80, endIndent: 16),
            itemBuilder: (context, index) {
              final conv = conversations[index];
              return _ConversationTile(
                conversation: conv,
                myUid: myUid,
                onTap: () => context.push(
                  '/talk/chat/${conv.partnerIdFor(myUid)}',
                  extra: {'partnerName': conv.partnerNameFor(myUid)},
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => _showFindPartnerSheet(context, ref),
        child: const Icon(Icons.person_add_rounded, color: Colors.white),
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onFindPartner});
  final VoidCallback onFindPartner;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.chat_bubble_outline_rounded, size: 64, color: AppColors.textMuted),
          const SizedBox(height: 16),
          Text('Belum ada percakapan',
              style: AppTypography.titleMedium.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Text('Temukan teman belajar dan mulai chat',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted)),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onFindPartner,
            icon: const Icon(Icons.person_search_rounded),
            label: const Text('Cari Teman'),
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

// ─── Conversation Tile ────────────────────────────────────────────────────────

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.conversation,
    required this.myUid,
    required this.onTap,
  });
  final ChatConversation conversation;
  final String myUid;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final partnerName = conversation.partnerNameFor(myUid);
    final lastMsg = conversation.lastMessageType == 'voice'
        ? '🎵 Voice note'
        : conversation.lastMessage;
    final time = _formatTime(conversation.lastMessageTime);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: AppColors.primary.withValues(alpha: 0.12),
        child: Text(
          partnerName.isNotEmpty ? partnerName[0].toUpperCase() : '?',
          style: AppTypography.titleLarge.copyWith(color: AppColors.primary),
        ),
      ),
      title: Text(
        partnerName,
        style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        lastMsg,
        style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text(
        time,
        style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
      ),
      onTap: onTap,
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    final yesterday = now.subtract(const Duration(days: 1));
    if (dt.year == yesterday.year && dt.month == yesterday.month && dt.day == yesterday.day) {
      return 'Kemarin';
    }
    return '${dt.day}/${dt.month}';
  }
}

// ─── Find Partner Bottom Sheet ────────────────────────────────────────────────

void _showFindPartnerSheet(BuildContext context, WidgetRef ref) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => _FindPartnerSheet(
      onSelected: (user) {
        Navigator.pop(ctx);
        context.push('/talk/chat/${user.uid}',
            extra: {'partnerName': user.displayName});
      },
    ),
  );
}

class _FindPartnerSheet extends ConsumerStatefulWidget {
  const _FindPartnerSheet({required this.onSelected});
  final void Function(UserModel user) onSelected;

  @override
  ConsumerState<_FindPartnerSheet> createState() => _FindPartnerSheetState();
}

class _FindPartnerSheetState extends ConsumerState<_FindPartnerSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchAsync = ref.watch(userSearchProvider);

    return Padding(
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Temukan Partner Belajar', style: AppTypography.headlineMedium),
          const SizedBox(height: 4),
          Text('Ketik email pengguna untuk memulai percakapan',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted)),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: 'Cari email pengguna...',
              prefixIcon: const Icon(Icons.email_outlined),
              filled: true,
              fillColor: AppColors.surfaceVariant,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (q) {
              if (q.trim().length >= 3) {
                ref.read(userSearchProvider.notifier).search(q.trim());
              } else {
                ref.read(userSearchProvider.notifier).clear();
              }
            },
          ),
          const SizedBox(height: 12),
          searchAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Gagal mencari: ${e.toString().split(']').last.trim()}',
                style: AppTypography.bodySmall.copyWith(color: AppColors.error),
                textAlign: TextAlign.center,
              ),
            ),
            data: (users) {
              if (users.isEmpty && _controller.text.length >= 3) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Text('Email tidak ditemukan',
                        style: AppTypography.bodyMedium
                            .copyWith(color: AppColors.textMuted)),
                  ),
                );
              }
              return ListView.builder(
                shrinkWrap: true,
                itemCount: users.length,
                itemBuilder: (_, i) {
                  final u = users[i];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                      child: Text(
                        u.displayName.isNotEmpty
                            ? u.displayName[0].toUpperCase()
                            : u.email[0].toUpperCase(),
                        style: AppTypography.titleMedium
                            .copyWith(color: AppColors.primary),
                      ),
                    ),
                    title: Text(u.displayName.isNotEmpty ? u.displayName : u.email,
                        style: AppTypography.titleMedium),
                    subtitle: Text(u.email,
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.textMuted)),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => widget.onSelected(u),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
