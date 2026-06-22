import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/services/audio_service.dart';
import '../../../data/models/stream_content_model.dart';
import 'stream_viewmodel.dart';

class WordOfDayDetailScreen extends ConsumerStatefulWidget {
  const WordOfDayDetailScreen({super.key, required this.wordId});
  final String wordId;

  @override
  ConsumerState<WordOfDayDetailScreen> createState() =>
      _WordOfDayDetailScreenState();
}

class _WordOfDayDetailScreenState extends ConsumerState<WordOfDayDetailScreen> {
  bool _isPlaying = false;
  bool _isLoading = false;

  @override
  void dispose() {
    ref.read(audioServiceProvider).stop();
    super.dispose();
  }

  Future<void> _toggleAudio(WordOfDay word) async {
    final service = ref.read(audioServiceProvider);

    // Stop if already playing
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

      // Use stored audioUrl if available, otherwise download TTS
      if (word.audioUrl != null && word.audioUrl!.isNotEmpty) {
        await service.playUrl(word.audioUrl!);
      } else {
        await service.playTts(word.arabic);
      }

      // Listen for natural completion
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
      if (mounted) setState(() {_isPlaying = false; _isLoading = false;});
    }
  }

  @override
  Widget build(BuildContext context) {
    final wordAsync = ref.watch(wordOfDayProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Kata Hari Ini',
            style: AppTypography.titleLarge
                .copyWith(color: AppColors.primary, fontWeight: FontWeight.w800)),
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: wordAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(
          child: Text('Gagal memuat kata',
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.textSecondary)),
        ),
        data: (word) {
          if (word == null) {
            return const Center(child: Text('Kata tidak tersedia'));
          }
          return _buildBody(word);
        },
      ),
    );
  }

  Widget _buildBody(WordOfDay word) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Arabic hero card ───────────────────────────────────────────
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
                  style: AppTypography.arabicLarge
                      .copyWith(color: Colors.white, fontSize: 56),
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(height: 8),
                Text(word.transliteration,
                    style: AppTypography.bodyLarge
                        .copyWith(color: Colors.white70)),
                const SizedBox(height: 4),
                Text(word.translation,
                    style: AppTypography.headlineMedium
                        .copyWith(color: Colors.white)),
                const SizedBox(height: 4),
                Text(word.partOfSpeech,
                    style: AppTypography.bodySmall
                        .copyWith(color: Colors.white54)),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Play button ────────────────────────────────────────────────
          GestureDetector(
            onTap: () => _toggleAudio(word),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: _isPlaying
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color:
                      _isPlaying ? AppColors.primary : AppColors.border,
                  width: _isPlaying ? 2 : 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isLoading)
                    const SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                          color: AppColors.primary, strokeWidth: 2.5),
                    )
                  else
                    Icon(
                      _isPlaying
                          ? Icons.stop_circle_rounded
                          : Icons.play_circle_fill_rounded,
                      color: AppColors.primary,
                      size: 32,
                    ),
                  const SizedBox(width: 12),
                  Text(
                    _isLoading
                        ? 'Memuat audio...'
                        : _isPlaying
                            ? 'Menghentikan...'
                            : 'Dengarkan Pengucapan',
                    style: AppTypography.bodyLarge.copyWith(
                      color: _isPlaying
                          ? AppColors.primary
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Info fallback TTS
          if (word.audioUrl == null || word.audioUrl!.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Audio dihasilkan otomatis via Google Translate',
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.textMuted),
                textAlign: TextAlign.center,
              ),
            ),

          const SizedBox(height: 24),

          // ── Contoh kalimat ──────────────────────────────────────────────
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Contoh Kalimat',
                style: AppTypography.headlineMedium),
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
                    style: AppTypography.bodyMedium
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Did you know ───────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.goldLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.4)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_rounded,
                    color: AppColors.gold, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Kata "${word.translation}" dalam bahasa Arab termasuk '
                    '${word.partOfSpeech.toLowerCase()}. '
                    'Pelajari penggunaannya dalam konteks percakapan sehari-hari!',
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.goldDark),
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
