class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.content,
    required this.type,
    required this.createdAt,
  });

  final String id;
  final String chatId;
  final String senderId;
  final String content;
  final MessageType type;
  final DateTime createdAt;

  bool isMe(String currentUid) => senderId == currentUid;

  factory ChatMessage.fromMap(Map<String, dynamic> map, String id, String chatId) {
    return ChatMessage(
      id: id,
      chatId: chatId,
      senderId: map['senderId'] as String? ?? '',
      content: map['content'] as String? ?? '',
      type: map['type'] == 'voice' ? MessageType.voice : MessageType.text,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int? ?? 0),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'content': content,
      'type': type == MessageType.voice ? 'voice' : 'text',
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }
}

enum MessageType { text, voice }

// Compute a deterministic chatId from two user IDs
String computeChatId(String uid1, String uid2) {
  final sorted = [uid1, uid2]..sort();
  return sorted.join('_');
}
