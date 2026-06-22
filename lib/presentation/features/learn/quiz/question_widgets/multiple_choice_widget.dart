import 'package:flutter/material.dart';
import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_typography.dart';
import '../../../../../data/models/quiz_question_model.dart';

class MultipleChoiceWidget extends StatelessWidget {
  const MultipleChoiceWidget({
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
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (question.arabicText != null) ...[
          Center(
            child: Text(
              question.arabicText!,
              style: AppTypography.arabicLarge,
              textDirection: TextDirection.rtl,
            ),
          ),
          const SizedBox(height: 24),
        ],
        ...question.options.map((option) {
          final isSelected = selectedAnswer == option;
          final isCorrect = option == question.correctAnswer;

          Color bgColor = AppColors.surface;
          Color borderColor = AppColors.border;
          double borderWidth = 1;
          Widget? trailing;

          if (showFeedback) {
            if (isCorrect) {
              bgColor = AppColors.successLight;
              borderColor = AppColors.success;
              borderWidth = 2;
              trailing = const Icon(Icons.check_circle, color: AppColors.success, size: 22);
            } else if (isSelected) {
              bgColor = AppColors.errorLight;
              borderColor = AppColors.error;
              borderWidth = 2;
              trailing = const Icon(Icons.cancel, color: AppColors.error, size: 22);
            }
          } else if (isSelected) {
            bgColor = AppColors.primary.withValues(alpha: 0.08);
            borderColor = AppColors.primary;
            borderWidth = 2;
          }

          return GestureDetector(
            onTap: showFeedback ? null : () => onSelect(option),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderColor, width: borderWidth),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      option,
                      style: question.options.any((o) => _isArabic(o))
                          ? AppTypography.arabicMedium
                          : AppTypography.bodyLarge,
                      textDirection: _isArabic(option) ? TextDirection.rtl : TextDirection.ltr,
                    ),
                  ),
                  ?trailing,
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  bool _isArabic(String text) {
    return text.codeUnits.any((c) => c >= 0x0600 && c <= 0x06FF);
  }
}