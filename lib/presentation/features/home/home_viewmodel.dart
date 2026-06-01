import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/auth_service.dart';
import '../../../data/models/learning_path_model.dart';
import '../../../data/models/user_model.dart';

// Streams live user data (XP, streak, hearts, gems)
final currentUserProvider = StreamProvider<UserModel?>((ref) {
  final uid = ref.watch(firebaseAuthProvider).currentUser?.uid;
  if (uid == null) return Stream.value(null);
  return ref.watch(firestoreDataSourceProvider).watchUser(uid);
});

// Static learning path — replaced with Firestore data in Sprint 3
final learningPathProvider = Provider<List<LearningUnit>>((ref) {
  return [
    LearningUnit(
      id: 'unit-1',
      title: 'Pengantar',
      description: 'Huruf Hijaiyah & Salam Dasar',
      isUnlocked: true,
      nodes: [
        LessonNode(id: 'u1-l1', title: 'Huruf Alif–Ta', state: NodeState.completed, stars: 3),
        LessonNode(id: 'u1-l2', title: 'Huruf Tsa–Dal', state: NodeState.completed, stars: 2),
        LessonNode(id: 'u1-l3', title: 'Huruf Dzal–Sin', state: NodeState.active),
        LessonNode(id: 'u1-l4', title: 'Huruf Syin–Dad', state: NodeState.locked),
        LessonNode(id: 'u1-l5', title: 'Kuis Huruf', state: NodeState.locked),
      ],
    ),
    LearningUnit(
      id: 'unit-2',
      title: 'Kosakata Dasar',
      description: 'Benda Sehari-hari & Angka',
      nodes: [
        LessonNode(id: 'u2-l1', title: 'Benda di Rumah', state: NodeState.locked),
        LessonNode(id: 'u2-l2', title: 'Angka 1–10', state: NodeState.locked),
        LessonNode(id: 'u2-l3', title: 'Warna', state: NodeState.locked),
        LessonNode(id: 'u2-l4', title: 'Anggota Keluarga', state: NodeState.locked),
        LessonNode(id: 'u2-l5', title: 'Kuis Kosakata', state: NodeState.locked),
      ],
    ),
    LearningUnit(
      id: 'unit-3',
      title: 'Percakapan',
      description: 'Salam & Perkenalan Diri',
      nodes: [
        LessonNode(id: 'u3-l1', title: 'Salam Pagi & Sore', state: NodeState.locked),
        LessonNode(id: 'u3-l2', title: 'Perkenalan Diri', state: NodeState.locked),
        LessonNode(id: 'u3-l3', title: 'Bertanya Kabar', state: NodeState.locked),
        LessonNode(id: 'u3-l4', title: 'Terima Kasih & Maaf', state: NodeState.locked),
        LessonNode(id: 'u3-l5', title: 'Dialog Lengkap', state: NodeState.locked),
      ],
    ),
  ];
});