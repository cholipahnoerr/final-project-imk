import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/auth_service.dart';

class OnboardingState {
  const OnboardingState({
    this.selectedGoals = const [],
    this.selectedLevel,
    this.dailyTargetMinutes = 10,
    this.isLoading = false,
    this.error,
    this.isCompleted = false,
  });

  final List<String> selectedGoals;
  final String? selectedLevel;
  final int dailyTargetMinutes;
  final bool isLoading;
  final String? error;
  final bool isCompleted;

  OnboardingState copyWith({
    List<String>? selectedGoals,
    String? selectedLevel,
    int? dailyTargetMinutes,
    bool? isLoading,
    String? error,
    bool? isCompleted,
  }) {
    return OnboardingState(
      selectedGoals: selectedGoals ?? this.selectedGoals,
      selectedLevel: selectedLevel ?? this.selectedLevel,
      dailyTargetMinutes: dailyTargetMinutes ?? this.dailyTargetMinutes,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

class OnboardingViewModel extends Notifier<OnboardingState> {
  @override
  OnboardingState build() => const OnboardingState();

  void toggleGoal(String goal) {
    final current = List<String>.from(state.selectedGoals);
    if (current.contains(goal)) {
      current.remove(goal);
    } else {
      current.add(goal);
    }
    state = state.copyWith(selectedGoals: current);
  }

  void setLevel(String level) {
    state = state.copyWith(selectedLevel: level);
  }

  void setDailyTarget(int minutes) {
    state = state.copyWith(dailyTargetMinutes: minutes);
  }

  Future<void> completeOnboarding() async {
    if (state.selectedGoals.isEmpty || state.selectedLevel == null) return;
    state = state.copyWith(isLoading: true);
    try {
      final uid = ref.read(firebaseAuthProvider).currentUser?.uid;
      if (uid == null) throw Exception('User tidak ditemukan');
      await ref.read(firestoreDataSourceProvider).saveOnboardingData(
            uid: uid,
            learningGoal: state.selectedGoals.join(','),
            proficiencyLevel: state.selectedLevel!,
            dailyTargetMinutes: state.dailyTargetMinutes,
          );
      state = state.copyWith(isLoading: false, isCompleted: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Gagal menyimpan data. Coba lagi.');
    }
  }
}

final onboardingViewModelProvider = NotifierProvider<OnboardingViewModel, OnboardingState>(
  OnboardingViewModel.new,
);