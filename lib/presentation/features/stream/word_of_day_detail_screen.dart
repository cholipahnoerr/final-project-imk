import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/services/audio_service.dart';
import 'stream_viewmodel.dart';

class WordOfDayDetailScreen extends ConsumerStatefulWidget {
  const WordOfDayDetailScreen({super.key, required this.wordId});
  final String wordId;

  @override
  ConsumerState<WordOfDayDetailScreen> createState() => _WordOfDayDetailScreenState();
}

class _WordOfDayDetailScreenState extends ConsumerState<WordOfDayDetailScreen> {
  bool _isPlaying = false;

  Future<void> _playAudio(String? audioUrl) async {
    if (_isPlaying) return;
    setState(() => _isPlaying = true);
    if (audioUrl != null && audioUrl.isNotEmpty) {
      await ref.read(audioServiceProvider).playUrl(audioUrl);
    } else {
      await Future.delayed(const Duration(milliseconds: 600));
    }
    if (mounted) setState(() => _isPlaying = false);
  }

  @override
  Widget build(BuildContext context) {
    final word = ref.watch(wordOfDayProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Kata Hari Ini'),
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Arabic word hero
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Text(
                    word.arabic,
                    style: AppTypography.arabicLarge.copyWith(color: Colors.white, fontSize: 56),
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    word.transliteration,
                    style: AppTypography.bodyLarge.copyWith(color: Colors.white70),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    word.translation,
                    style: AppTypography.headlineMedium.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    word.partOfSpeech,
                    style: AppTypography.bodySmall.copyWith(color: Colors.white54),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Play audio button
            GestureDetector(
              onTap: () => _playAudio(word.audioUrl),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: _isPlaying
                      ? AppColors.primary.withValues(alpha: 0.1)
                      : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _isPlaying ? AppColors.primary : AppColors.border,
                    width: _isPlaying ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isPlaying ? Icons.volume_up_rounded : Icons.play_circle_fill_rounded,
                      color: AppColors.primary,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _isPlaying ? 'Memutar...' : 'Dengarkan Pengucapan',
                      style: AppTypography.bodyLarge.copyWith(
                        color: _isPlaying ? AppColors.primary : AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Example sentence
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Contoh Kalimat', style: AppTypography.headlineMedium),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    word.exampleArabic,
                    style: AppTypography.arabicMedium.copyWith(fontSize: 20),
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      word.exampleTranslation,
                      style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Did you know
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.goldLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lightbulb_rounded, color: AppColors.gold, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Kata "${word.translation}" dalam bahasa Arab termasuk '
                      '${word.partOfSpeech.toLowerCase()}. '
                      'Pelajari penggunaannya dalam konteks percakapan sehari-hari!',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.goldDark),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
