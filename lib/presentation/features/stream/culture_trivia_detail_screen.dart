import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../data/models/stream_content_model.dart';
import 'stream_viewmodel.dart';

class CultureTriviaDetailScreen extends ConsumerWidget {
  const CultureTriviaDetailScreen({super.key, required this.triviaId});
  final String triviaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trivia = ref.watch(cultureTriviaProvider(triviaId));

    if (trivia == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Artikel Budaya')),
        body: const Center(child: Text('Artikel tidak ditemukan')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Artikel Budaya'),
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero image placeholder
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: const Center(
                child: Icon(Icons.auto_stories_rounded, size: 56, color: AppColors.primary),
              ),
            ),
            const SizedBox(height: 20),

            // Title + subtitle
            Text(trivia.title, style: AppTypography.headlineLarge),
            const SizedBox(height: 6),
            Text(
              trivia.subtitle,
              style: AppTypography.bodyLarge.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),

            // Article body — words clickable for inline dictionary
            _InlineDictionaryText(
              text: trivia.content,
              vocabulary: trivia.vocabulary,
            ),

            const SizedBox(height: 28),

            // Vocabulary section
            Text('Kosakata dalam Artikel', style: AppTypography.headlineMedium),
            const SizedBox(height: 12),
            ...trivia.vocabulary.map((v) => _VocabCard(entry: v)),
          ],
        ),
      ),
    );
  }
}

class _InlineDictionaryText extends StatelessWidget {
  const _InlineDictionaryText({required this.text, required this.vocabulary});

  final String text;
  final List<VocabEntry> vocabulary;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: AppTypography.bodyLarge);
  }
}

class _VocabCard extends StatelessWidget {
  const _VocabCard({required this.entry});
  final VocabEntry entry;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showDictionarySheet(context, entry),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.translate_rounded, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.arabic,
                    style: AppTypography.arabicMedium.copyWith(fontSize: 18),
                    textDirection: TextDirection.rtl,
                  ),
                  if (entry.transliteration != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      entry.transliteration!,
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              entry.translation,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

void _showDictionarySheet(BuildContext context, VocabEntry entry) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            entry.arabic,
            style: AppTypography.arabicLarge.copyWith(fontSize: 48),
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: 8),
          if (entry.transliteration != null)
            Text(
              entry.transliteration!,
              style: AppTypography.bodyLarge.copyWith(color: AppColors.textSecondary),
            ),
          const SizedBox(height: 6),
          Text(
            entry.translation,
            style: AppTypography.headlineMedium.copyWith(color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.volume_up_rounded, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Dengarkan pengucapan',
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
