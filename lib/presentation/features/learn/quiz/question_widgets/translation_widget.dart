import 'package:flutter/material.dart';
import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_typography.dart';
import '../../../../../data/models/quiz_question_model.dart';

class TranslationWidget extends StatefulWidget {
  const TranslationWidget({
    super.key,
    required this.question,
    required this.showFeedback,
    required this.onAnswerChanged,
  });

  final QuizQuestion question;
  final bool showFeedback;
  final ValueChanged<String> onAnswerChanged;

  @override
  State<TranslationWidget> createState() => _TranslationWidgetState();
}

class _TranslationWidgetState extends State<TranslationWidget> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  bool get _isCorrect {
    return _controller.text.trim() == widget.question.correctAnswer.trim();
  }

  Color get _borderColor {
    if (!widget.showFeedback) return AppColors.border;
    return _isCorrect ? AppColors.success : AppColors.error;
  }

  Color get _fillColor {
    if (!widget.showFeedback) return AppColors.surface;
    return _isCorrect ? AppColors.successLight : AppColors.errorLight;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Source text to translate
        if (widget.question.arabicText != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              widget.question.arabicText!,
              style: AppTypography.bodyLarge.copyWith(
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),
        ],

        // Input field
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: _fillColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _borderColor, width: widget.showFeedback ? 2 : 1),
          ),
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            enabled: !widget.showFeedback,
            textDirection: TextDirection.rtl,
            maxLines: 3,
            minLines: 2,
            onChanged: (value) => widget.onAnswerChanged(value),
            style: AppTypography.arabicMedium.copyWith(fontSize: 18),
            decoration: InputDecoration(
              hintText: 'Ketik terjemahan bahasa Arab di sini...',
              hintStyle: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
              hintTextDirection: TextDirection.ltr,
              contentPadding: const EdgeInsets.all(16),
              border: InputBorder.none,
              suffixIcon: widget.showFeedback
                  ? Padding(
                      padding: const EdgeInsets.all(12),
                      child: Icon(
                        _isCorrect ? Icons.check_circle : Icons.cancel,
                        color: _isCorrect ? AppColors.success : AppColors.error,
                        size: 22,
                      ),
                    )
                  : null,
            ),
          ),
        ),

        // Correct answer reveal after feedback
        if (widget.showFeedback && !_isCorrect) ...[
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.lightbulb_outline_rounded, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Jawaban yang benar:',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.question.correctAnswer,
                      style: AppTypography.arabicMedium.copyWith(
                        fontSize: 16,
                        color: AppColors.primary,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],

        if (widget.showFeedback && widget.question.hint != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.school_outlined, size: 18, color: AppColors.textSecondary),
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
