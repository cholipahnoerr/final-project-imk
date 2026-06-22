import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/auth_service.dart';
import '../../../data/models/chat_message_model.dart';
import '../../../data/models/user_model.dart';

final conversationsProvider = StreamProvider.autoDispose<List<ChatConversation>>((ref) {
  final uid = ref.watch(firebaseAuthProvider).currentUser?.uid;
  if (uid == null) return Stream.value([]);
  return ref.watch(firestoreDataSourceProvider).watchUserConversations(uid);
});

class UserSearchNotifier extends AutoDisposeAsyncNotifier<List<UserModel>> {
  @override
  Future<List<UserModel>> build() async => [];

  Future<void> search(String query) async {
    final uid = ref.read(firebaseAuthProvider).currentUser?.uid ?? '';
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(firestoreDataSourceProvider).searchUsers(query, uid),
    );
  }

  void clear() => state = const AsyncData([]);
}

final userSearchProvider =
    AsyncNotifierProvider.autoDispose<UserSearchNotifier, List<UserModel>>(
  UserSearchNotifier.new,
);
