import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/auth_service.dart';
import '../../../data/models/stream_content_model.dart';

// Kata hari ini — otomatis berdasarkan scheduledDate, fallback ke terbaru
final wordOfDayProvider = StreamProvider<WordOfDay?>((ref) {
  return ref.watch(firestoreDataSourceProvider).watchTodayWord();
});

// Watch daftar trivia dari Firestore
final triviasProvider = StreamProvider<List<CultureTrivia>>((ref) {
  return ref.watch(firestoreDataSourceProvider).watchTrivias();
});

// Social posts tetap static
final socialPostsProvider = Provider<List<SocialPost>>((ref) {
  return StreamContent.socialPosts;
});

// Provider lama untuk backward compat detail screens
final cultureTriviaProvider = Provider.family<CultureTrivia?, String>((ref, id) {
  final list = ref.watch(triviasProvider).valueOrNull ?? [];
  try {
    return list.firstWhere((t) => t.id == id);
  } catch (_) {
    return null;
  }
});
