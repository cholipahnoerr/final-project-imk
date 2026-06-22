class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.content,
    required this.type,
    required this.createdAt,
    this.duration,
  });

  final String id;
  final String chatId;
  final String senderId;
  final String content;
  final MessageType type;
  final DateTime createdAt;
  final int? duration; // detik, untuk voice note

  bool isMe(String currentUid) => senderId == currentUid;

  factory ChatMessage.fromMap(Map<String, dynamic> map, String id, String chatId) {
    return ChatMessage(
      id: id,
      chatId: chatId,
      senderId: map['senderId'] as String? ?? '',
      content: map['content'] as String? ?? '',
      type: map['type'] == 'voice' ? MessageType.voice : MessageType.text,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int? ?? 0),
      duration: map['duration'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'content': content,
      'type': type == MessageType.voice ? 'voice' : 'text',
      'createdAt': createdAt.millisecondsSinceEpoch,
      if (duration != null) 'duration': duration,
    };
  }
}

enum MessageType { text, voice }

String computeChatId(String uid1, String uid2) {
  final sorted = [uid1, uid2]..sort();
  return sorted.join('_');
}

class ChatConversation {
  const ChatConversation({
    required this.chatId,
    required this.participants,
    required this.participantNames,
    required this.participantPhotos,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.lastSenderId,
    required this.lastMessageType,
  });

  final String chatId;
  final List<String> participants;
  final Map<String, String> participantNames;
  final Map<String, String?> participantPhotos;
  final String lastMessage;
  final int lastMessageAt;
  final String lastSenderId;
  final String lastMessageType;

  String partnerIdFor(String myUid) =>
      participants.firstWhere((p) => p != myUid, orElse: () => '');

  String partnerNameFor(String myUid) =>
      participantNames[partnerIdFor(myUid)] ?? 'Unknown';

  String? partnerPhotoFor(String myUid) =>
      participantPhotos[partnerIdFor(myUid)];

  DateTime get lastMessageTime =>
      DateTime.fromMillisecondsSinceEpoch(lastMessageAt);

  factory ChatConversation.fromMap(Map<String, dynamic> map, String chatId) {
    final rawNames = map['participantNames'] as Map<dynamic, dynamic>? ?? {};
    final rawPhotos = map['participantPhotos'] as Map<dynamic, dynamic>? ?? {};
    return ChatConversation(
      chatId: chatId,
      participants: List<String>.from(map['participants'] as List<dynamic>? ?? []),
      participantNames: rawNames.map((k, v) => MapEntry(k.toString(), v.toString())),
      participantPhotos: rawPhotos.map((k, v) => MapEntry(k.toString(), v as String?)),
      lastMessage: map['lastMessage'] as String? ?? '',
      lastMessageAt: map['lastMessageAt'] as int? ?? 0,
      lastSenderId: map['lastSenderId'] as String? ?? '',
      lastMessageType: map['lastMessageType'] as String? ?? 'text',
    );
  }

  Map<String, dynamic> toMap() => {
        'participants': participants,
        'participantNames': participantNames,
        'participantPhotos': participantPhotos,
        'lastMessage': lastMessage,
        'lastMessageAt': lastMessageAt,
        'lastSenderId': lastSenderId,
        'lastMessageType': lastMessageType,
      };
}
