import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/services/agora_service.dart';

class VideoCallScreen extends ConsumerStatefulWidget {
  const VideoCallScreen({
    super.key,
    required this.callId,
    required this.partnerName,
  });
  final String callId;
  final String partnerName;

  @override
  ConsumerState<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends ConsumerState<VideoCallScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(agoraCallProvider.notifier)
          .init(channelId: widget.callId, isVideo: true);
    });
  }

  String _formatElapsed(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final call = ref.watch(agoraCallProvider);
    final engine = ref.read(agoraCallProvider.notifier).engine;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Remote video (full screen)
          if (call.remoteUid != null && engine != null)
            AgoraVideoView(
              controller: VideoViewController.remote(
                rtcEngine: engine,
                canvas: VideoCanvas(uid: call.remoteUid!),
                connection: RtcConnection(channelId: widget.callId),
              ),
            )
          else
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.person_rounded, size: 80, color: Colors.white38),
                  const SizedBox(height: 12),
                  Text(
                    call.isJoined ? 'Menunggu...' : 'Menghubungkan...',
                    style: AppTypography.bodyLarge.copyWith(color: Colors.white54),
                  ),
                ],
              ),
            ),

          // Local video (picture-in-picture)
          if (!call.isCameraOff && engine != null)
            Positioned(
              right: 16,
              top: MediaQuery.of(context).padding.top + 16,
              width: 100,
              height: 140,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AgoraVideoView(
                  controller: VideoViewController(
                    rtcEngine: engine,
                    canvas: const VideoCanvas(uid: 0),
                  ),
                ),
              ),
            ),

          // Timer overlay
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  call.remoteUid != null ? _formatElapsed(call.elapsed) : 'Menunggu...',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ),
          ),

          // Controls bottom bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                left: 40,
                right: 40,
                top: 20,
                bottom: MediaQuery.of(context).padding.bottom + 20,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black87, Colors.transparent],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _VideoCallButton(
                    icon: call.isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                    label: call.isMuted ? 'Unmute' : 'Mute',
                    active: call.isMuted,
                    onTap: () => ref.read(agoraCallProvider.notifier).toggleMute(),
                  ),
                  _VideoCallButton(
                    icon: Icons.call_end_rounded,
                    label: 'Tutup',
                    isEndCall: true,
                    onTap: () async {
                      await ref.read(agoraCallProvider.notifier).endCall();
                      if (context.mounted) context.pop();
                    },
                  ),
                  _VideoCallButton(
                    icon: call.isCameraOff
                        ? Icons.videocam_off_rounded
                        : Icons.videocam_rounded,
                    label: call.isCameraOff ? 'Kamera Off' : 'Kamera',
                    active: call.isCameraOff,
                    onTap: () => ref.read(agoraCallProvider.notifier).toggleCamera(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VideoCallButton extends StatelessWidget {
  const _VideoCallButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
    this.isEndCall = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;
  final bool isEndCall;

  @override
  Widget build(BuildContext context) {
    final bg = isEndCall
        ? Colors.red
        : active
            ? Colors.red.withValues(alpha: 0.8)
            : Colors.white24;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: isEndCall ? 64 : 52,
            height: isEndCall ? 64 : 52,
            decoration: BoxDecoration(shape: BoxShape.circle, color: bg),
            child: Icon(icon, color: Colors.white, size: isEndCall ? 30 : 24),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }
}
