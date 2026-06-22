import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/services/auth_service.dart';
import '../../../data/models/chat_message_model.dart';
import 'chat_viewmodel.dart';

class ChatRoomScreen extends ConsumerStatefulWidget {
  const ChatRoomScreen({
    super.key,
    required this.partnerId,
    this.initialPartnerName,
  });
  final String partnerId;
  final String? initialPartnerName;

  @override
  ConsumerState<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends ConsumerState<ChatRoomScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _recorder = AudioRecorder();

  bool _isRecording = false;
  int _recordingSeconds = 0;
  Timer? _recordingTimer;

  static const List<String> _smartReplies = [
    'شكراً', 'عفواً', 'ممتاز', 'يلا', 'أهلاً', 'صحيح',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(chatViewModelProvider(widget.partnerId).notifier)
          .ensureChatExists(widget.initialPartnerName);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _recorder.dispose();
    _recordingTimer?.cancel();
    super.dispose();
  }

  void _send(String text) {
    if (text.trim().isEmpty) return;
    _controller.clear();
    ref.read(chatViewModelProvider(widget.partnerId).notifier).sendText(text);
    _scrollToBottom();
  }

  Future<void> _startRecording() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Izin mikrofon diperlukan untuk merekam suara'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }
    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(const RecordConfig(), path: path);
    setState(() {
      _isRecording = true;
      _recordingSeconds = 0;
    });
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _recordingSeconds++);
    });
  }

  Future<void> _stopAndSend() async {
    _recordingTimer?.cancel();
    final path = await _recorder.stop();
    final duration = _recordingSeconds;
    setState(() => _isRecording = false);
    if (path == null || duration == 0) return;
    try {
      await ref
          .read(chatViewModelProvider(widget.partnerId).notifier)
          .sendVoiceNote(path, duration);
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengirim voice note: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _cancelRecording() async {
    _recordingTimer?.cancel();
    await _recorder.stop();
    setState(() => _isRecording = false);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _fmtRecording(int s) {
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final sec = (s % 60).toString().padLeft(2, '0');
    return '$m:$sec';
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = ref.watch(firebaseAuthProvider).currentUser?.uid ?? '';
    final messagesAsync = ref.watch(chatMessagesProvider(widget.partnerId));
    final partnerAsync = ref.watch(chatPartnerProvider(widget.partnerId));

    ref.listen(chatMessagesProvider(widget.partnerId), (_, _) => _scrollToBottom());

    // Resolve partner name: from route extra → from Firestore → fallback
    final partnerName = partnerAsync.valueOrNull?.partnerNameFor(currentUid) ??
        widget.initialPartnerName ??
        '...';

    final chatId = computeChatId(currentUid, widget.partnerId);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary.withValues(alpha: 0.12),
              child: Text(
                partnerName.isNotEmpty ? partnerName[0].toUpperCase() : '?',
                style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.primary, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(partnerName, style: AppTypography.titleMedium),
                Text('Online',
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.success, fontSize: 11)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.call_outlined),
            onPressed: () => context.push(
              '/talk/voice-call/$chatId',
              extra: {'partnerName': partnerName},
            ),
          ),
          IconButton(
            icon: const Icon(Icons.videocam_outlined),
            onPressed: () => context.push(
              '/talk/video-call/$chatId',
              extra: {'partnerName': partnerName},
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Message list
          Expanded(
            child: messagesAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error: (_, _) =>
                  const Center(child: Text('Gagal memuat pesan')),
              data: (messages) {
                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.chat_bubble_outline_rounded,
                            size: 56, color: AppColors.textMuted),
                        const SizedBox(height: 12),
                        Text(
                          'Belum ada pesan.\nKirim salam pertama!',
                          style: AppTypography.bodyLarge
                              .copyWith(color: AppColors.textMuted),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final showDate = index == 0 ||
                        !_isSameDay(messages[index - 1].createdAt, msg.createdAt);
                    return Column(
                      children: [
                        if (showDate) _DateDivider(date: msg.createdAt),
                        _MessageBubble(
                          message: msg,
                          isMe: msg.isMe(currentUid),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          // Smart reply chips
          if (!_isRecording)
            Container(
              color: AppColors.background,
              child: SizedBox(
                height: 46,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  itemCount: _smartReplies.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) => ActionChip(
                    label: Text(_smartReplies[index],
                        style: AppTypography.arabicMedium.copyWith(fontSize: 14)),
                    onPressed: () => _send(_smartReplies[index]),
                    backgroundColor: AppColors.surfaceVariant,
                    side: const BorderSide(color: AppColors.border),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                  ),
                ),
              ),
            ),

          const Divider(height: 1),

          // Input row
          Padding(
            padding: EdgeInsets.only(
              left: 8,
              right: 8,
              top: 6,
              bottom: MediaQuery.of(context).viewInsets.bottom + 8,
            ),
            child: _isRecording
                ? _RecordingBar(
                    seconds: _recordingSeconds,
                    format: _fmtRecording,
                    onCancel: _cancelRecording,
                    onSend: _stopAndSend,
                  )
                : Row(
                    children: [
                      // Hold-to-record mic button
                      Listener(
                        onPointerDown: (_) => _startRecording(),
                        onPointerUp: (_) => _stopAndSend(),
                        child: Container(
                          width: 40,
                          height: 40,
                          margin: const EdgeInsets.only(right: 4),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.mic_rounded,
                              color: AppColors.textSecondary, size: 20),
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          decoration: InputDecoration(
                            hintText: 'Tulis pesan...',
                            filled: true,
                            fillColor: AppColors.surfaceVariant,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                          ),
                          textInputAction: TextInputAction.send,
                          onSubmitted: _send,
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _send(_controller.text),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: _controller.text.trim().isNotEmpty
                                ? AppColors.primary
                                : AppColors.border,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.send_rounded,
                              color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

// ─── Recording Bar ────────────────────────────────────────────────────────────

class _RecordingBar extends StatelessWidget {
  const _RecordingBar({
    required this.seconds,
    required this.format,
    required this.onCancel,
    required this.onSend,
  });

  final int seconds;
  final String Function(int) format;
  final VoidCallback onCancel;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onCancel,
            child: const Icon(Icons.delete_outline_rounded,
                color: Colors.red, size: 22),
          ),
          const SizedBox(width: 8),
          const _PulsingDot(),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Merekam ${format(seconds)}',
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
            ),
          ),
          GestureDetector(
            onTap: onSend,
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 10,
        height: 10,
        decoration: const BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

// ─── Message Bubble ───────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.isMe});

  final ChatMessage message;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMe ? 18 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 18),
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05), blurRadius: 4),
          ],
        ),
        child: message.type == MessageType.voice
            ? _VoiceNoteBubble(message: message, isMe: isMe)
            : Column(
                crossAxisAlignment:
                    isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: AppTypography.arabicMedium.copyWith(
                      color: isMe ? Colors.white : AppColors.textPrimary,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _formatTime(message.createdAt),
                    style: TextStyle(
                      fontSize: 10,
                      color: isMe ? Colors.white54 : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

// ─── Voice Note Bubble ────────────────────────────────────────────────────────

class _VoiceNoteBubble extends StatefulWidget {
  const _VoiceNoteBubble({required this.message, required this.isMe});
  final ChatMessage message;
  final bool isMe;

  @override
  State<_VoiceNoteBubble> createState() => _VoiceNoteBubbleState();
}

class _VoiceNoteBubbleState extends State<_VoiceNoteBubble> {
  final _player = AudioPlayer();
  bool _isPlaying = false;
  double _progress = 0;

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (_isPlaying) {
      await _player.pause();
      setState(() => _isPlaying = false);
      return;
    }
    try {
      await _player.setUrl(widget.message.content);
      _player.positionStream.listen((pos) {
        final dur = _player.duration ?? Duration.zero;
        if (mounted && dur.inMilliseconds > 0) {
          setState(() => _progress = pos.inMilliseconds / dur.inMilliseconds);
        }
      });
      _player.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed && mounted) {
          setState(() {
            _isPlaying = false;
            _progress = 0;
          });
        }
      });
      await _player.play();
      setState(() => _isPlaying = true);
    } catch (_) {}
  }

  String _fmtDuration(int? seconds) {
    if (seconds == null) return '0:00';
    final m = seconds ~/ 60;
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final fgMuted = widget.isMe ? Colors.white54 : AppColors.textMuted;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: _togglePlay,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: widget.isMe
                  ? Colors.white.withValues(alpha: 0.2)
                  : AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: widget.isMe ? Colors.white : AppColors.primary,
              size: 22,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LinearProgressIndicator(
                value: _progress,
                backgroundColor:
                    widget.isMe ? Colors.white24 : AppColors.border,
                valueColor: AlwaysStoppedAnimation(
                    widget.isMe ? Colors.white : AppColors.primary),
                minHeight: 3,
                borderRadius: BorderRadius.circular(2),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_fmtDuration(widget.message.duration),
                      style: TextStyle(fontSize: 11, color: fgMuted)),
                  Text(
                    '${widget.message.createdAt.hour.toString().padLeft(2, '0')}:${widget.message.createdAt.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(fontSize: 10, color: fgMuted),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Date Divider ─────────────────────────────────────────────────────────────

class _DateDivider extends StatelessWidget {
  const _DateDivider({required this.date});
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    String label;
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      label = 'Hari ini';
    } else if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day - 1) {
      label = 'Kemarin';
    } else {
      label =
          '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(label,
                style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted)),
          ),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }
}
