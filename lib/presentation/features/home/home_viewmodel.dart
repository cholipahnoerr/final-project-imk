import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/local_storage_service.dart';
import '../../../data/models/learning_path_model.dart';
import '../../../data/models/user_model.dart';

// Streams live user data (XP, streak, hearts, gems)
final currentUserProvider = StreamProvider<UserModel?>((ref) {
  final uid = ref.watch(firebaseAuthProvider).currentUser?.uid;
  if (uid == null) return Stream.value(null);
  return ref.watch(firestoreDataSourceProvider).watchUser(uid);
});

// Learning path from Firestore with user progress applied
final learningPathProvider =
    FutureProvider.autoDispose<List<LearningUnit>>((ref) async {
  final ds = ref.read(firestoreDataSourceProvider);
  final user = ref.watch(currentUserProvider).valueOrNull;
  final completedNodes = user?.completedNodes ?? [];

  List<LearningUnit> units;
  try {
    units = await ds.getUnitsWithNodes();
  } catch (_) {
    units = _hardcodedUnits;
  }

  if (units.isEmpty) units = _hardcodedUnits;

  bool foundActive = false;
  return units.map((unit) {
    if (!unit.isUnlocked) return unit;
    final nodes = unit.nodes.map((node) {
      final key = '${unit.id}/${node.id}';
      if (completedNodes.contains(key)) {
        return node.copyWith(state: NodeState.completed);
      } else if (!foundActive) {
        foundActive = true;
        return node.copyWith(state: NodeState.active);
      } else {
        return node.copyWith(state: NodeState.locked);
      }
    }).toList();
    return LearningUnit(
      id: unit.id,
      title: unit.title,
      description: unit.description,
      nodes: nodes,
      isUnlocked: unit.isUnlocked,
      order: unit.order,
    );
  }).toList();
});

// ── Daily Gift ────────────────────────────────────────────────────────────────

String _todayKey(String uid) {
  final now = DateTime.now();
  final date =
      '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  return 'gift_${uid}_$date';
}

class DailyGiftNotifier extends Notifier<bool> {
  static const int _giftXp = 10;

  @override
  bool build() {
    final uid = ref.watch(firebaseAuthProvider).currentUser?.uid ?? '';
    return LocalStorageService.get<bool>(_todayKey(uid)) == true;
  }

  Future<bool> claim() async {
    if (state) return false;
    final uid = ref.read(firebaseAuthProvider).currentUser?.uid;
    final user = ref.read(currentUserProvider).valueOrNull;
    if (uid == null || user == null) return false;

    await ref.read(firestoreDataSourceProvider).updateUser(uid, {
      'xp': user.xp + _giftXp,
      'leagueXpThisWeek': user.leagueXpThisWeek + _giftXp,
    });
    await LocalStorageService.put(_todayKey(uid), true);
    state = true;
    return true;
  }
}

final dailyGiftProvider =
    NotifierProvider<DailyGiftNotifier, bool>(DailyGiftNotifier.new);

// Hardcoded fallback
final _hardcodedUnits = <LearningUnit>[
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
