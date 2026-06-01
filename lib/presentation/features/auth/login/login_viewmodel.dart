import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../data/models/user_model.dart';

sealed class LoginState {
  const LoginState();
}

class LoginInitial extends LoginState {
  const LoginInitial();
}

class LoginLoading extends LoginState {
  const LoginLoading();
}

class LoginSuccess extends LoginState {
  const LoginSuccess(this.user);
  final UserModel user;
}

class LoginError extends LoginState {
  const LoginError(this.message);
  final String message;
}

class LoginViewModel extends Notifier<LoginState> {
  @override
  LoginState build() => const LoginInitial();

  Future<void> login(String email, String password) async {
    state = const LoginLoading();
    try {
      final repo = ref.read(authRepositoryProvider);
      final user = await repo.signInWithEmailAndPassword(email, password);
      state = LoginSuccess(user);
    } on FirebaseAuthException catch (e) {
      state = LoginError(_mapFirebaseError(e.code));
    } catch (e) {
      state = LoginError('Terjadi kesalahan. Coba lagi.');
    }
  }

  String _mapFirebaseError(String code) {
    return switch (code) {
      'user-not-found' => 'Email tidak terdaftar.',
      'wrong-password' || 'invalid-credential' => 'Email atau kata sandi salah.',
      'user-disabled' => 'Akun ini dinonaktifkan.',
      'too-many-requests' => 'Terlalu banyak percobaan. Coba lagi nanti.',
      _ => 'Login gagal. Periksa kembali email dan kata sandi.',
    };
  }
}

final loginViewModelProvider = NotifierProvider<LoginViewModel, LoginState>(
  LoginViewModel.new,
);