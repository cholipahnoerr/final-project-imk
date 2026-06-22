import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../../models/chat_message_model.dart';
import '../../models/learning_path_model.dart';
import '../../models/quiz_question_model.dart';
import '../../models/stream_content_model.dart';
import '../../models/user_model.dart';

class FirestoreDataSource {
  FirestoreDataSource(this._firestore, this._storage);

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

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

  Stream<List<UserModel>> watchLeaderboard(String league) {
    return _users
        .where('currentLeague', isEqualTo: league)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => UserModel.fromMap(d.data(), d.id))
          .toList();
      list.sort((a, b) => b.leagueXpThisWeek.compareTo(a.leagueXpThisWeek));
      return list;
    });
  }

  // â”€â”€ Chat â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  CollectionReference<Map<String, dynamic>> get _chats =>
      _firestore.collection('chats');

  CollectionReference<Map<String, dynamic>> _messages(String chatId) =>
      _chats.doc(chatId).collection('messages');

  Stream<List<ChatMessage>> watchMessages(String chatId) {
    return _messages(chatId)
        .orderBy('createdAt', descending: false)
        .limitToLast(50)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => ChatMessage.fromMap(d.data(), d.id, chatId))
            .toList());
  }

  Stream<List<ChatConversation>> watchUserConversations(String uid) {
    // Tanpa orderBy agar tidak butuh composite index Firestore — sort client-side
    return _chats
        .where('participants', arrayContains: uid)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => ChatConversation.fromMap(d.data(), d.id))
          .toList();
      list.sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
      return list;
    });
  }

  Stream<ChatConversation?> watchConversation(String chatId) {
    return _chats.doc(chatId).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return ChatConversation.fromMap(snap.data()!, snap.id);
    });
  }

  Future<String> createOrGetChat({
    required String myUid,
    required String myName,
    required String partnerUid,
    required String partnerName,
    String? myPhoto,
    String? partnerPhoto,
  }) async {
    final chatId = computeChatId(myUid, partnerUid);
    final ref = _chats.doc(chatId);
    final snap = await ref.get();
    if (!snap.exists) {
      await ref.set({
        'participants': [myUid, partnerUid],
        'participantNames': {myUid: myName, partnerUid: partnerName},
        'participantPhotos': {myUid: myPhoto, partnerUid: partnerPhoto},
        'lastMessage': '',
        'lastMessageAt': DateTime.now().millisecondsSinceEpoch,
        'lastSenderId': '',
        'lastMessageType': 'text',
      });
    } else {
      // Repair docs created without participants (e.g. by sendMessage before createOrGetChat ran)
      final data = snap.data()!;
      if (data['participants'] == null) {
        await ref.update({
          'participants': [myUid, partnerUid],
          'participantNames': {myUid: myName, partnerUid: partnerName},
          'participantPhotos': {myUid: myPhoto, partnerUid: partnerPhoto},
        });
      }
    }
    return chatId;
  }

  Future<List<UserModel>> searchUsers(String query, String excludeUid) async {
    if (query.trim().isEmpty) return [];
    final lq = query.toLowerCase().trim();
    final snap = await _users.limit(200).get();
    return snap.docs
        .map((d) => UserModel.fromMap(d.data(), d.id))
        .where((u) => u.uid != excludeUid && u.email.toLowerCase().contains(lq))
        .take(20)
        .toList();
  }

  Future<String> uploadVoiceNote(String chatId, String filePath) async {
    final file = File(filePath);
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.m4a';
    final ref = _storage.ref().child('voice_notes/$chatId/$fileName');
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  // â”€â”€ Admin â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Future<List<UserModel>> getAllUsers({int limit = 100}) async {
    final snap = await _users.orderBy('xp', descending: true).limit(limit).get();
    return snap.docs.map((d) => UserModel.fromMap(d.data(), d.id)).toList();
  }

  Future<void> setAdminRole(String uid, {required bool isAdmin}) async {
    await _users.doc(uid).update({'isAdmin': isAdmin});
  }

  Future<Map<String, int>> getAppStats() async {
    final snap = await _users.get();
    final users = snap.docs.map((d) => UserModel.fromMap(d.data(), d.id)).toList();
    return {
      'totalUsers': users.length,
      'onboardedUsers': users.where((u) => u.onboardingCompleted).length,
      'activeStreakUsers': users.where((u) => u.currentStreak > 0).length,
      'adminUsers': users.where((u) => u.isAdmin).length,
    };
  }

  Future<void> sendMessage(ChatMessage message) async {
    final lastMsg = message.type == MessageType.voice ? '🎵 Voice note' : message.content;
    // Always merge participants so watchUserConversations (arrayContains query) can find this chat
    await Future.wait([
      _messages(message.chatId).add(message.toMap()),
      _chats.doc(message.chatId).set({
        'participants': message.chatId.split('_'),
        'lastMessage': lastMsg,
        'lastMessageAt': message.createdAt.millisecondsSinceEpoch,
        'lastSenderId': message.senderId,
        'lastMessageType': message.type == MessageType.voice ? 'voice' : 'text',
      }, SetOptions(merge: true)),
    ]);
  }

  // â”€â”€ Words (Kata Hari Ini) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  CollectionReference<Map<String, dynamic>> get _words =>
      _firestore.collection('words');

  Stream<List<WordOfDay>> watchWords() {
    return _words.orderBy('createdAt', descending: true).snapshots().map(
        (s) => s.docs.map((d) => WordOfDay.fromMap(d.data(), d.id)).toList());
  }

  // Kata hari ini: cari yang scheduledDate == hari ini, fallback ke terbaru
  Stream<WordOfDay?> watchTodayWord() {
    final today = _todayString();
    return _words
        .where('scheduledDate', isEqualTo: today)
        .limit(1)
        .snapshots()
        .asyncMap((snap) async {
      if (snap.docs.isNotEmpty) {
        return WordOfDay.fromMap(snap.docs.first.data(), snap.docs.first.id);
      }
      final fallback = await _words.orderBy('createdAt', descending: true).limit(1).get();
      if (fallback.docs.isEmpty) return null;
      return WordOfDay.fromMap(fallback.docs.first.data(), fallback.docs.first.id);
    });
  }

  static String _todayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> addWord(WordOfDay word) async {
    await _words
        .add({...word.toMap(), 'createdAt': FieldValue.serverTimestamp()});
  }

  Future<void> updateWord(String id, Map<String, dynamic> data) async {
    await _words.doc(id).update(data);
  }

  Future<void> deleteWord(String id) async {
    await _words.doc(id).delete();
  }

  // â”€â”€ Trivias (Trivia Budaya) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  CollectionReference<Map<String, dynamic>> get _trivias =>
      _firestore.collection('trivias');

  Stream<List<CultureTrivia>> watchTrivias() {
    return _trivias.orderBy('createdAt', descending: true).snapshots().map(
        (s) =>
            s.docs.map((d) => CultureTrivia.fromMap(d.data(), d.id)).toList());
  }

  Future<void> addTrivia(CultureTrivia trivia) async {
    await _trivias
        .add({...trivia.toMap(), 'createdAt': FieldValue.serverTimestamp()});
  }

  Future<void> updateTrivia(String id, Map<String, dynamic> data) async {
    await _trivias.doc(id).update(data);
  }

  Future<void> deleteTrivia(String id) async {
    await _trivias.doc(id).delete();
  }

  // â”€â”€ Units â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  CollectionReference<Map<String, dynamic>> get _units =>
      _firestore.collection('units');

  Future<List<LearningUnit>> getUnitsWithNodes() async {
    final unitSnap = await _units.orderBy('order').get();
    final List<LearningUnit> units = [];
    for (final doc in unitSnap.docs) {
      final nodeSnap = await _units
          .doc(doc.id)
          .collection('nodes')
          .orderBy('order')
          .get();
      final nodes =
          nodeSnap.docs.map((d) => LessonNode.fromMap(d.data(), d.id)).toList();
      units.add(LearningUnit.fromMap(doc.data(), doc.id, nodes));
    }
    return units;
  }

  Future<void> addUnit(Map<String, dynamic> data) async {
    await _units.add(data);
  }

  Future<void> updateUnit(String id, Map<String, dynamic> data) async {
    await _units.doc(id).update(data);
  }

  Future<void> deleteUnit(String id) async {
    await _units.doc(id).delete();
  }

  // â”€â”€ Nodes â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Future<List<LessonNode>> getNodes(String unitId) async {
    final snap = await _units
        .doc(unitId)
        .collection('nodes')
        .orderBy('order')
        .get();
    return snap.docs.map((d) => LessonNode.fromMap(d.data(), d.id)).toList();
  }

  Future<void> addNode(String unitId, Map<String, dynamic> data) async {
    await _units.doc(unitId).collection('nodes').add(data);
  }

  Future<void> updateNode(
      String unitId, String nodeId, Map<String, dynamic> data) async {
    await _units.doc(unitId).collection('nodes').doc(nodeId).update(data);
  }

  Future<void> deleteNode(String unitId, String nodeId) async {
    await _units.doc(unitId).collection('nodes').doc(nodeId).delete();
  }

  // â”€â”€ Questions â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Future<List<QuizQuestion>> getQuestions(
      String unitId, String nodeId) async {
    final snap = await _units
        .doc(unitId)
        .collection('nodes')
        .doc(nodeId)
        .collection('questions')
        .orderBy('order')
        .get();
    return snap.docs
        .map((d) => QuizQuestion.fromMap(d.data(), d.id))
        .toList();
  }

  Future<void> addQuestion(
      String unitId, String nodeId, Map<String, dynamic> data) async {
    await _units
        .doc(unitId)
        .collection('nodes')
        .doc(nodeId)
        .collection('questions')
        .add(data);
  }

  Future<void> updateQuestion(String unitId, String nodeId, String qId,
      Map<String, dynamic> data) async {
    await _units
        .doc(unitId)
        .collection('nodes')
        .doc(nodeId)
        .collection('questions')
        .doc(qId)
        .update(data);
  }

  Future<void> deleteQuestion(
      String unitId, String nodeId, String qId) async {
    await _units
        .doc(unitId)
        .collection('nodes')
        .doc(nodeId)
        .collection('questions')
        .doc(qId)
        .delete();
  }

  // â”€â”€ User Progress â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Future<void> markNodeComplete(
      String uid, String unitId, String nodeId) async {
    await _users.doc(uid).update({
      'completedNodes': FieldValue.arrayUnion(['$unitId/$nodeId']),
    });
  }

  // â”€â”€ Seed data â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Future<void> seedContent() async {
    await _seedWords();
    await _seedTrivias();
    await _seedUnitsNodesQuestions();
    await _seedQuestionsForExistingNodes();
  }

  // Seed questions ke nodes yang sudah ada (bisa dipanggil ulang tanpa duplikat)
  Future<void> _seedQuestionsForExistingNodes() async {
    final unitSnap = await _units.get();
    for (final unitDoc in unitSnap.docs) {
      final unitTitle = unitDoc.data()['title'] as String? ?? '';
      final nodeSnap = await _units.doc(unitDoc.id).collection('nodes').get();
      for (final nodeDoc in nodeSnap.docs) {
        final nodeTitle = nodeDoc.data()['title'] as String? ?? '';
        final qSnap = await _units.doc(unitDoc.id).collection('nodes').doc(nodeDoc.id).collection('questions').limit(1).get();
        if (qSnap.docs.isNotEmpty) continue; // sudah ada soal
        final questions = _getQuestionsFor(unitTitle, nodeTitle);
        for (int i = 0; i < questions.length; i++) {
          await _units.doc(unitDoc.id).collection('nodes').doc(nodeDoc.id).collection('questions').add({...questions[i], 'order': i + 1});
        }
      }
    }
  }

  static List<Map<String, Object>> _getQuestionsFor(String unit, String node) {
    if (unit == 'Kosakata Dasar') {
      if (node == 'Benda di Rumah') return _questionsBendaDiRumah;
      if (node == 'Angka 1â€“10') return _questionsAngka;
      if (node == 'Warna') return _questionsWarna;
      if (node == 'Anggota Keluarga') return _questionsAnggotaKeluarga;
      if (node == 'Kuis Kosakata') return _questionsKuisKosakata;
    }
    if (unit == 'Percakapan') {
      if (node == 'Salam Pagi & Sore') return _questionsSalamPagi;
      if (node == 'Perkenalan Diri') return _questionsPerkenalan;
      if (node == 'Bertanya Kabar') return _questionsBertanyaKabar;
      if (node == 'Terima Kasih & Maaf') return _questionsTerimaMaaf;
      if (node == 'Dialog Lengkap') return _questionsDialogLengkap;
    }
    return [];
  }

  Future<void> _seedWords() async {
    final snap = await _words.limit(1).get();
    if (snap.docs.isNotEmpty) return;
    final seedWords = [
      {
        'arabic': 'Ù…ÙŽØ±Ù’Ø­ÙŽØ¨Ù‹Ø§', 'transliteration': 'Marhaban',
        'translation': 'Selamat Datang', 'partOfSpeech': 'Kata Seru',
        'exampleArabic': 'Ù…ÙŽØ±Ù’Ø­ÙŽØ¨Ù‹Ø§ Ø¨ÙÙƒÙŽ', 'exampleTranslation': 'Selamat datang kepadamu', 'level': 1,
      },
      {
        'arabic': 'Ø´ÙÙƒÙ’Ø±Ù‹Ø§', 'transliteration': 'Syukran',
        'translation': 'Terima Kasih', 'partOfSpeech': 'Kata Seru',
        'exampleArabic': 'Ø´ÙÙƒÙ’Ø±Ù‹Ø§ Ø¬ÙŽØ²ÙÙŠÙ„Ù‹Ø§', 'exampleTranslation': 'Terima kasih banyak', 'level': 1,
      },
      {
        'arabic': 'ØµÙŽØ¨ÙŽØ§Ø­Ù Ø§Ù„Ù’Ø®ÙŽÙŠÙ’Ø±Ù', 'transliteration': 'Sabahul Khair',
        'translation': 'Selamat Pagi', 'partOfSpeech': 'Frasa Sapaan',
        'exampleArabic': 'ØµÙŽØ¨ÙŽØ§Ø­Ù Ø§Ù„Ù’Ø®ÙŽÙŠÙ’Ø±Ù ÙŠÙŽØ§ Ø£ÙŽØµÙ’Ø¯ÙÙ‚ÙŽØ§Ø¡', 'exampleTranslation': 'Selamat pagi teman-teman', 'level': 1,
      },
      {
        'arabic': 'ÙƒÙØªÙŽØ§Ø¨ÙŒ', 'transliteration': 'KitÄbun',
        'translation': 'Buku', 'partOfSpeech': 'Kata Benda',
        'exampleArabic': 'Ù‡ÙŽØ°ÙŽØ§ ÙƒÙØªÙŽØ§Ø¨ÙŒ Ø¬ÙŽÙ…ÙÙŠÙ„ÙŒ', 'exampleTranslation': 'Ini adalah buku yang indah', 'level': 1,
      },
      {
        'arabic': 'Ù…ÙŽØ§Ø¡ÙŒ', 'transliteration': "Ma'un",
        'translation': 'Air', 'partOfSpeech': 'Kata Benda',
        'exampleArabic': 'Ø£ÙØ±ÙÙŠØ¯Ù Ù…ÙŽØ§Ø¡Ù‹', 'exampleTranslation': 'Saya ingin air', 'level': 1,
      },
    ];
    final now = DateTime.now();
    for (int i = 0; i < seedWords.length; i++) {
      final date = now.add(Duration(days: i));
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      await _words.add({...seedWords[i], 'scheduledDate': dateStr, 'createdAt': FieldValue.serverTimestamp()});
    }
  }

  Future<void> _seedTrivias() async {
    final snap = await _trivias.limit(1).get();
    if (snap.docs.isNotEmpty) return;
    for (final t in StreamContent.triviaList) {
      await _trivias.add({...t.toMap(), 'createdAt': FieldValue.serverTimestamp()});
    }
  }

  Future<void> _seedUnitsNodesQuestions() async {
    final snap = await _units.limit(1).get();
    if (snap.docs.isNotEmpty) return;

    // â”€â”€ Unit 1: Pengantar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    final u1 = await _units.add({'title': 'Pengantar', 'description': 'Huruf Hijaiyah & Salam Dasar', 'isUnlocked': true, 'order': 1});

    final n1 = await u1.collection('nodes').add({'title': 'Huruf Alifâ€“Ta', 'order': 1});
    for (final q in _questionsAlifTa) { await n1.collection('questions').add(q); }

    final n2 = await u1.collection('nodes').add({'title': 'Huruf Tsaâ€“Dal', 'order': 2});
    for (final q in _questionsTsaDal) { await n2.collection('questions').add(q); }

    final n3 = await u1.collection('nodes').add({'title': 'Huruf Dzalâ€“Sin', 'order': 3});
    for (final q in _questionsDzalSin) { await n3.collection('questions').add(q); }

    final n4 = await u1.collection('nodes').add({'title': 'Huruf Syinâ€“Dad', 'order': 4});
    for (final q in _questionsSyinDad) { await n4.collection('questions').add(q); }

    final n5 = await u1.collection('nodes').add({'title': 'Kuis Huruf', 'order': 5});
    for (final q in _questionsKuisHuruf) { await n5.collection('questions').add(q); }

    // â”€â”€ Unit 2: Kosakata Dasar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    final u2 = await _units.add({'title': 'Kosakata Dasar', 'description': 'Benda Sehari-hari & Angka', 'isUnlocked': false, 'order': 2});
    await u2.collection('nodes').add({'title': 'Benda di Rumah', 'order': 1});
    await u2.collection('nodes').add({'title': 'Angka 1â€“10', 'order': 2});
    await u2.collection('nodes').add({'title': 'Warna', 'order': 3});
    await u2.collection('nodes').add({'title': 'Anggota Keluarga', 'order': 4});
    await u2.collection('nodes').add({'title': 'Kuis Kosakata', 'order': 5});

    // â”€â”€ Unit 3: Percakapan â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    final u3 = await _units.add({'title': 'Percakapan', 'description': 'Salam & Perkenalan Diri', 'isUnlocked': false, 'order': 3});
    await u3.collection('nodes').add({'title': 'Salam Pagi & Sore', 'order': 1});
    await u3.collection('nodes').add({'title': 'Perkenalan Diri', 'order': 2});
    await u3.collection('nodes').add({'title': 'Bertanya Kabar', 'order': 3});
    await u3.collection('nodes').add({'title': 'Terima Kasih & Maaf', 'order': 4});
    await u3.collection('nodes').add({'title': 'Dialog Lengkap', 'order': 5});
  }

  // â”€â”€ Quiz Questions â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  static const _questionsAlifTa = [
    {'type': 'multipleChoice', 'prompt': 'Apa nama huruf ini?', 'arabicText': 'Ø§', 'options': ['Alif', 'Ba', 'Ta', 'Jim'], 'correctAnswer': 'Alif', 'hint': 'Ø§ adalah huruf pertama dalam abjad Arab.', 'order': 1},
    {'type': 'multipleChoice', 'prompt': 'Apa nama huruf ini?', 'arabicText': 'Ø¨', 'options': ['Alif', 'Ba', 'Ta', 'Tsa'], 'correctAnswer': 'Ba', 'hint': 'Ø¨ memiliki satu titik di bawah.', 'order': 2},
    {'type': 'multipleChoice', 'prompt': 'Apa nama huruf ini?', 'arabicText': 'Øª', 'options': ['Ba', 'Tsa', 'Ta', 'Jim'], 'correctAnswer': 'Ta', 'hint': 'Øª memiliki dua titik di atas.', 'order': 3},
    {'type': 'multipleChoice', 'prompt': 'Pilih huruf "Ba":',  'arabicText': '', 'options': ['Ø«', 'Ø§', 'Ø¨', 'Øª'], 'correctAnswer': 'Ø¨', 'hint': 'Ba ditulis dengan satu titik di bawah garis.', 'order': 4},
    {'type': 'multipleChoice', 'prompt': 'Pilih huruf "Ta":', 'arabicText': '', 'options': ['Ø§', 'Øª', 'Ø¨', 'Ø«'], 'correctAnswer': 'Øª', 'hint': 'Ta ditulis dengan dua titik di atas garis.', 'order': 5},
  ];

  static const _questionsTsaDal = [
    {'type': 'multipleChoice', 'prompt': 'Apa nama huruf ini?', 'arabicText': 'Ø«', 'options': ['Ta', 'Tsa', 'Jim', 'Ha'], 'correctAnswer': 'Tsa', 'hint': 'Ø« memiliki tiga titik di atas.', 'order': 1},
    {'type': 'multipleChoice', 'prompt': 'Apa nama huruf ini?', 'arabicText': 'Ø¬', 'options': ['Ha', 'Kha', 'Jim', 'Dal'], 'correctAnswer': 'Jim', 'hint': 'Ø¬ memiliki satu titik di bawah.', 'order': 2},
    {'type': 'multipleChoice', 'prompt': 'Apa nama huruf ini?', 'arabicText': 'Ø­', 'options': ['Jim', 'Ha', 'Kha', 'Dal'], 'correctAnswer': 'Ha', 'hint': 'Ø­ tidak memiliki titik sama sekali.', 'order': 3},
    {'type': 'multipleChoice', 'prompt': 'Apa nama huruf ini?', 'arabicText': 'Ø®', 'options': ['Ha', 'Jim', 'Kha', 'Tsa'], 'correctAnswer': 'Kha', 'hint': 'Ø® memiliki satu titik di atas.', 'order': 4},
    {'type': 'multipleChoice', 'prompt': 'Apa nama huruf ini?', 'arabicText': 'Ø¯', 'options': ['Dzal', 'Dal', 'Ra', 'Zai'], 'correctAnswer': 'Dal', 'hint': 'Ø¯ tanpa titik, bentuk seperti sudut.', 'order': 5},
  ];

  static const _questionsDzalSin = [
    {'type': 'multipleChoice', 'prompt': 'Apa nama huruf ini?', 'arabicText': 'Ø°', 'options': ['Dal', 'Dzal', 'Ra', 'Zai'], 'correctAnswer': 'Dzal', 'hint': 'Ø° seperti Dal tapi dengan satu titik di atas.', 'order': 1},
    {'type': 'multipleChoice', 'prompt': 'Apa nama huruf ini?', 'arabicText': 'Ø±', 'options': ['Dal', 'Dzal', 'Ra', 'Zai'], 'correctAnswer': 'Ra', 'hint': 'Ø± seperti koma tanpa titik, melengkung ke bawah.', 'order': 2},
    {'type': 'multipleChoice', 'prompt': 'Apa nama huruf ini?', 'arabicText': 'Ø²', 'options': ['Ra', 'Dzal', 'Dal', 'Zai'], 'correctAnswer': 'Zai', 'hint': 'Ø² seperti Ra tapi dengan satu titik di atas.', 'order': 3},
    {'type': 'multipleChoice', 'prompt': 'Apa nama huruf ini?', 'arabicText': 'Ø³', 'options': ['Sin', 'Syin', 'Shad', 'Dhad'], 'correctAnswer': 'Sin', 'hint': 'Ø³ tiga tonjolan kecil di bawah tanpa titik.', 'order': 4},
    {'type': 'multipleChoice', 'prompt': 'Pilih huruf "Ra":', 'arabicText': '', 'options': ['Ø°', 'Ø±', 'Ø²', 'Ø³'], 'correctAnswer': 'Ø±', 'hint': 'Ra melengkung ke bawah tanpa titik.', 'order': 5},
  ];

  static const _questionsSyinDad = [
    {'type': 'multipleChoice', 'prompt': 'Apa nama huruf ini?', 'arabicText': 'Ø´', 'options': ['Sin', 'Syin', 'Shad', 'Dhad'], 'correctAnswer': 'Syin', 'hint': 'Ø´ seperti Sin dengan tiga titik di atas.', 'order': 1},
    {'type': 'multipleChoice', 'prompt': 'Apa nama huruf ini?', 'arabicText': 'Øµ', 'options': ['Syin', 'Shad', 'Dhad', 'Tha'], 'correctAnswer': 'Shad', 'hint': 'Øµ bulat besar dengan ekor ke kiri.', 'order': 2},
    {'type': 'multipleChoice', 'prompt': 'Apa nama huruf ini?', 'arabicText': 'Ø¶', 'options': ['Shad', 'Dhad', 'Tha', 'Zha'], 'correctAnswer': 'Dhad', 'hint': 'Ø¶ seperti Shad dengan titik satu di atas.', 'order': 3},
    {'type': 'multipleChoice', 'prompt': 'Pilih huruf "Syin":', 'arabicText': '', 'options': ['Ø³', 'Ø´', 'Øµ', 'Ø¶'], 'correctAnswer': 'Ø´', 'hint': 'Syin memiliki tiga titik di atas bentuk Sin.', 'order': 4},
    {'type': 'multipleChoice', 'prompt': 'Pilih huruf "Shad":', 'arabicText': '', 'options': ['Ø´', 'Øµ', 'Ø¶', 'Ø·'], 'correctAnswer': 'Øµ', 'hint': 'Shad tidak memiliki titik, bulat besar.', 'order': 5},
  ];

  static const _questionsKuisHuruf = [
    {'type': 'multipleChoice', 'prompt': 'Huruf apakah ini?', 'arabicText': 'Ø§', 'options': ['Alif', 'Ba', 'Ta', 'Dal'], 'correctAnswer': 'Alif', 'hint': 'Huruf pertama dalam abjad Arab.', 'order': 1},
    {'type': 'multipleChoice', 'prompt': 'Huruf apakah ini?', 'arabicText': 'Ø¬', 'options': ['Ha', 'Jim', 'Kha', 'Sin'], 'correctAnswer': 'Jim', 'hint': 'Jim memiliki satu titik di bawah.', 'order': 2},
    {'type': 'multipleChoice', 'prompt': 'Huruf apakah ini?', 'arabicText': 'Ø³', 'options': ['Syin', 'Shad', 'Sin', 'Dzal'], 'correctAnswer': 'Sin', 'hint': 'Sin punya tiga tonjolan tanpa titik.', 'order': 3},
    {'type': 'multipleChoice', 'prompt': 'Pilih huruf "Dzal":', 'arabicText': '', 'options': ['Ø¯', 'Ø°', 'Ø±', 'Ø²'], 'correctAnswer': 'Ø°', 'hint': 'Dzal seperti Dal dengan titik satu di atas.', 'order': 4},
    {'type': 'wordArrangement', 'prompt': 'Susun huruf-huruf ini menjadi kata "Ø¨ÙŽÙŠÙ’Øª" (rumah):', 'arabicText': '', 'words': ['Ø¨ÙŽ', 'ÙŠÙ’', 'Øª'], 'correctAnswer': 'Ø¨ÙŽÙŠÙ’Øª', 'hint': 'Ø¨ÙŽÙŠÙ’Øª (bayt) artinya rumah.', 'order': 5},
  ];

  // â”€â”€ Unit 2: Benda di Rumah â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static const _questionsBendaDiRumah = [
    {'type': 'multipleChoice', 'prompt': 'Apa arti dari kata "ÙƒÙØªÙŽØ§Ø¨ÙŒ"?', 'arabicText': 'ÙƒÙØªÙŽØ§Ø¨ÙŒ', 'options': ['Rumah', 'Buku', 'Pena', 'Meja'], 'correctAnswer': 'Buku', 'hint': 'ÙƒÙØªÙŽØ§Ø¨ÙŒ (Kitaabun) artinya buku.'},
    {'type': 'multipleChoice', 'prompt': 'Pilihlah bahasa Arab yang tepat untuk kata "Rumah":', 'arabicText': '', 'options': ['Ù…ÙŽØ¯Ù’Ø±ÙŽØ³ÙŽØ©ÙŒ', 'Ø¨ÙŽÙŠÙ’ØªÙŒ', 'Ù…ÙŽØ³Ù’Ø¬ÙØ¯ÙŒ', 'Ø¨ÙŽØ§Ø¨ÙŒ'], 'correctAnswer': 'Ø¨ÙŽÙŠÙ’ØªÙŒ', 'hint': 'Ø¨ÙŽÙŠÙ’ØªÙŒ (Baitun) artinya rumah.'},
    {'type': 'multipleChoice', 'prompt': 'Apa arti dari kata "Ù‚ÙŽÙ„ÙŽÙ…ÙŒ"?', 'arabicText': 'Ù‚ÙŽÙ„ÙŽÙ…ÙŒ', 'options': ['Kertas', 'Penghapus', 'Pena', 'Tas'], 'correctAnswer': 'Pena', 'hint': 'Ù‚ÙŽÙ„ÙŽÙ…ÙŒ (Qalamun) artinya pena.'},
    {'type': 'wordArrangement', 'prompt': 'Terjemahkan: "Ini adalah buku baru"', 'arabicText': '', 'words': ['Ø¬ÙŽØ¯ÙÙŠØ¯ÙŒ', 'ÙƒÙØªÙŽØ§Ø¨ÙŒ', 'Ù‡ÙŽÙ°Ø°ÙŽØ§'], 'correctAnswer': 'Ù‡ÙŽÙ°Ø°ÙŽØ§ ÙƒÙØªÙŽØ§Ø¨ÙŒ Ø¬ÙŽØ¯ÙÙŠØ¯ÙŒ', 'hint': 'Ù‡ÙŽÙ°Ø°ÙŽØ§ = ini, ÙƒÙØªÙŽØ§Ø¨ÙŒ = buku, Ø¬ÙŽØ¯ÙÙŠØ¯ÙŒ = baru.'},
    {'type': 'multipleChoice', 'prompt': '"Ø§Ù„Ù’Ù‚ÙŽÙ„ÙŽÙ…Ù ........... Ø§Ù„Ù’Ù…ÙŽÙƒÙ’ØªÙŽØ¨Ù" (Pena itu di atas meja)', 'arabicText': '', 'options': ['ÙÙÙŠ', 'Ø¹ÙŽÙ„ÙŽÙ‰', 'ØªÙŽØ­Ù’ØªÙŽ', 'Ù…ÙÙ†Ù’'], 'correctAnswer': 'Ø¹ÙŽÙ„ÙŽÙ‰', 'hint': 'Ø¹ÙŽÙ„ÙŽÙ‰ artinya "di atas".'},
  ];

  static const _questionsAnggotaKeluarga = [
    {'type': 'multipleChoice', 'prompt': 'Apa arti dari kata "Ø£ÙŽØ¨ÙŒ"?', 'arabicText': 'Ø£ÙŽØ¨ÙŒ', 'options': ['Kakek', 'Paman', 'Ayah', 'Saudara'], 'correctAnswer': 'Ayah', 'hint': 'Ø£ÙŽØ¨ÙŒ (Abun) artinya ayah.'},
    {'type': 'multipleChoice', 'prompt': 'Pilihlah bahasa Arab yang tepat untuk kata "Ibu":', 'arabicText': '', 'options': ['Ø£ÙØ®Ù’ØªÙŒ', 'Ø£ÙÙ…ÙŒÙ‘', 'Ø¬ÙŽØ¯ÙŽÙ‘Ø©ÙŒ', 'Ø¹ÙŽÙ…ÙŽÙ‘Ø©ÙŒ'], 'correctAnswer': 'Ø£ÙÙ…ÙŒÙ‘', 'hint': 'Ø£ÙÙ…ÙŒÙ‘ (Ummun) artinya ibu.'},
    {'type': 'multipleChoice', 'prompt': 'Apa arti dari kata "Ø¬ÙŽØ¯ÙŒÙ‘"?', 'arabicText': 'Ø¬ÙŽØ¯ÙŒÙ‘', 'options': ['Kakek', 'Nenek', 'Kakak', 'Adik'], 'correctAnswer': 'Kakek', 'hint': 'Ø¬ÙŽØ¯ÙŒÙ‘ (Jaddun) artinya kakek.'},
    {'type': 'wordArrangement', 'prompt': 'Terjemahkan: "Ini adalah ayahku"', 'arabicText': '', 'words': ['Ø£ÙŽØ¨ÙÙŠ', 'Ù‡ÙŽÙ°Ø°ÙŽØ§', 'Ø£ÙÙ…ÙÙ‘ÙŠ'], 'correctAnswer': 'Ù‡ÙŽÙ°Ø°ÙŽØ§ Ø£ÙŽØ¨ÙÙŠ', 'hint': 'Ù‡ÙŽÙ°Ø°ÙŽØ§ = ini (untuk lk), Ø£ÙŽØ¨ÙÙŠ = ayahku.'},
    {'type': 'multipleChoice', 'prompt': 'Ahmad: "Ù…ÙŽÙ†Ù’ Ù‡ÙŽÙ°Ø°ÙŽØ§ØŸ" â€” Zaid: "........... Ø£ÙŽØ¨ÙÙŠ"', 'arabicText': '', 'options': ['Ù‡ÙŽÙ°Ø°ÙÙ‡Ù', 'Ù‡ÙŽÙ°Ø°ÙŽØ§', 'ØªÙÙ„Ù’ÙƒÙŽ', 'Ø£ÙŽÙ†ÙŽØ§'], 'correctAnswer': 'Ù‡ÙŽÙ°Ø°ÙŽØ§', 'hint': 'Ù‡ÙŽÙ°Ø°ÙŽØ§ digunakan untuk benda/orang laki-laki.'},
  ];

  // â”€â”€ Unit 2: Angka 1â€“10 â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static const _questionsAngka = [
    {'type': 'multipleChoice', 'prompt': 'Apa bahasa Arab dari angka "3"?', 'arabicText': '', 'options': ['Ø§Ø«Ù’Ù†ÙŽØ§Ù†Ù', 'Ø«ÙŽÙ„ÙŽØ§Ø«ÙŽØ©ÙŒ', 'Ø£ÙŽØ±Ù’Ø¨ÙŽØ¹ÙŽØ©ÙŒ', 'Ø®ÙŽÙ…Ù’Ø³ÙŽØ©ÙŒ'], 'correctAnswer': 'Ø«ÙŽÙ„ÙŽØ§Ø«ÙŽØ©ÙŒ', 'hint': 'Ø«ÙŽÙ„ÙŽØ§Ø«ÙŽØ©ÙŒ (TsalÄtsatun) = tiga.'},
    {'type': 'multipleChoice', 'prompt': 'Apa arti dari "Ø®ÙŽÙ…Ù’Ø³ÙŽØ©ÙŒ"?', 'arabicText': 'Ø®ÙŽÙ…Ù’Ø³ÙŽØ©ÙŒ', 'options': ['Empat', 'Lima', 'Enam', 'Tujuh'], 'correctAnswer': 'Lima', 'hint': 'Ø®ÙŽÙ…Ù’Ø³ÙŽØ©ÙŒ (Khamsatun) = lima.'},
    {'type': 'multipleChoice', 'prompt': 'Apa bahasa Arab dari angka "7"?', 'arabicText': '', 'options': ['Ø³ÙØªÙŽÙ‘Ø©ÙŒ', 'Ø³ÙŽØ¨Ù’Ø¹ÙŽØ©ÙŒ', 'Ø«ÙŽÙ…ÙŽØ§Ù†ÙÙŠÙŽØ©ÙŒ', 'ØªÙØ³Ù’Ø¹ÙŽØ©ÙŒ'], 'correctAnswer': 'Ø³ÙŽØ¨Ù’Ø¹ÙŽØ©ÙŒ', 'hint': 'Ø³ÙŽØ¨Ù’Ø¹ÙŽØ©ÙŒ (Sab\'atun) = tujuh.'},
    {'type': 'multipleChoice', 'prompt': 'Apa arti dari "Ø¹ÙŽØ´ÙŽØ±ÙŽØ©ÙŒ"?', 'arabicText': 'Ø¹ÙŽØ´ÙŽØ±ÙŽØ©ÙŒ', 'options': ['Delapan', 'Sembilan', 'Sepuluh', 'Sebelas'], 'correctAnswer': 'Sepuluh', 'hint': 'Ø¹ÙŽØ´ÙŽØ±ÙŽØ©ÙŒ (\'Asyaratun) = sepuluh.'},
    {'type': 'wordArrangement', 'prompt': 'Terjemahkan: "Saya punya lima buku"', 'arabicText': '', 'words': ['ÙƒÙØªÙØ¨Ù', 'Ø¹ÙÙ†Ù’Ø¯ÙÙŠ', 'Ø®ÙŽÙ…Ù’Ø³ÙŽØ©Ù'], 'correctAnswer': 'Ø¹ÙÙ†Ù’Ø¯ÙÙŠ Ø®ÙŽÙ…Ù’Ø³ÙŽØ©Ù ÙƒÙØªÙØ¨Ù', 'hint': 'Ø¹ÙÙ†Ù’Ø¯ÙÙŠ = saya punya, Ø®ÙŽÙ…Ù’Ø³ÙŽØ©Ù = lima, ÙƒÙØªÙØ¨Ù = buku-buku.'},
  ];

  // â”€â”€ Unit 2: Warna â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static const _questionsWarna = [
    {'type': 'multipleChoice', 'prompt': 'Apa arti dari "Ø£ÙŽØ­Ù’Ù…ÙŽØ±Ù"?', 'arabicText': 'Ø£ÙŽØ­Ù’Ù…ÙŽØ±Ù', 'options': ['Biru', 'Merah', 'Hijau', 'Kuning'], 'correctAnswer': 'Merah', 'hint': 'Ø£ÙŽØ­Ù’Ù…ÙŽØ±Ù (Ahmar) = merah.'},
    {'type': 'multipleChoice', 'prompt': 'Pilihlah bahasa Arab untuk warna "Biru":', 'arabicText': '', 'options': ['Ø£ÙŽØ®Ù’Ø¶ÙŽØ±Ù', 'Ø£ÙŽØµÙ’ÙÙŽØ±Ù', 'Ø£ÙŽØ²Ù’Ø±ÙŽÙ‚Ù', 'Ø£ÙŽØ¨Ù’ÙŠÙŽØ¶Ù'], 'correctAnswer': 'Ø£ÙŽØ²Ù’Ø±ÙŽÙ‚Ù', 'hint': 'Ø£ÙŽØ²Ù’Ø±ÙŽÙ‚Ù (Azraq) = biru.'},
    {'type': 'multipleChoice', 'prompt': 'Apa arti dari "Ø£ÙŽØµÙ’ÙÙŽØ±Ù"?', 'arabicText': 'Ø£ÙŽØµÙ’ÙÙŽØ±Ù', 'options': ['Hijau', 'Putih', 'Hitam', 'Kuning'], 'correctAnswer': 'Kuning', 'hint': 'Ø£ÙŽØµÙ’ÙÙŽØ±Ù (Asfar) = kuning.'},
    {'type': 'wordArrangement', 'prompt': 'Terjemahkan: "Buku itu berwarna merah"', 'arabicText': '', 'words': ['Ø£ÙŽØ­Ù’Ù…ÙŽØ±Ù', 'Ø§Ù„Ù’ÙƒÙØªÙŽØ§Ø¨Ù', 'Ø£ÙŽØ²Ù’Ø±ÙŽÙ‚Ù'], 'correctAnswer': 'Ø§Ù„Ù’ÙƒÙØªÙŽØ§Ø¨Ù Ø£ÙŽØ­Ù’Ù…ÙŽØ±Ù', 'hint': 'Ø§Ù„Ù’ÙƒÙØªÙŽØ§Ø¨Ù = buku itu, Ø£ÙŽØ­Ù’Ù…ÙŽØ±Ù = merah.'},
    {'type': 'multipleChoice', 'prompt': 'Ahmad: "Ù…ÙŽØ§ Ù„ÙŽÙˆÙ’Ù†Ù Ø§Ù„Ø³ÙŽÙ‘ÙŠÙŽÙ‘Ø§Ø±ÙŽØ©ÙØŸ" â€” Zaid: "Ù‡ÙÙŠÙŽ ..........."', 'arabicText': '', 'options': ['ÙƒÙŽØ¨ÙÙŠØ±ÙŽØ©ÙŒ', 'Ø¨ÙŽÙŠÙ’Ø¶ÙŽØ§Ø¡Ù', 'Ø¬ÙŽØ¯ÙÙŠØ¯ÙŽØ©ÙŒ', 'Ø³ÙŽØ±ÙÙŠØ¹ÙŽØ©ÙŒ'], 'correctAnswer': 'Ø¨ÙŽÙŠÙ’Ø¶ÙŽØ§Ø¡Ù', 'hint': 'Ø¨ÙŽÙŠÙ’Ø¶ÙŽØ§Ø¡Ù (Baydaa) = putih (untuk kata benda perempuan).'},
  ];

  // â”€â”€ Unit 2: Kuis Kosakata â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static const _questionsKuisKosakata = [
    {'type': 'multipleChoice', 'prompt': 'Apa arti "Ù‚ÙŽÙ„ÙŽÙ…ÙŒ"?', 'arabicText': 'Ù‚ÙŽÙ„ÙŽÙ…ÙŒ', 'options': ['Buku', 'Pena', 'Meja', 'Kursi'], 'correctAnswer': 'Pena', 'hint': 'Ù‚ÙŽÙ„ÙŽÙ…ÙŒ (Qalam) = pena.'},
    {'type': 'multipleChoice', 'prompt': 'Bahasa Arab untuk "Ibu" adalah:', 'arabicText': '', 'options': ['Ø£ÙŽØ¨ÙŒ', 'Ø£ÙØ®Ù’ØªÙŒ', 'Ø£ÙÙ…ÙŒÙ‘', 'Ø¬ÙŽØ¯ÙŽÙ‘Ø©ÙŒ'], 'correctAnswer': 'Ø£ÙÙ…ÙŒÙ‘', 'hint': 'Ø£ÙÙ…ÙŒÙ‘ (Umm) = ibu.'},
    {'type': 'multipleChoice', 'prompt': 'Apa bahasa Arab untuk angka "Lima"?', 'arabicText': '', 'options': ['Ø£ÙŽØ±Ù’Ø¨ÙŽØ¹ÙŽØ©ÙŒ', 'Ø®ÙŽÙ…Ù’Ø³ÙŽØ©ÙŒ', 'Ø³ÙØªÙŽÙ‘Ø©ÙŒ', 'Ø³ÙŽØ¨Ù’Ø¹ÙŽØ©ÙŒ'], 'correctAnswer': 'Ø®ÙŽÙ…Ù’Ø³ÙŽØ©ÙŒ', 'hint': 'Ø®ÙŽÙ…Ù’Ø³ÙŽØ©ÙŒ (Khamsa) = lima.'},
    {'type': 'multipleChoice', 'prompt': 'Apa arti "Ø£ÙŽØ®Ù’Ø¶ÙŽØ±Ù"?', 'arabicText': 'Ø£ÙŽØ®Ù’Ø¶ÙŽØ±Ù', 'options': ['Merah', 'Biru', 'Hijau', 'Kuning'], 'correctAnswer': 'Hijau', 'hint': 'Ø£ÙŽØ®Ù’Ø¶ÙŽØ±Ù (Akhdar) = hijau.'},
    {'type': 'wordArrangement', 'prompt': 'Terjemahkan: "Ini adalah buku"', 'arabicText': '', 'words': ['Ù‡ÙŽÙ°Ø°ÙŽØ§', 'Ù‚ÙŽÙ„ÙŽÙ…ÙŒ', 'ÙƒÙØªÙŽØ§Ø¨ÙŒ'], 'correctAnswer': 'Ù‡ÙŽÙ°Ø°ÙŽØ§ ÙƒÙØªÙŽØ§Ø¨ÙŒ', 'hint': 'Ù‡ÙŽÙ°Ø°ÙŽØ§ = ini, ÙƒÙØªÙŽØ§Ø¨ÙŒ = buku.'},
  ];

  // â”€â”€ Unit 3: Salam Pagi & Sore â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static const _questionsSalamPagi = [
    {'type': 'multipleChoice', 'prompt': '"ØµÙŽØ¨ÙŽØ§Ø­Ù Ø§Ù„Ù’Ø®ÙŽÙŠÙ’Ø±Ù" artinya?', 'arabicText': 'ØµÙŽØ¨ÙŽØ§Ø­Ù Ø§Ù„Ù’Ø®ÙŽÙŠÙ’Ø±Ù', 'options': ['Selamat malam', 'Selamat sore', 'Selamat pagi', 'Sampai jumpa'], 'correctAnswer': 'Selamat pagi', 'hint': 'ØµÙŽØ¨ÙŽØ§Ø­Ù Ø§Ù„Ù’Ø®ÙŽÙŠÙ’Ø±Ù (Shabahul khair) = Selamat pagi.'},
    {'type': 'multipleChoice', 'prompt': 'Jawaban yang tepat untuk "ØµÙŽØ¨ÙŽØ§Ø­Ù Ø§Ù„Ù’Ø®ÙŽÙŠÙ’Ø±Ù" adalah:', 'arabicText': '', 'options': ['Ù…ÙŽØ³ÙŽØ§Ø¡Ù Ø§Ù„Ù†ÙÙ‘ÙˆØ±Ù', 'ØµÙŽØ¨ÙŽØ§Ø­Ù Ø§Ù„Ù†ÙÙ‘ÙˆØ±Ù', 'Ø§Ù„Ø³ÙŽÙ‘Ù„ÙŽØ§Ù…Ù Ø¹ÙŽÙ„ÙŽÙŠÙ’ÙƒÙÙ…Ù’', 'ÙˆÙŽØ¹ÙŽÙ„ÙŽÙŠÙ’ÙƒÙÙ…Ù Ø§Ù„Ø³ÙŽÙ‘Ù„ÙŽØ§Ù…'], 'correctAnswer': 'ØµÙŽØ¨ÙŽØ§Ø­Ù Ø§Ù„Ù†ÙÙ‘ÙˆØ±Ù', 'hint': 'Balasan ØµÙŽØ¨ÙŽØ§Ø­Ù Ø§Ù„Ù’Ø®ÙŽÙŠÙ’Ø±Ù adalah ØµÙŽØ¨ÙŽØ§Ø­Ù Ø§Ù„Ù†ÙÙ‘ÙˆØ±Ù.'},
    {'type': 'multipleChoice', 'prompt': '"Ù…ÙŽØ³ÙŽØ§Ø¡Ù Ø§Ù„Ù’Ø®ÙŽÙŠÙ’Ø±Ù" digunakan pada waktu:', 'arabicText': 'Ù…ÙŽØ³ÙŽØ§Ø¡Ù Ø§Ù„Ù’Ø®ÙŽÙŠÙ’Ø±Ù', 'options': ['Pagi hari', 'Siang hari', 'Sore/petang hari', 'Tengah malam'], 'correctAnswer': 'Sore/petang hari', 'hint': 'Ù…ÙŽØ³ÙŽØ§Ø¡Ù Ø§Ù„Ù’Ø®ÙŽÙŠÙ’Ø±Ù (Masa\'ul khair) = Selamat sore/petang.'},
    {'type': 'wordArrangement', 'prompt': 'Susun salam pagi yang benar:', 'arabicText': '', 'words': ['Ø§Ù„Ù’Ø®ÙŽÙŠÙ’Ø±Ù', 'ØµÙŽØ¨ÙŽØ§Ø­Ù', 'Ø§Ù„Ù†ÙÙ‘ÙˆØ±Ù'], 'correctAnswer': 'ØµÙŽØ¨ÙŽØ§Ø­Ù Ø§Ù„Ù’Ø®ÙŽÙŠÙ’Ø±Ù', 'hint': 'ØµÙŽØ¨ÙŽØ§Ø­Ù = pagi, Ø§Ù„Ù’Ø®ÙŽÙŠÙ’Ø±Ù = kebaikan.'},
    {'type': 'multipleChoice', 'prompt': 'Ali mengucapkan salam di pagi hari. Kalimat yang tepat adalah:', 'arabicText': '', 'options': ['Ù…ÙŽØ³ÙŽØ§Ø¡Ù Ø§Ù„Ù’Ø®ÙŽÙŠÙ’Ø±Ù', 'ØªÙØµÙ’Ø¨ÙØ­Ù Ø¹ÙŽÙ„ÙŽÙ‰ Ø®ÙŽÙŠÙ’Ø±Ù', 'ØµÙŽØ¨ÙŽØ§Ø­Ù Ø§Ù„Ù’Ø®ÙŽÙŠÙ’Ø±Ù', 'Ù…ÙŽØ¹ÙŽ Ø§Ù„Ø³ÙŽÙ‘Ù„ÙŽØ§Ù…ÙŽØ©Ù'], 'correctAnswer': 'ØµÙŽØ¨ÙŽØ§Ø­Ù Ø§Ù„Ù’Ø®ÙŽÙŠÙ’Ø±Ù', 'hint': 'ØµÙŽØ¨ÙŽØ§Ø­Ù Ø§Ù„Ù’Ø®ÙŽÙŠÙ’Ø±Ù digunakan di pagi hari.'},
  ];

  // â”€â”€ Unit 3: Perkenalan Diri â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static const _questionsPerkenalan = [
    {'type': 'multipleChoice', 'prompt': '"Ù…ÙŽØ§ Ø§Ø³Ù’Ù…ÙÙƒÙŽØŸ" artinya?', 'arabicText': 'Ù…ÙŽØ§ Ø§Ø³Ù’Ù…ÙÙƒÙŽØŸ', 'options': ['Dari mana kamu?', 'Berapa umurmu?', 'Siapa namamu?', 'Apa pekerjaanmu?'], 'correctAnswer': 'Siapa namamu?', 'hint': 'Ù…ÙŽØ§ Ø§Ø³Ù’Ù…ÙÙƒÙŽ = Siapa namamu? (untuk laki-laki).'},
    {'type': 'multipleChoice', 'prompt': 'Cara menjawab "Namaku Ahmad" dalam bahasa Arab:', 'arabicText': '', 'options': ['Ø§Ø³Ù’Ù…ÙÙƒÙŽ Ø£ÙŽØ­Ù’Ù…ÙŽØ¯Ù', 'Ø§Ø³Ù’Ù…ÙÙŠ Ø£ÙŽØ­Ù’Ù…ÙŽØ¯Ù', 'Ø£ÙŽÙ†ÙŽØ§ Ø£ÙŽØ­Ù’Ù…ÙŽØ¯Ù Ø§Ø³Ù’Ù…ÙŒ', 'Ù‡ÙÙˆÙŽ Ø£ÙŽØ­Ù’Ù…ÙŽØ¯Ù'], 'correctAnswer': 'Ø§Ø³Ù’Ù…ÙÙŠ Ø£ÙŽØ­Ù’Ù…ÙŽØ¯Ù', 'hint': 'Ø§Ø³Ù’Ù…ÙÙŠ = namaku (milik saya).'},
    {'type': 'multipleChoice', 'prompt': '"Ù…ÙÙ†Ù’ Ø£ÙŽÙŠÙ’Ù†ÙŽ Ø£ÙŽÙ†Ù’ØªÙŽØŸ" artinya?', 'arabicText': 'Ù…ÙÙ†Ù’ Ø£ÙŽÙŠÙ’Ù†ÙŽ Ø£ÙŽÙ†Ù’ØªÙŽØŸ', 'options': ['Di mana rumahmu?', 'Dari mana kamu?', 'Ke mana kamu pergi?', 'Siapa namamu?'], 'correctAnswer': 'Dari mana kamu?', 'hint': 'Ù…ÙÙ†Ù’ = dari, Ø£ÙŽÙŠÙ’Ù†ÙŽ = mana, Ø£ÙŽÙ†Ù’ØªÙŽ = kamu.'},
    {'type': 'wordArrangement', 'prompt': 'Terjemahkan: "Namaku Fatimah"', 'arabicText': '', 'words': ['ÙÙŽØ§Ø·ÙÙ…ÙŽØ©Ù', 'Ø£ÙŽØ­Ù’Ù…ÙŽØ¯Ù', 'Ø§Ø³Ù’Ù…ÙÙŠ'], 'correctAnswer': 'Ø§Ø³Ù’Ù…ÙÙŠ ÙÙŽØ§Ø·ÙÙ…ÙŽØ©Ù', 'hint': 'Ø§Ø³Ù’Ù…ÙÙŠ = namaku, ÙÙŽØ§Ø·ÙÙ…ÙŽØ©Ù = Fatimah.'},
    {'type': 'multipleChoice', 'prompt': '"ÙƒÙŽÙ…Ù’ Ø¹ÙÙ…Ù’Ø±ÙÙƒÙŽØŸ" artinya?', 'arabicText': 'ÙƒÙŽÙ…Ù’ Ø¹ÙÙ…Ù’Ø±ÙÙƒÙŽØŸ', 'options': ['Siapa namamu?', 'Dari mana kamu?', 'Berapa umurmu?', 'Apa pekerjaanmu?'], 'correctAnswer': 'Berapa umurmu?', 'hint': 'ÙƒÙŽÙ…Ù’ = berapa, Ø¹ÙÙ…Ù’Ø±ÙÙƒÙŽ = umurmu.'},
  ];

  // â”€â”€ Unit 3: Bertanya Kabar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static const _questionsBertanyaKabar = [
    {'type': 'multipleChoice', 'prompt': '"ÙƒÙŽÙŠÙ’ÙÙŽ Ø­ÙŽØ§Ù„ÙÙƒÙŽØŸ" artinya?', 'arabicText': 'ÙƒÙŽÙŠÙ’ÙÙŽ Ø­ÙŽØ§Ù„ÙÙƒÙŽØŸ', 'options': ['Siapa namamu?', 'Bagaimana kabarmu?', 'Dari mana kamu?', 'Di mana rumahmu?'], 'correctAnswer': 'Bagaimana kabarmu?', 'hint': 'ÙƒÙŽÙŠÙ’ÙÙŽ = bagaimana, Ø­ÙŽØ§Ù„ÙÙƒÙŽ = kabarmu.'},
    {'type': 'multipleChoice', 'prompt': 'Jawaban yang paling tepat untuk "ÙƒÙŽÙŠÙ’ÙÙŽ Ø­ÙŽØ§Ù„ÙÙƒÙŽØŸ":', 'arabicText': '', 'options': ['Ø´ÙÙƒÙ’Ø±Ù‹Ø§', 'Ø§Ø³Ù’Ù…ÙÙŠ Ø£ÙŽØ­Ù’Ù…ÙŽØ¯Ù', 'Ø¨ÙØ®ÙŽÙŠÙ’Ø±ÙØŒ Ø§Ù„Ù’Ø­ÙŽÙ…Ù’Ø¯Ù Ù„ÙÙ„ÙŽÙ‘Ù‡Ù', 'ØµÙŽØ¨ÙŽØ§Ø­Ù Ø§Ù„Ù’Ø®ÙŽÙŠÙ’Ø±Ù'], 'correctAnswer': 'Ø¨ÙØ®ÙŽÙŠÙ’Ø±ÙØŒ Ø§Ù„Ù’Ø­ÙŽÙ…Ù’Ø¯Ù Ù„ÙÙ„ÙŽÙ‘Ù‡Ù', 'hint': 'Ø¨ÙØ®ÙŽÙŠÙ’Ø±Ù = baik, Ø§Ù„Ù’Ø­ÙŽÙ…Ù’Ø¯Ù Ù„ÙÙ„ÙŽÙ‘Ù‡Ù = segala puji bagi Allah.'},
    {'type': 'multipleChoice', 'prompt': '"Ø§Ù„Ù’Ø­ÙŽÙ…Ù’Ø¯Ù Ù„ÙÙ„ÙŽÙ‘Ù‡Ù" artinya?', 'arabicText': 'Ø§Ù„Ù’Ø­ÙŽÙ…Ù’Ø¯Ù Ù„ÙÙ„ÙŽÙ‘Ù‡Ù', 'options': ['Subhanallah', 'Allahu Akbar', 'Segala puji bagi Allah', 'Tidak apa-apa'], 'correctAnswer': 'Segala puji bagi Allah', 'hint': 'Ø§Ù„Ù’Ø­ÙŽÙ…Ù’Ø¯Ù Ù„ÙÙ„ÙŽÙ‘Ù‡Ù sering diucapkan sebagai rasa syukur.'},
    {'type': 'wordArrangement', 'prompt': 'Susun pertanyaan: "Bagaimana kabarmu?"', 'arabicText': '', 'words': ['Ø­ÙŽØ§Ù„ÙÙƒÙŽ', 'ÙƒÙŽÙŠÙ’ÙÙŽ', 'Ø§Ø³Ù’Ù…ÙÙƒÙŽ'], 'correctAnswer': 'ÙƒÙŽÙŠÙ’ÙÙŽ Ø­ÙŽØ§Ù„ÙÙƒÙŽ', 'hint': 'ÙƒÙŽÙŠÙ’ÙÙŽ = bagaimana, Ø­ÙŽØ§Ù„ÙÙƒÙŽ = kabarmu.'},
    {'type': 'multipleChoice', 'prompt': 'Setelah seseorang menjawab kabarnya, kamu ingin balik bertanya "Dan kamu?". Kalimat yang tepat:', 'arabicText': '', 'options': ['Ù…ÙŽØ§ Ø§Ø³Ù’Ù…ÙÙƒÙŽØŸ', 'ÙˆÙŽØ£ÙŽÙ†Ù’ØªÙŽØŸ', 'Ù…ÙÙ†Ù’ Ø£ÙŽÙŠÙ’Ù†ÙŽ Ø£ÙŽÙ†Ù’ØªÙŽØŸ', 'ÙƒÙŽÙ…Ù’ Ø¹ÙÙ…Ù’Ø±ÙÙƒÙŽØŸ'], 'correctAnswer': 'ÙˆÙŽØ£ÙŽÙ†Ù’ØªÙŽØŸ', 'hint': 'ÙˆÙŽØ£ÙŽÙ†Ù’ØªÙŽ = dan kamu? (laki-laki). ÙˆÙŽØ£ÙŽÙ†Ù’ØªÙ untuk perempuan.'},
  ];

  // â”€â”€ Unit 3: Terima Kasih & Maaf â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static const _questionsTerimaMaaf = [
    {'type': 'multipleChoice', 'prompt': '"Ø´ÙÙƒÙ’Ø±Ù‹Ø§" artinya?', 'arabicText': 'Ø´ÙÙƒÙ’Ø±Ù‹Ø§', 'options': ['Maaf', 'Permisi', 'Terima kasih', 'Sama-sama'], 'correctAnswer': 'Terima kasih', 'hint': 'Ø´ÙÙƒÙ’Ø±Ù‹Ø§ (Syukran) = terima kasih.'},
    {'type': 'multipleChoice', 'prompt': 'Jawaban yang tepat untuk "Ø´ÙÙƒÙ’Ø±Ù‹Ø§" adalah:', 'arabicText': '', 'options': ['Ø´ÙÙƒÙ’Ø±Ù‹Ø§ Ø¬ÙŽØ²ÙÙŠÙ„Ù‹Ø§', 'Ø¹ÙŽÙÙ’ÙˆÙ‹Ø§', 'Ø¢Ø³ÙÙÙŒ', 'Ù„ÙŽØ§ Ø¨ÙŽØ£Ù’Ø³ÙŽ'], 'correctAnswer': 'Ø¹ÙŽÙÙ’ÙˆÙ‹Ø§', 'hint': 'Ø¹ÙŽÙÙ’ÙˆÙ‹Ø§ (\'Afwan) = sama-sama / maaf.'},
    {'type': 'multipleChoice', 'prompt': '"Ø¢Ø³ÙÙÙŒ" atau "Ø£ÙŽÙ†ÙŽØ§ Ø¢Ø³ÙÙÙŒ" artinya?', 'arabicText': 'Ø£ÙŽÙ†ÙŽØ§ Ø¢Ø³ÙÙÙŒ', 'options': ['Terima kasih', 'Tidak apa-apa', 'Saya minta maaf', 'Permisi'], 'correctAnswer': 'Saya minta maaf', 'hint': 'Ø£ÙŽÙ†ÙŽØ§ Ø¢Ø³ÙÙÙŒ = saya minta maaf (untuk laki-laki).'},
    {'type': 'wordArrangement', 'prompt': 'Terjemahkan: "Terima kasih banyak"', 'arabicText': '', 'words': ['Ø¬ÙŽØ²ÙÙŠÙ„Ù‹Ø§', 'Ø¹ÙŽÙÙ’ÙˆÙ‹Ø§', 'Ø´ÙÙƒÙ’Ø±Ù‹Ø§'], 'correctAnswer': 'Ø´ÙÙƒÙ’Ø±Ù‹Ø§ Ø¬ÙŽØ²ÙÙŠÙ„Ù‹Ø§', 'hint': 'Ø´ÙÙƒÙ’Ø±Ù‹Ø§ = terima kasih, Ø¬ÙŽØ²ÙÙŠÙ„Ù‹Ø§ = banyak/sangat.'},
    {'type': 'multipleChoice', 'prompt': '"Ù„ÙŽØ§ Ø¨ÙŽØ£Ù’Ø³ÙŽ" artinya?', 'arabicText': 'Ù„ÙŽØ§ Ø¨ÙŽØ£Ù’Ø³ÙŽ', 'options': ['Terima kasih', 'Tidak apa-apa', 'Maaf', 'Permisi'], 'correctAnswer': 'Tidak apa-apa', 'hint': 'Ù„ÙŽØ§ Ø¨ÙŽØ£Ù’Ø³ÙŽ (Laa ba\'sa) = tidak apa-apa / tidak masalah.'},
  ];

  // â”€â”€ Unit 3: Dialog Lengkap â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static const _questionsDialogLengkap = [
    {'type': 'multipleChoice', 'prompt': 'Ahmad bertemu Zaid di pagi hari. Kalimat pembuka yang tepat:', 'arabicText': '', 'options': ['Ù…ÙŽØ¹ÙŽ Ø§Ù„Ø³ÙŽÙ‘Ù„ÙŽØ§Ù…ÙŽØ©Ù', 'ØªÙØµÙ’Ø¨ÙØ­Ù Ø¹ÙŽÙ„ÙŽÙ‰ Ø®ÙŽÙŠÙ’Ø±Ù', 'Ø§Ù„Ø³ÙŽÙ‘Ù„ÙŽØ§Ù…Ù Ø¹ÙŽÙ„ÙŽÙŠÙ’ÙƒÙÙ…Ù’', 'Ø¥ÙÙ„ÙŽÙ‰ Ø§Ù„Ù„ÙÙ‘Ù‚ÙŽØ§Ø¡Ù'], 'correctAnswer': 'Ø§Ù„Ø³ÙŽÙ‘Ù„ÙŽØ§Ù…Ù Ø¹ÙŽÙ„ÙŽÙŠÙ’ÙƒÙÙ…Ù’', 'hint': 'Salam pembuka yang tepat adalah Ø§Ù„Ø³ÙŽÙ‘Ù„ÙŽØ§Ù…Ù Ø¹ÙŽÙ„ÙŽÙŠÙ’ÙƒÙÙ…Ù’.'},
    {'type': 'multipleChoice', 'prompt': 'Setelah saling salam dan bertanya kabar, Ahmad bertanya nama Zaid. Kalimat yang tepat:', 'arabicText': '', 'options': ['ÙƒÙŽÙŠÙ’ÙÙŽ Ø­ÙŽØ§Ù„ÙÙƒÙŽØŸ', 'Ù…ÙŽØ§ Ø§Ø³Ù’Ù…ÙÙƒÙŽØŸ', 'Ù…ÙÙ†Ù’ Ø£ÙŽÙŠÙ’Ù†ÙŽ Ø£ÙŽÙ†Ù’ØªÙŽØŸ', 'ÙƒÙŽÙ…Ù’ Ø¹ÙÙ…Ù’Ø±ÙÙƒÙŽØŸ'], 'correctAnswer': 'Ù…ÙŽØ§ Ø§Ø³Ù’Ù…ÙÙƒÙŽØŸ', 'hint': 'Ù…ÙŽØ§ Ø§Ø³Ù’Ù…ÙÙƒÙŽ = siapa namamu?'},
    {'type': 'multipleChoice', 'prompt': '"Ù…ÙŽØ¹ÙŽ Ø§Ù„Ø³ÙŽÙ‘Ù„ÙŽØ§Ù…ÙŽØ©Ù" digunakan saat:', 'arabicText': 'Ù…ÙŽØ¹ÙŽ Ø§Ù„Ø³ÙŽÙ‘Ù„ÙŽØ§Ù…ÙŽØ©Ù', 'options': ['Bertemu seseorang', 'Memulai percakapan', 'Berpamitan / mengakhiri pertemuan', 'Menanyakan kabar'], 'correctAnswer': 'Berpamitan / mengakhiri pertemuan', 'hint': 'Ù…ÙŽØ¹ÙŽ Ø§Ù„Ø³ÙŽÙ‘Ù„ÙŽØ§Ù…ÙŽØ©Ù (Ma\'a as-salamah) = selamat jalan / sampai jumpa.'},
    {'type': 'wordArrangement', 'prompt': 'Terjemahkan: "Selamat jalan"', 'arabicText': '', 'words': ['Ø§Ù„Ø³ÙŽÙ‘Ù„ÙŽØ§Ù…ÙŽØ©Ù', 'Ù…ÙŽØ¹ÙŽ', 'Ø§Ù„Ù„ÙÙ‘Ù‚ÙŽØ§Ø¡Ù'], 'correctAnswer': 'Ù…ÙŽØ¹ÙŽ Ø§Ù„Ø³ÙŽÙ‘Ù„ÙŽØ§Ù…ÙŽØ©Ù', 'hint': 'Ù…ÙŽØ¹ÙŽ = dengan/selamat, Ø§Ù„Ø³ÙŽÙ‘Ù„ÙŽØ§Ù…ÙŽØ©Ù = keselamatan.'},
    {'type': 'multipleChoice', 'prompt': 'Jawaban yang tepat untuk "Ù…ÙŽØ¹ÙŽ Ø§Ù„Ø³ÙŽÙ‘Ù„ÙŽØ§Ù…ÙŽØ©Ù" adalah:', 'arabicText': '', 'options': ['ÙˆÙŽØ¹ÙŽÙ„ÙŽÙŠÙ’ÙƒÙÙ…Ù Ø§Ù„Ø³ÙŽÙ‘Ù„ÙŽØ§Ù…', 'ØµÙŽØ¨ÙŽØ§Ø­Ù Ø§Ù„Ù†ÙÙ‘ÙˆØ±Ù', 'Ø¥ÙÙ„ÙŽÙ‰ Ø§Ù„Ù„ÙÙ‘Ù‚ÙŽØ§Ø¡Ù', 'Ø¨ÙØ®ÙŽÙŠÙ’Ø±Ù'], 'correctAnswer': 'Ø¥ÙÙ„ÙŽÙ‰ Ø§Ù„Ù„ÙÙ‘Ù‚ÙŽØ§Ø¡Ù', 'hint': 'Ø¥ÙÙ„ÙŽÙ‰ Ø§Ù„Ù„ÙÙ‘Ù‚ÙŽØ§Ø¡Ù (Ila al-liqa\') = sampai jumpa lagi.'},
  ];
}


