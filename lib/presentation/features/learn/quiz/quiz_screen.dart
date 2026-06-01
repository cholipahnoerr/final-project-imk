import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../data/models/quiz_question_model.dart';
import '../../../common_widgets/primary_button.dart';
import 'quiz_viewmodel.dart';
import 'question_widgets/multiple_choice_widget.dart';
import 'question_widgets/audio_question_widget.dart';
import 'question_widgets/word_arrangement_widget.dart';
import 'question_widgets/character_tracing_widget.dart';
import 'question_widgets/pronunciation_widget.dart';
import 'question_widgets/translation_widget.dart';

class QuizScreen extends ConsumerWidget {
  const QuizScreen({super.key, required this.unitId, required this.lessonId});
  final String unitId;
  final String lessonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final args = (unitId: unitId, lessonId: lessonId);
    final state = ref.watch(quizViewModelProvider(args));
    final vm = ref.read(quizViewModelProvider(args).notifier);

    // Navigate to complete screen when quiz is done
    ref.listen(quizViewModelProvider(args), (prev, next) {
      if (prev?.phase != QuizPhase.complete && next.phase == QuizPhase.complete) {
        context.go(
          '/home/lesson-complete',
          extra: {
            'earnedXp': next.earnedXp,
            'stars': next.stars,
            'correctCount': next.correctCount,
            'totalCount': next.questions.length,
          },
        );
      }
    });

    if (state.phase == QuizPhase.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final question = state.currentQuestion;
    if (question == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final showFeedback = state.phase == QuizPhase.feedback;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _QuizHeader(
              progress: state.progress,
              hearts: state.hearts,
              onClose: () => context.pop(),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Prompt
                    Text(
                      question.prompt,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Question widget based on type
                    _buildQuestionWidget(question, state, vm, args, showFeedback),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            // Bottom action bar
            _BottomBar(
              phase: state.phase,
              isCorrect: state.isCorrect,
              correctAnswer: question.correctAnswer,
              hint: question.hint,
              selectedAnswer: state.selectedAnswer,
              onCheck: vm.submitAnswer,
              onNext: vm.next,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionWidget(
    QuizQuestion question,
    QuizState state,
    QuizViewModel vm,
    ({String unitId, String lessonId}) args,
    bool showFeedback,
  ) {
    switch (question.type) {
      case QuestionType.multipleChoice:
        return MultipleChoiceWidget(
          question: question,
          selectedAnswer: state.selectedAnswer,
          showFeedback: showFeedback,
          onSelect: vm.selectAnswer,
        );
      case QuestionType.audio:
        return AudioQuestionWidget(
          question: question,
          selectedAnswer: state.selectedAnswer,
          showFeedback: showFeedback,
          onSelect: vm.selectAnswer,
        );
      case QuestionType.wordArrangement:
        return WordArrangementWidget(
          question: question,
          showFeedback: showFeedback,
          onAnswerChanged: vm.selectAnswer,
        );
      case QuestionType.characterTracing:
        return CharacterTracingWidget(
          question: question,
          showFeedback: showFeedback,
          onAnswerChanged: vm.selectAnswer,
        );
      case QuestionType.pronunciation:
        return PronunciationWidget(
          question: question,
          showFeedback: showFeedback,
          onAnswerChanged: vm.selectAnswer,
        );
      case QuestionType.translation:
        return TranslationWidget(
          question: question,
          showFeedback: showFeedback,
          onAnswerChanged: vm.selectAnswer,
        );
    }
  }
}

class _QuizHeader extends StatelessWidget {
  const _QuizHeader({
    required this.progress,
    required this.hearts,
    required this.onClose,
  });

  final double progress;
  final int hearts;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: onClose,
            color: AppColors.textSecondary,
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 12,
                backgroundColor: AppColors.surfaceVariant,
                valueColor: const AlwaysStoppedAnimation(AppColors.primary),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Row(
            children: [
              const Icon(Icons.favorite_rounded, color: AppColors.hearts, size: 20),
              const SizedBox(width: 4),
              Text(
                '$hearts',
                style: AppTypography.titleMedium.copyWith(color: AppColors.hearts),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.phase,
    required this.isCorrect,
    required this.correctAnswer,
    required this.hint,
    required this.selectedAnswer,
    required this.onCheck,
    required this.onNext,
  });

  final QuizPhase phase;
  final bool? isCorrect;
  final String correctAnswer;
  final String? hint;
  final String? selectedAnswer;
  final VoidCallback onCheck;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    if (phase == QuizPhase.question) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: PrimaryButton(
          label: 'Periksa',
          onPressed: (selectedAnswer == null || selectedAnswer!.isEmpty) ? null : onCheck,
        ),
      );
    }

    // Feedback phase
    final correct = isCorrect ?? false;
    final color = correct ? AppColors.success : AppColors.error;
    final bgColor = correct ? AppColors.successLight : AppColors.errorLight;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(top: BorderSide(color: color, width: 2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(correct ? Icons.check_circle_rounded : Icons.cancel_rounded, color: color, size: 22),
              const SizedBox(width: 8),
              Text(
                correct ? 'Benar!' : 'Salah!',
                style: AppTypography.titleLarge.copyWith(color: color),
              ),
            ],
          ),
          if (!correct && correctAnswer.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Jawaban: $correctAnswer',
              style: AppTypography.bodyMedium.copyWith(color: color),
              textDirection: _isArabic(correctAnswer) ? TextDirection.rtl : TextDirection.ltr,
            ),
          ],
          if (hint != null) ...[
            const SizedBox(height: 6),
            Text(
              hint!,
              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: onNext,
              child: Text('Lanjut', style: AppTypography.labelLarge.copyWith(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  bool _isArabic(String text) {
    return text.codeUnits.any((c) => c >= 0x0600 && c <= 0x06FF);
  }
}
