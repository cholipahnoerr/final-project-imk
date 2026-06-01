import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/auth_service.dart';

class OnboardingState {
  const OnboardingState({
    this.selectedGoal,
    this.selectedLevel,
    this.dailyTargetMinutes = 10,
    this.isLoading = false,
    this.error,
    this.isCompleted = false,
  });

  final String? selectedGoal;
  final String? selectedLevel;
  final int dailyTargetMinutes;
  final bool isLoading;
  final String? error;
  final bool isCompleted;

  OnboardingState copyWith({
    String? selectedGoal,
    String? selectedLevel,
    int? dailyTargetMinutes,
    bool? isLoading,
    String? error,
    bool? isCompleted,
  }) {
    return OnboardingState(
      selectedGoal: selectedGoal ?? this.selectedGoal,
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

  void setGoal(String goal) {
    state = state.copyWith(selectedGoal: goal);
  }

  void setLevel(String level) {
    state = state.copyWith(selectedLevel: level);
  }

  void setDailyTarget(int minutes) {
    state = state.copyWith(dailyTargetMinutes: minutes);
  }

  Future<void> completeOnboarding() async {
    if (state.selectedGoal == null || state.selectedLevel == null) return;
    state = state.copyWith(isLoading: true);
    try {
      final uid = ref.read(firebaseAuthProvider).currentUser?.uid;
      if (uid == null) throw Exception('User tidak ditemukan');
      await ref.read(firestoreDataSourceProvider).saveOnboardingData(
            uid: uid,
            learningGoal: state.selectedGoal!,
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