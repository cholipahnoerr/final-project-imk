import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';

class VideoCallScreen extends StatefulWidget {
  const VideoCallScreen({super.key, required this.callId});
  final String callId;

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  bool _isMuted = false;
  bool _isCameraOff = false;
  int _seconds = 0;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() => _seconds++);
      return mounted;
    });
  }

  String get _timeFormatted {
    final m = (_seconds ~/ 60).toString().padLeft(2, '0');
    final s = (_seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Remote video (full screen placeholder)
          Container(
            width: double.infinity,
            height: double.infinity,
            color: const Color(0xFF1A1A2E),
            child: const Center(
              child: Icon(Icons.person, size: 120, color: Colors.white24),
            ),
          ),
          // Local video (PIP placeholder)
          Positioned(
            top: 60,
            right: 16,
            child: Container(
              width: 100,
              height: 140,
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A3E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24),
              ),
              child: _isCameraOff
                  ? const Icon(Icons.videocam_off, color: Colors.white54)
                  : const Icon(Icons.person, color: Colors.white54),
            ),
          ),
          // Timer
          Positioned(
            top: 60,
            left: 0,
            right: 0,
            child: Center(
              child: Text(_timeFormatted, style: AppTypography.bodyLarge.copyWith(color: Colors.white70)),
            ),
          ),
          // Controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black87, Colors.transparent],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _VideoCallButton(
                    icon: _isMuted ? Icons.mic_off : Icons.mic,
                    onTap: () => setState(() => _isMuted = !_isMuted),
                  ),
                  _VideoCallButton(
                    icon: Icons.call_end,
                    color: AppColors.error,
                    size: 64,
                    onTap: () => context.pop(),
                  ),
                  _VideoCallButton(
                    icon: _isCameraOff ? Icons.videocam_off : Icons.videocam,
                    onTap: () => setState(() => _isCameraOff = !_isCameraOff),
                  ),
                  _VideoCallButton(
                    icon: Icons.flip_camera_android,
                    onTap: () {
                      // TODO: Switch camera
                    },
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
  const _VideoCallButton({required this.icon, required this.onTap, this.color, this.size = 52});

  final IconData icon;
  final VoidCallback onTap;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color ?? Colors.white24,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: size * 0.45),
      ),
    );
  }
}