import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

class AudioService {
  final AudioPlayer _player = AudioPlayer();
  final Dio _dio = Dio();

  static String _arabicTtsUrl(String arabicText) {
    final encoded = Uri.encodeQueryComponent(arabicText);
    return 'https://translate.googleapis.com/translate_tts'
        '?ie=UTF-8&q=$encoded&tl=ar&client=gtx&ttsspeed=0.8';
  }

  /// Downloads Google TTS audio then plays from temp file.
  /// More reliable than streaming because ExoPlayer may not forward headers on redirect.
  Future<void> playTts(String arabicText) async {
    await _player.stop();
    final url = _arabicTtsUrl(arabicText);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/tts_ar.mp3');

    await _dio.download(
      url,
      file.path,
      options: Options(
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36',
        },
        receiveTimeout: const Duration(seconds: 10),
      ),
    );

    await _player.setFilePath(file.path);
    await _player.play();
  }

  /// Streams from a remote [url] (e.g. Firebase Storage).
  Future<void> playUrl(String url) async {
    await _player.stop();
    await _player.setAudioSource(
      AudioSource.uri(
        Uri.parse(url),
        headers: const {'User-Agent': 'Mozilla/5.0'},
      ),
    );
    await _player.play();
  }

  Future<void> playAsset(String assetPath) async {
    await _player.stop();
    await _player.setAsset(assetPath);
    await _player.play();
  }

  Future<void> stop() async => _player.stop();

  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  void dispose() => _player.dispose();
}

final audioServiceProvider = Provider<AudioService>((ref) {
  final service = AudioService();
  ref.onDispose(service.dispose);
  return service;
});
