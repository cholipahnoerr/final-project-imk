import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/services/agora_service.dart';

class VoiceCallScreen extends ConsumerStatefulWidget {
  const VoiceCallScreen({
    super.key,
    required this.callId,
    required this.partnerName,
  });
  final String callId;
  final String partnerName;

  @override
  ConsumerState<VoiceCallScreen> createState() => _VoiceCallScreenState();
}

class _VoiceCallScreenState extends ConsumerState<VoiceCallScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(agoraCallProvider.notifier)
          .init(channelId: widget.callId, isVideo: false);
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

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 48),
            // Avatar
            CircleAvatar(
              radius: 56,
              backgroundColor: AppColors.primary.withValues(alpha: 0.2),
              child: const Icon(Icons.person_rounded, size: 64, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            Text(
              widget.partnerName.isNotEmpty ? widget.partnerName : '...',
              style: AppTypography.headlineMedium.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              call.isJoined
                  ? (call.remoteUid != null
                      ? _formatElapsed(call.elapsed)
                      : 'Menunggu...')
                  : 'Menghubungkan...',
              style: AppTypography.bodyLarge.copyWith(color: Colors.white54),
            ),
            const Spacer(),
            // Controls
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _CallButton(
                    icon: call.isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                    label: call.isMuted ? 'Unmute' : 'Mute',
                    color: call.isMuted ? Colors.red : Colors.white24,
                    onTap: () => ref.read(agoraCallProvider.notifier).toggleMute(),
                  ),
                  _CallButton(
                    icon: Icons.call_end_rounded,
                    label: 'Tutup',
                    color: Colors.red,
                    size: 72,
                    onTap: () async {
                      await ref.read(agoraCallProvider.notifier).endCall();
                      if (context.mounted) context.pop();
                    },
                  ),
                  _CallButton(
                    icon: call.isSpeakerOn
                        ? Icons.volume_up_rounded
                        : Icons.volume_down_rounded,
                    label: 'Speaker',
                    color: call.isSpeakerOn ? AppColors.primary : Colors.white24,
                    onTap: () => ref.read(agoraCallProvider.notifier).toggleSpeaker(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CallButton extends StatelessWidget {
  const _CallButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.size = 56,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            child: Icon(icon, color: Colors.white, size: size * 0.45),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ],
    );
  }
}
