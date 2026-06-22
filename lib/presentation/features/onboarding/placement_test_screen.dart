import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../common_widgets/primary_button.dart';

class PlacementTestScreen extends StatefulWidget {
  const PlacementTestScreen({super.key});

  @override
  State<PlacementTestScreen> createState() => _PlacementTestScreenState();
}

class _PlacementTestScreenState extends State<PlacementTestScreen> {
  int _currentQuestion = 0;
  String? _selectedAnswer;
  int _score = 0; // passed to PlacementResultScreen

  // TODO: Load from Firestore
  static const List<Map<String, dynamic>> _questions = [
    {
      'question': 'Apa arti kata "مَرْحَبًا"?',
      'options': ['Halo / Selamat datang', 'Terima kasih', 'Sampai jumpa', 'Maaf'],
      'correct': 0,
    },
    {
      'question': 'Manakah yang berarti "Saya pergi ke sekolah"?',
      'options': [
        'أَنَا أَذْهَبُ إِلَى الْمَدْرَسَةِ',
        'أَنَا أَكُلُ الطَّعَامَ',
        'أَنَا أَنَامُ',
        'أَنَا أَقْرَأُ كِتَابًا',
      ],
      'correct': 0,
    },
  ];

  void _selectAnswer(String answer) {
    setState(() => _selectedAnswer = answer);
  }

  void _next() {
    if (_selectedAnswer == _questions[_currentQuestion]['options'][_questions[_currentQuestion]['correct']]) {
      _score++;
    }
    if (_currentQuestion < _questions.length - 1) {
      setState(() {
        _currentQuestion++;
        _selectedAnswer = null;
      });
    } else {
      context.go('/onboarding/placement-result', extra: {'score': _score});
    }
  }

  @override
  Widget build(BuildContext context) {
    final question = _questions[_currentQuestion];
    final options = question['options'] as List<String>;

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.pop()),
        title: Text('Tes Penempatan ${_currentQuestion + 1}/${_questions.length}'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LinearProgressIndicator(
                value: (_currentQuestion + 1) / _questions.length,
                backgroundColor: AppColors.surfaceVariant,
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 32),
              Text(question['question'] as String, style: AppTypography.headlineMedium),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.separated(
                  itemCount: options.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final option = options[index];
                    final isSelected = _selectedAnswer == option;
                    return GestureDetector(
                      onTap: () => _selectAnswer(option),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : AppColors.border,
                            width: isSelected ? 2 : 1,
                          ),
                          color: isSelected ? AppColors.primary.withValues(alpha: 0.08) : AppColors.surface,
                        ),
                        child: Text(option, style: AppTypography.bodyLarge),
                      ),
                    );
                  },
                ),
              ),
              PrimaryButton(
                label: _currentQuestion == _questions.length - 1 ? 'Selesai' : 'Lanjut',
                onPressed: _selectedAnswer == null ? null : _next,
              ),
            ],
          ),
        ),
      ),
    );
  }
}