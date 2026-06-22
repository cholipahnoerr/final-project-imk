import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/auth_service.dart';
import '../../../data/models/chat_message_model.dart';
import '../home/home_viewmodel.dart';

final chatMessagesProvider =
    StreamProvider.family<List<ChatMessage>, String>((ref, partnerId) {
  final uid = ref.watch(firebaseAuthProvider).currentUser?.uid;
  if (uid == null) return Stream.value([]);
  final chatId = computeChatId(uid, partnerId);
  return ref.watch(firestoreDataSourceProvider).watchMessages(chatId);
});

final chatPartnerProvider =
    StreamProvider.family<ChatConversation?, String>((ref, partnerId) {
  final uid = ref.watch(firebaseAuthProvider).currentUser?.uid;
  if (uid == null) return Stream.value(null);
  final chatId = computeChatId(uid, partnerId);
  return ref.watch(firestoreDataSourceProvider).watchConversation(chatId);
});

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

  Future<void> sendVoiceNote(String filePath, int durationSeconds) async {
    final uid = ref.read(firebaseAuthProvider).currentUser?.uid;
    if (uid == null) return;
    final chatId = computeChatId(uid, arg);
    final url =
        await ref.read(firestoreDataSourceProvider).uploadVoiceNote(chatId, filePath);
    final message = ChatMessage(
      id: '',
      chatId: chatId,
      senderId: uid,
      content: url,
      type: MessageType.voice,
      createdAt: DateTime.now(),
      duration: durationSeconds,
    );
    await ref.read(firestoreDataSourceProvider).sendMessage(message);
  }

  Future<void> ensureChatExists(String? partnerName) async {
    final user = ref.read(currentUserProvider).valueOrNull ??
        await ref.read(currentUserProvider.future);
    if (user == null) return;
    String resolvedName = partnerName ?? '';
    if (resolvedName.isEmpty) {
      final partner = await ref.read(firestoreDataSourceProvider).getUser(arg);
      resolvedName = partner?.displayName ?? '';
    }
    await ref.read(firestoreDataSourceProvider).createOrGetChat(
          myUid: user.uid,
          myName: user.displayName,
          partnerUid: arg,
          partnerName: resolvedName,
          myPhoto: user.photoUrl,
        );
  }
}

final chatViewModelProvider =
    NotifierProviderFamily<ChatViewModel, void, String>(ChatViewModel.new);
