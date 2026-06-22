import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';

class AgoraCallState {
  const AgoraCallState({
    this.isJoined = false,
    this.remoteUid,
    this.isMuted = false,
    this.isSpeakerOn = false,
    this.isCameraOff = false,
    this.elapsed = 0,
  });

  final bool isJoined;
  final int? remoteUid;
  final bool isMuted;
  final bool isSpeakerOn;
  final bool isCameraOff;
  final int elapsed;

  AgoraCallState copyWith({
    bool? isJoined,
    int? remoteUid,
    bool clearRemoteUid = false,
    bool? isMuted,
    bool? isSpeakerOn,
    bool? isCameraOff,
    int? elapsed,
  }) {
    return AgoraCallState(
      isJoined: isJoined ?? this.isJoined,
      remoteUid: clearRemoteUid ? null : (remoteUid ?? this.remoteUid),
      isMuted: isMuted ?? this.isMuted,
      isSpeakerOn: isSpeakerOn ?? this.isSpeakerOn,
      isCameraOff: isCameraOff ?? this.isCameraOff,
      elapsed: elapsed ?? this.elapsed,
    );
  }
}

class AgoraCallNotifier extends StateNotifier<AgoraCallState> {
  AgoraCallNotifier() : super(const AgoraCallState());

  RtcEngine? _engine;
  Timer? _timer;

  Future<void> init({required String channelId, required bool isVideo}) async {
    _engine = createAgoraRtcEngine();
    await _engine!.initialize(RtcEngineContext(appId: AppConfig.agoraAppId));

    _engine!.registerEventHandler(RtcEngineEventHandler(
      onJoinChannelSuccess: (connection, elapsed) {
        state = state.copyWith(isJoined: true);
        _startTimer();
      },
      onUserJoined: (connection, remoteUid, elapsed) {
        state = state.copyWith(remoteUid: remoteUid);
      },
      onUserOffline: (connection, remoteUid, reason) {
        state = state.copyWith(clearRemoteUid: true);
      },
    ));

    await _engine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
    await _engine!.enableAudio();

    if (isVideo) {
      await _engine!.enableVideo();
      await _engine!.startPreview();
    }

    await _engine!.joinChannel(
      token: '',
      channelId: channelId,
      uid: 0,
      options: const ChannelMediaOptions(
        channelProfile: ChannelProfileType.channelProfileCommunication,
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
      ),
    );
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) state = state.copyWith(elapsed: state.elapsed + 1);
    });
  }

  Future<void> toggleMute() async {
    final newMuted = !state.isMuted;
    await _engine?.muteLocalAudioStream(newMuted);
    state = state.copyWith(isMuted: newMuted);
  }

  Future<void> toggleSpeaker() async {
    final newSpeaker = !state.isSpeakerOn;
    await _engine?.setEnableSpeakerphone(newSpeaker);
    state = state.copyWith(isSpeakerOn: newSpeaker);
  }

  Future<void> toggleCamera() async {
    final newOff = !state.isCameraOff;
    await _engine?.enableLocalVideo(!newOff);
    state = state.copyWith(isCameraOff: newOff);
  }

  Future<void> endCall() async {
    await _cleanup();
  }

  Future<void> _cleanup() async {
    _timer?.cancel();
    _timer = null;
    await _engine?.leaveChannel();
    await _engine?.release();
    _engine = null;
  }

  RtcEngine? get engine => _engine;

  @override
  void dispose() {
    _cleanup();
    super.dispose();
  }
}

final agoraCallProvider =
    StateNotifierProvider.autoDispose<AgoraCallNotifier, AgoraCallState>(
  (ref) => AgoraCallNotifier(),
);
