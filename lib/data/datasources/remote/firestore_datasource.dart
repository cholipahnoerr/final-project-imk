import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/chat_message_model.dart';
import '../../models/user_model.dart';

class FirestoreDataSource {
  FirestoreDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  Future<void> createUser(UserModel user) async {
    await _users.doc(user.uid).set(user.toMap());
  }

  Future<UserModel?> getUser(String uid) async {
    final doc = await _users.doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserModel.fromMap(doc.data()!, uid);
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await _users.doc(uid).update(data);
  }

  Future<void> saveOnboardingData({
    required String uid,
    required String learningGoal,
    required String proficiencyLevel,
    required int dailyTargetMinutes,
  }) async {
    await _users.doc(uid).set({
      'learningGoal': learningGoal,
      'proficiencyLevel': proficiencyLevel,
      'dailyTargetMinutes': dailyTargetMinutes,
      'onboardingCompleted': true,
    }, SetOptions(merge: true)).timeout(const Duration(seconds: 15));
  }

  Stream<UserModel?> watchUser(String uid) {
    return _users.doc(uid).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return UserModel.fromMap(snap.data()!, uid);
    });
  }

  // Achievements subcollection: users/{uid}/achievements/{achievementId}
  Future<void> unlockAchievement(String uid, String achievementId) async {
    await _users.doc(uid).collection('achievements').doc(achievementId).set({
      'unlockedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Stream<List<String>> watchUnlockedAchievementIds(String uid) {
    return _users
        .doc(uid)
        .collection('achievements')
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.id).toList());
  }

  // ── Chat ────────────────────────────────────────────
  CollectionReference<Map<String, dynamic>> _messages(String chatId) =>
      _firestore.collection('chats').doc(chatId).collection('messages');

  Stream<List<ChatMessage>> watchMessages(String chatId) {
    return _messages(chatId)
        .orderBy('createdAt', descending: false)
        .limitToLast(50)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => ChatMessage.fromMap(d.data(), d.id, chatId))
            .toList());
  }

  Future<void> sendMessage(ChatMessage message) async {
    final chatRef = _firestore.collection('chats').doc(message.chatId);
    await Future.wait([
      _messages(message.chatId).add(message.toMap()),
      chatRef.set({
        'lastMessage': message.content,
        'lastMessageAt': message.createdAt.millisecondsSinceEpoch,
      }, SetOptions(merge: true)),
    ]);
  }
}