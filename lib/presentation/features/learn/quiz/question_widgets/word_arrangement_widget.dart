import 'package:flutter/material.dart';
import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_typography.dart';
import '../../../../../data/models/quiz_question_model.dart';

class WordArrangementWidget extends StatefulWidget {
  const WordArrangementWidget({
    super.key,
    required this.question,
    required this.showFeedback,
    required this.onAnswerChanged,
  });

  final QuizQuestion question;
  final bool showFeedback;
  final ValueChanged<String> onAnswerChanged;

  @override
  State<WordArrangementWidget> createState() => _WordArrangementWidgetState();
}

class _WordArrangementWidgetState extends State<WordArrangementWidget> {
  late List<String> _bank;    // Available words to pick
  late List<String> _answer;  // Words placed in answer

  @override
  void initState() {
    super.initState();
    _bank = List.from(widget.question.words)..shuffle();
    _answer = [];
  }

  void _pickWord(String word) {
    if (widget.showFeedback) return;
    setState(() {
      _bank.remove(word);
      _answer.add(word);
    });
    widget.onAnswerChanged(_answer.join(' '));
  }

  void _removeWord(int index) {
    if (widget.showFeedback) return;
    final word = _answer[index];
    setState(() {
      _answer.removeAt(index);
      _bank.add(word);
    });
    widget.onAnswerChanged(_answer.join(' '));
  }

  Color _answerBoxColor() {
    if (!widget.showFeedback) return AppColors.surfaceVariant;
    final isCorrect = _answer.join(' ') == widget.question.correctAnswer;
    return isCorrect ? AppColors.successLight : AppColors.errorLight;
  }

  Color _answerBorderColor() {
    if (!widget.showFeedback) return AppColors.border;
    final isCorrect = _answer.join(' ') == widget.question.correctAnswer;
    return isCorrect ? AppColors.success : AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Answer area
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          constraints: const BoxConstraints(minHeight: 64),
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _answerBoxColor(),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _answerBorderColor(), width: 2),
          ),
          child: _answer.isEmpty
              ? Center(
                  child: Text(
                    'Ketuk kata di bawah untuk menyusun kalimat',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                    textAlign: TextAlign.center,
                  ),
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _answer.asMap().entries.map((entry) {
                    return GestureDetector(
                      onTap: () => _removeWord(entry.key),
                      child: _WordChip(word: entry.value, placed: true),
                    );
                  }).toList(),
                ),
        ),
        const SizedBox(height: 24),
        // Word bank
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _bank.map((word) {
            return GestureDetector(
              onTap: () => _pickWord(word),
              child: _WordChip(word: word, placed: false),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _WordChip extends StatelessWidget {
  const _WordChip({required this.word, required this.placed});
  final String word;
  final bool placed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: placed ? AppColors.primary.withValues(alpha: 0.1) : AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: placed ? AppColors.primary : AppColors.border,
          width: placed ? 2 : 1,
        ),
      ),
      child: Text(
        word,
        style: AppTypography.arabicMedium.copyWith(fontSize: 16),
        textDirection: TextDirection.rtl,
      ),
    );
  }
}