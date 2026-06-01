import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_typography.dart';
import '../../../../../core/services/audio_service.dart';
import '../../../../../data/models/quiz_question_model.dart';

class PronunciationWidget extends ConsumerStatefulWidget {
  const PronunciationWidget({
    super.key,
    required this.question,
    required this.showFeedback,
    required this.onAnswerChanged,
  });

  final QuizQuestion question;
  final bool showFeedback;
  final ValueChanged<String> onAnswerChanged;

  @override
  ConsumerState<PronunciationWidget> createState() => _PronunciationWidgetState();
}

class _PronunciationWidgetState extends ConsumerState<PronunciationWidget> {
  bool _isPlaying = false;
  bool _hasListened = false;
  String? _selfAssessment; // 'correct' or 'incorrect'

  Future<void> _playAudio() async {
    if (_isPlaying) return;
    setState(() => _isPlaying = true);
    if (widget.question.audioUrl != null && widget.question.audioUrl!.isNotEmpty) {
      await ref.read(audioServiceProvider).playUrl(widget.question.audioUrl!);
    } else {
      // No audio URL — simulate a brief pause for demo
      await Future.delayed(const Duration(milliseconds: 800));
    }
    if (mounted) {
      setState(() {
        _isPlaying = false;
        _hasListened = true;
      });
    }
  }

  void _assess(String result) {
    if (widget.showFeedback) return;
    setState(() => _selfAssessment = result);
    widget.onAnswerChanged(result);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Arabic text display
        if (widget.question.arabicText != null) ...[
          Text(
            widget.question.arabicText!,
            style: AppTypography.arabicLarge.copyWith(fontSize: 48),
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
        ],

        // Play button
        GestureDetector(
          onTap: _isPlaying || widget.showFeedback ? null : _playAudio,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
            decoration: BoxDecoration(
              color: _isPlaying
                  ? AppColors.primary.withValues(alpha: 0.12)
                  : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _isPlaying ? AppColors.primary : AppColors.border,
                width: _isPlaying ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isPlaying ? Icons.volume_up_rounded : Icons.play_circle_fill_rounded,
                  color: AppColors.primary,
                  size: 40,
                ),
                const SizedBox(width: 12),
                Text(
                  _isPlaying ? 'Memutar...' : 'Dengarkan contoh',
                  style: AppTypography.bodyMedium.copyWith(
                    color: _isPlaying ? AppColors.primary : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Instruction
        Text(
          _hasListened
              ? 'Sekarang ucapkan kata tersebut, lalu nilai diri sendiri:'
              : 'Dengarkan dulu, lalu coba ucapkan.',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 20),

        // Self-assessment buttons
        AnimatedOpacity(
          opacity: _hasListened && !widget.showFeedback ? 1.0 : (widget.showFeedback ? 0.5 : 0.3),
          duration: const Duration(milliseconds: 300),
          child: Row(
            children: [
              Expanded(
                child: _AssessButton(
                  label: 'Sudah benar',
                  icon: Icons.check_circle_outline_rounded,
                  color: AppColors.success,
                  selected: _selfAssessment == 'correct',
                  onTap: _hasListened && !widget.showFeedback
                      ? () => _assess('correct')
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _AssessButton(
                  label: 'Perlu latihan',
                  icon: Icons.replay_rounded,
                  color: AppColors.error,
                  selected: _selfAssessment == 'incorrect',
                  onTap: _hasListened && !widget.showFeedback
                      ? () => _assess('incorrect')
                      : null,
                ),
              ),
            ],
          ),
        ),

        if (widget.showFeedback && widget.question.hint != null) ...[
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.question.hint!,
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _AssessButton extends StatelessWidget {
  const _AssessButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? color : AppColors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? color : AppColors.textMuted, size: 28),
            const SizedBox(height: 6),
            Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: selected ? color : AppColors.textSecondary,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
