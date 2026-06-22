import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/services/audio_service.dart';
import '../../../data/models/stream_content_model.dart';
import '../home/home_viewmodel.dart';
import 'stream_viewmodel.dart';

// Olive/sage green matching Figma Kata Hari Ini card
const _kOliveGreen = Color(0xFF6B7A5C);

class StreamScreen extends ConsumerWidget {
  const StreamScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wordAsync = ref.watch(wordOfDayProvider);
    final triviasAsync = ref.watch(triviasProvider);
    final socialPosts = ref.watch(socialPostsProvider);
    final userAsync = ref.watch(currentUserProvider);

    // Build interleaved feed once data is available
    final WordOfDay? word = wordAsync.valueOrNull;
    final List<CultureTrivia> trivias = triviasAsync.valueOrNull ?? [];

    // Build interleaved feed: word-of-day → [post, trivia, post, trivia …]
    final feed = _buildFeed(word, trivias, socialPosts);

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
          'Kabar',
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
                  Icon(Icons.diamond_rounded, color: AppColors.gems, size: 20),
                ],
              ),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: wordAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(
          child: Text('Gagal memuat konten',
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.textSecondary)),
        ),
        data: (_) => ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          itemCount: feed.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, i) => _buildFeedItem(context, feed[i]),
        ),
      ),
    );
  }

  List<Object> _buildFeed(
    WordOfDay? word,
    List<CultureTrivia> trivias,
    List<SocialPost> socialPosts,
  ) {
    final items = <Object>[];
    if (word != null) items.add(word);

    final posts = List<SocialPost>.from(socialPosts);
    final triviaList = List<CultureTrivia>.from(trivias);

    int pi = 0, ti = 0;
    while (pi < posts.length || ti < triviaList.length) {
      if (pi < posts.length) items.add(posts[pi++]);
      if (ti < triviaList.length) items.add(triviaList[ti++]);
    }
    return items;
  }

  Widget _buildFeedItem(BuildContext context, Object item) {
    if (item is WordOfDay) {
      return _WordOfDayCard(
        word: item,
        onTap: () => context.push('/stream/word-of-day/${item.id}'),
      );
    } else if (item is SocialPost) {
      return _SocialPostCard(post: item);
    } else if (item is CultureTrivia) {
      return _TriviaBudayaCard(
        trivia: item,
        onTap: () => context.push('/stream/culture-trivia/${item.id}'),
      );
    }
    return const SizedBox.shrink();
  }
}

// ─── Word of Day Card ─────────────────────────────────────────────────────────

class _WordOfDayCard extends ConsumerStatefulWidget {
  const _WordOfDayCard({required this.word, required this.onTap});

  final WordOfDay word;
  final VoidCallback onTap;

  @override
  ConsumerState<_WordOfDayCard> createState() => _WordOfDayCardState();
}

class _WordOfDayCardState extends ConsumerState<_WordOfDayCard> {
  bool _isPlaying = false;
  bool _isLoading = false;

  @override
  void dispose() {
    ref.read(audioServiceProvider).stop();
    super.dispose();
  }

  Future<void> _toggleAudio() async {
    final service = ref.read(audioServiceProvider);

    if (_isPlaying) {
      await service.stop();
      if (mounted) setState(() => _isPlaying = false);
      return;
    }

    setState(() => _isLoading = true);

    try {
      setState(() {
        _isLoading = false;
        _isPlaying = true;
      });

      if (widget.word.audioUrl != null && widget.word.audioUrl!.isNotEmpty) {
        await service.playUrl(widget.word.audioUrl!);
      } else {
        await service.playTts(widget.word.arabic);
      }

      await service.playerStateStream.firstWhere(
        (s) =>
            s.processingState == ProcessingState.completed ||
            s.processingState == ProcessingState.idle,
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Gagal memutar audio. Periksa koneksi internet dan coba lagi.'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() { _isPlaying = false; _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        decoration: BoxDecoration(
          color: _kOliveGreen,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Text(
              'KATA HARI INI',
              style: AppTypography.bodySmall.copyWith(
                color: Colors.white.withValues(alpha: 0.75),
                letterSpacing: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              widget.word.arabic,
              style: const TextStyle(
                fontFamily: 'NotoNaskhArabic',
                fontSize: 48,
                color: Colors.white,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              widget.word.transliteration,
              style: AppTypography.headlineMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              widget.word.translation,
              style: AppTypography.bodyMedium.copyWith(
                color: Colors.white.withValues(alpha: 0.85),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            // Play button — absorbs tap to prevent card navigation
            GestureDetector(
              onTap: _toggleAudio,
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isPlaying
                      ? Colors.white.withValues(alpha: 0.4)
                      : Colors.white.withValues(alpha: 0.2),
                ),
                child: Center(
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Icon(
                          _isPlaying
                              ? Icons.stop_rounded
                              : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 30,
                        ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Kosa Kata Level ${widget.word.level}',
              style: AppTypography.bodySmall.copyWith(
                color: Colors.white.withValues(alpha: 0.65),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Social Post Card ─────────────────────────────────────────────────────────

class _SocialPostCard extends StatefulWidget {
  const _SocialPostCard({required this.post});
  final SocialPost post;

  @override
  State<_SocialPostCard> createState() => _SocialPostCardState();
}

class _SocialPostCardState extends State<_SocialPostCard> {
  bool _liked = false;

  @override
  Widget build(BuildContext context) {
    final initials = widget.post.userName.isNotEmpty
        ? widget.post.userName[0].toUpperCase()
        : '?';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                backgroundImage: widget.post.userAvatar != null
                    ? NetworkImage(widget.post.userAvatar!)
                    : null,
                child: widget.post.userAvatar == null
                    ? Text(
                        initials,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              // Name + time
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          widget.post.userName,
                          style: AppTypography.titleMedium,
                        ),
                        Text(
                          ' • ${widget.post.timeAgo}',
                          style: AppTypography.bodySmall
                              .copyWith(color: AppColors.textMuted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.post.content,
                      style: AppTypography.bodyMedium
                          .copyWith(color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ),
              // Like button
              GestureDetector(
                onTap: () => setState(() => _liked = !_liked),
                child: Icon(
                  _liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: _liked ? AppColors.hearts : AppColors.textMuted,
                  size: 22,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Streak badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.streak.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: AppColors.streak.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.local_fire_department_rounded,
                    color: AppColors.streak, size: 15),
                const SizedBox(width: 4),
                Text(
                  '${widget.post.streakDays} Hari',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.streak,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Trivia Budaya Card ───────────────────────────────────────────────────────

class _TriviaBudayaCard extends StatelessWidget {
  const _TriviaBudayaCard({required this.trivia, required this.onTap});

  final CultureTrivia trivia;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.lightbulb_outline_rounded,
                            color: AppColors.primary, size: 16),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'TRIVIA BUDAYA',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    trivia.title,
                    style: AppTypography.headlineMedium.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    trivia.subtitle,
                    style: AppTypography.bodyMedium
                        .copyWith(color: AppColors.textSecondary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Image area
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(16),
              ),
              child: trivia.imageUrl != null
                  ? Image.network(
                      trivia.imageUrl!,
                      height: 140,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      height: 120,
                      width: double.infinity,
                      color: AppColors.primary.withValues(alpha: 0.08),
                      child: const Center(
                        child: Icon(Icons.auto_stories_rounded,
                            color: AppColors.primary, size: 48),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
