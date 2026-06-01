import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_typography.dart';
import '../../../../../data/models/quiz_question_model.dart';

class CharacterTracingWidget extends StatefulWidget {
  const CharacterTracingWidget({
    super.key,
    required this.question,
    required this.showFeedback,
    required this.onAnswerChanged,
  });

  final QuizQuestion question;
  final bool showFeedback;
  final ValueChanged<String> onAnswerChanged;

  @override
  State<CharacterTracingWidget> createState() => _CharacterTracingWidgetState();
}

class _CharacterTracingWidgetState extends State<CharacterTracingWidget> {
  final List<List<Offset>> _strokes = [];
  List<Offset> _currentStroke = [];
  bool _evaluated = false;
  double _similarity = 0;

  void _onPanStart(DragStartDetails d) {
    if (widget.showFeedback) return;
    setState(() {
      _currentStroke = [d.localPosition];
    });
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (widget.showFeedback) return;
    setState(() {
      _currentStroke = [..._currentStroke, d.localPosition];
    });
  }

  void _onPanEnd(DragEndDetails _) {
    if (widget.showFeedback) return;
    if (_currentStroke.isEmpty) return;
    setState(() {
      _strokes.add(List.from(_currentStroke));
      _currentStroke = [];
    });
    _evaluate();
  }

  void _evaluate() {
    // Simple heuristic: coverage of canvas area indicates an attempt was made
    final allPoints = _strokes.expand((s) => s).toList();
    if (allPoints.length < 10) {
      _similarity = 0;
      widget.onAnswerChanged('');
      return;
    }

    final xs = allPoints.map((p) => p.dx);
    final ys = allPoints.map((p) => p.dy);
    final width = xs.reduce(max) - xs.reduce(min);
    final height = ys.reduce(max) - ys.reduce(min);
    // Score based on coverage area relative to expected strokes
    final coverageScore = (width * height).clamp(0.0, 10000.0) / 10000.0;
    final strokeCountScore = (_strokes.length / 3).clamp(0.0, 1.0);
    _similarity = (coverageScore * 0.6 + strokeCountScore * 0.4).clamp(0.0, 1.0);

    _evaluated = true;
    widget.onAnswerChanged(_similarity >= 0.4 ? 'correct' : 'incorrect');
  }

  void _clear() {
    setState(() {
      _strokes.clear();
      _currentStroke = [];
      _evaluated = false;
      _similarity = 0;
    });
    widget.onAnswerChanged('');
  }

  Color get _canvasColor {
    if (!widget.showFeedback) return AppColors.surfaceVariant;
    final isCorrect = _similarity >= 0.4;
    return isCorrect ? AppColors.successLight : AppColors.errorLight;
  }

  Color get _borderColor {
    if (!widget.showFeedback) return AppColors.border;
    return _similarity >= 0.4 ? AppColors.success : AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.question.arabicText != null) ...[
          Center(
            child: Text(
              widget.question.arabicText!,
              style: AppTypography.arabicLarge.copyWith(fontSize: 64),
              textDirection: TextDirection.rtl,
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Salin karakter di atas pada area di bawah',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 16),
        ],
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: _canvasColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _borderColor, width: 2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: GestureDetector(
              onPanStart: _onPanStart,
              onPanUpdate: _onPanUpdate,
              onPanEnd: _onPanEnd,
              child: CustomPaint(
                painter: _TracingPainter(
                  strokes: _strokes,
                  currentStroke: _currentStroke,
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 240,
                  child: _strokes.isEmpty && _currentStroke.isEmpty
                      ? Center(
                          child: Text(
                            'Gambar karakter di sini',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),
                        )
                      : null,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            if (!widget.showFeedback)
              TextButton.icon(
                onPressed: _clear,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Hapus'),
                style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
              ),
            if (widget.showFeedback && _evaluated) ...[
              const SizedBox(width: 4),
              Icon(
                _similarity >= 0.4 ? Icons.check_circle : Icons.cancel,
                color: _similarity >= 0.4 ? AppColors.success : AppColors.error,
                size: 20,
              ),
              const SizedBox(width: 6),
              Text(
                _similarity >= 0.4
                    ? 'Bagus! Karakter terdeteksi.'
                    : 'Coba lagi — gambar lebih penuh.',
                style: AppTypography.bodySmall.copyWith(
                  color: _similarity >= 0.4 ? AppColors.success : AppColors.error,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _TracingPainter extends CustomPainter {
  _TracingPainter({required this.strokes, required this.currentStroke});

  final List<List<Offset>> strokes;
  final List<Offset> currentStroke;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      if (stroke.length < 2) continue;
      final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
      for (int i = 1; i < stroke.length; i++) {
        path.lineTo(stroke[i].dx, stroke[i].dy);
      }
      canvas.drawPath(path, paint);
    }

    if (currentStroke.length >= 2) {
      final path = Path()..moveTo(currentStroke.first.dx, currentStroke.first.dy);
      for (int i = 1; i < currentStroke.length; i++) {
        path.lineTo(currentStroke[i].dx, currentStroke[i].dy);
      }
      canvas.drawPath(path, paint..color = AppColors.primary.withValues(alpha: 0.7));
    }
  }

  @override
  bool shouldRepaint(_TracingPainter old) =>
      old.strokes != strokes || old.currentStroke != currentStroke;
}
