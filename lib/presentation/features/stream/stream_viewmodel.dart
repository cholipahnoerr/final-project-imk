import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/stream_content_model.dart';

class StreamState {
  const StreamState({
    required this.wordOfDay,
    required this.triviaList,
  });

  final WordOfDay wordOfDay;
  final List<CultureTrivia> triviaList;
}

// Static content provider — Sprint 6 can swap to a Firestore StreamProvider
final streamStateProvider = Provider<StreamState>((ref) {
  return StreamState(
    wordOfDay: StreamContent.wordOfDay,
    triviaList: StreamContent.triviaList,
  );
});

// Convenience providers consumed by detail screens
final wordOfDayProvider = Provider<WordOfDay>((ref) {
  return ref.watch(streamStateProvider).wordOfDay;
});

final cultureTriviaProvider = Provider.family<CultureTrivia?, String>((ref, id) {
  final list = ref.watch(streamStateProvider).triviaList;
  try {
    return list.firstWhere((t) => t.id == id);
  } catch (_) {
    return null;
  }
});
