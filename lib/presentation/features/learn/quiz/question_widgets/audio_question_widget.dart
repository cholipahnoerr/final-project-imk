import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_typography.dart';
import '../../../../../core/services/audio_service.dart';
import '../../../../../data/models/quiz_question_model.dart';
import 'multiple_choice_widget.dart';

class AudioQuestionWidget extends ConsumerStatefulWidget {
  const AudioQuestionWidget({
    super.key,
    required this.question,
    required this.selectedAnswer,
    required this.showFeedback,
    required this.onSelect,
  });

  final QuizQuestion question;
  final String? selectedAnswer;
  final bool showFeedback;
  final ValueChanged<String> onSelect;

  @override
  ConsumerState<AudioQuestionWidget> createState() => _AudioQuestionWidgetState();
}

class _AudioQuestionWidgetState extends ConsumerState<AudioQuestionWidget> {
  bool _isPlaying = false;

  Future<void> _playAudio() async {
    if (widget.question.audioUrl == null || widget.question.audioUrl!.isEmpty) return;
    setState(() => _isPlaying = true);
    await ref.read(audioServiceProvider).playUrl(widget.question.audioUrl!);
    if (mounted) setState(() => _isPlaying = false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: _isPlaying ? null : _playAudio,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
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
            child: Column(
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    _isPlaying ? Icons.volume_up : Icons.play_circle_fill,
                    key: ValueKey(_isPlaying),
                    size: 64,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isPlaying ? 'Memutar...' : 'Ketuk untuk dengarkan',
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        MultipleChoiceWidget(
          question: widget.question,
          selectedAnswer: widget.selectedAnswer,
          showFeedback: widget.showFeedback,
          onSelect: widget.onSelect,
        ),
      ],
    );
  }
}