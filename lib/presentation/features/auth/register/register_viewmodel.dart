import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../data/models/user_model.dart';

sealed class RegisterState {
  const RegisterState();
}

class RegisterInitial extends RegisterState {
  const RegisterInitial();
}

class RegisterLoading extends RegisterState {
  const RegisterLoading();
}

class RegisterSuccess extends RegisterState {
  const RegisterSuccess(this.user);
  final UserModel user;
}

class RegisterError extends RegisterState {
  const RegisterError(this.message);
  final String message;
}

class RegisterViewModel extends Notifier<RegisterState> {
  @override
  RegisterState build() => const RegisterInitial();

  Future<void> register(String email, String password, String name) async {
    state = const RegisterLoading();
    try {
      final repo = ref.read(authRepositoryProvider);
      final user = await repo.signUpWithEmailAndPassword(email, password, name);
      state = RegisterSuccess(user);
    } on FirebaseAuthException catch (e) {
      state = RegisterError(_mapFirebaseError(e.code));
    } catch (e) {
      state = RegisterError('Pendaftaran gagal. Coba lagi.');
    }
  }

  String _mapFirebaseError(String code) {
    return switch (code) {
      'email-already-in-use' => 'Email sudah terdaftar. Coba masuk.',
      'weak-password' => 'Kata sandi terlalu lemah. Gunakan minimal 6 karakter.',
      'invalid-email' => 'Format email tidak valid.',
      _ => 'Pendaftaran gagal. Coba lagi.',
    };
  }
}

final registerViewModelProvider = NotifierProvider<RegisterViewModel, RegisterState>(
  RegisterViewModel.new,
);