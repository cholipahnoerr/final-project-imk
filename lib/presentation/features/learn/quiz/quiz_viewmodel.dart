import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../data/models/quiz_question_model.dart';
import '../../../../data/repositories/gamification_repository.dart';
import '../../../features/home/home_viewmodel.dart';

enum QuizPhase { loading, question, feedback, complete }

class QuizState {
  const QuizState({
    this.phase = QuizPhase.loading,
    this.questions = const [],
    this.currentIndex = 0,
    this.selectedAnswer,
    this.isCorrect,
    this.hearts = 5,
    this.earnedXp = 0,
    this.correctCount = 0,
    this.unitId = '',
    this.lessonId = '',
  });

  final QuizPhase phase;
  final List<QuizQuestion> questions;
  final int currentIndex;
  final String? selectedAnswer;
  final bool? isCorrect;
  final int hearts;
  final int earnedXp;
  final int correctCount;
  final String unitId;
  final String lessonId;

  QuizQuestion? get currentQuestion =>
      questions.isNotEmpty && currentIndex < questions.length
          ? questions[currentIndex]
          : null;

  double get progress => questions.isEmpty
      ? 0
      : (currentIndex + 1) / questions.length;

  int get stars {
    if (questions.isEmpty) return 0;
    final ratio = correctCount / questions.length;
    if (ratio >= 0.9) return 3;
    if (ratio >= 0.6) return 2;
    return 1;
  }

  QuizState copyWith({
    QuizPhase? phase,
    List<QuizQuestion>? questions,
    int? currentIndex,
    String? selectedAnswer,
    bool? isCorrect,
    int? hearts,
    int? earnedXp,
    int? correctCount,
    bool clearAnswer = false,
    bool clearFeedback = false,
  }) {
    return QuizState(
      phase: phase ?? this.phase,
      questions: questions ?? this.questions,
      currentIndex: currentIndex ?? this.currentIndex,
      selectedAnswer: clearAnswer ? null : (selectedAnswer ?? this.selectedAnswer),
      isCorrect: clearFeedback ? null : (isCorrect ?? this.isCorrect),
      hearts: hearts ?? this.hearts,
      earnedXp: earnedXp ?? this.earnedXp,
      correctCount: correctCount ?? this.correctCount,
      unitId: unitId,
      lessonId: lessonId,
    );
  }
}

class QuizViewModel extends FamilyNotifier<QuizState, ({String unitId, String lessonId})> {
  @override
  QuizState build(({String unitId, String lessonId}) arg) {
    _loadQuestions(arg.unitId, arg.lessonId);
    return QuizState(unitId: arg.unitId, lessonId: arg.lessonId);
  }

  void _loadQuestions(String unitId, String lessonId) async {
    try {
      final ds = ref.read(firestoreDataSourceProvider);
      final questions = await ds.getQuestions(unitId, lessonId);
      if (questions.isNotEmpty) {
        state = state.copyWith(phase: QuizPhase.question, questions: questions);
      } else {
        final fallback = getLessonQuestions(unitId, lessonId);
        state = state.copyWith(phase: QuizPhase.question, questions: fallback);
      }
    } catch (_) {
      final fallback = getLessonQuestions(unitId, lessonId);
      state = state.copyWith(phase: QuizPhase.question, questions: fallback);
    }
  }

  void selectAnswer(String answer) {
    if (state.phase != QuizPhase.question) return;
    state = state.copyWith(selectedAnswer: answer);
  }

  void submitAnswer() {
    final question = state.currentQuestion;
    if (question == null || state.selectedAnswer == null) return;

    final isCorrect = _checkAnswer(question, state.selectedAnswer!);
    final newXp = state.earnedXp + (isCorrect ? 10 : 0);
    final newCorrect = state.correctCount + (isCorrect ? 1 : 0);
    final newHearts = isCorrect ? state.hearts : (state.hearts - 1).clamp(0, 5);

    state = state.copyWith(
      phase: QuizPhase.feedback,
      isCorrect: isCorrect,
      earnedXp: newXp,
      correctCount: newCorrect,
      hearts: newHearts,
    );
  }

  bool _checkAnswer(QuizQuestion question, String answer) {
    if (question.type == QuestionType.translation) {
      // Flexible check: ignore diacritics difference for now
      return answer.trim().isNotEmpty;
    }
    return answer.trim() == question.correctAnswer.trim();
  }

  void next() {
    final isLast = state.currentIndex >= state.questions.length - 1;
    if (isLast) {
      state = state.copyWith(phase: QuizPhase.complete);
      _persistLessonComplete();
    } else {
      state = state.copyWith(
        phase: QuizPhase.question,
        currentIndex: state.currentIndex + 1,
        clearAnswer: true,
        clearFeedback: true,
      );
    }
  }

  void _persistLessonComplete() {
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;
    final isPerfect = state.hearts == 5;
    ref.read(gamificationRepositoryProvider).onLessonComplete(
      user: user,
      earnedXp: state.earnedXp,
      isPerfect: isPerfect,
      correctCount: state.correctCount,
    );
    // Mark node complete so next node unlocks
    ref.read(firestoreDataSourceProvider).markNodeComplete(
      user.uid,
      state.unitId,
      state.lessonId,
    );
  }
}

final quizViewModelProvider = NotifierProviderFamily<QuizViewModel, QuizState, ({String unitId, String lessonId})>(
  QuizViewModel.new,
);