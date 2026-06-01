import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/auth_service.dart';
import '../../../data/models/chat_message_model.dart';

// Real-time message stream for a given partnerId
final chatMessagesProvider =
    StreamProvider.family<List<ChatMessage>, String>((ref, partnerId) {
  final uid = ref.watch(firebaseAuthProvider).currentUser?.uid;
  if (uid == null) return Stream.value([]);
  final chatId = computeChatId(uid, partnerId);
  return ref.watch(firestoreDataSourceProvider).watchMessages(chatId);
});

// Actions: send a message
class ChatViewModel extends FamilyNotifier<void, String> {
  @override
  void build(String partnerId) {}

  Future<void> sendText(String text) async {
    final uid = ref.read(firebaseAuthProvider).currentUser?.uid;
    if (uid == null || text.trim().isEmpty) return;
    final chatId = computeChatId(uid, arg);
    final message = ChatMessage(
      id: '',
      chatId: chatId,
      senderId: uid,
      content: text.trim(),
      type: MessageType.text,
      createdAt: DateTime.now(),
    );
    await ref.read(firestoreDataSourceProvider).sendMessage(message);
  }
}

final chatViewModelProvider =
    NotifierProviderFamily<ChatViewModel, void, String>(ChatViewModel.new);
