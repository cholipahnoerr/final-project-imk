enum QuestionType { multipleChoice, audio, wordArrangement, characterTracing, pronunciation, translation }

class QuizQuestion {
  const QuizQuestion({
    required this.id,
    required this.type,
    required this.prompt,
    this.arabicText,
    this.audioUrl,
    this.options = const [],
    this.correctAnswer = '',
    this.words = const [],
    this.hint,
    this.order = 0,
  });

  final String id;
  final QuestionType type;
  final String prompt;           // Instruction shown to user
  final String? arabicText;      // Arabic text to display/trace/pronounce
  final String? audioUrl;        // For audio questions
  final List<String> options;    // For multiple choice
  final String correctAnswer;    // Expected answer string
  final List<String> words;      // For word arrangement (shuffled words)
  final String? hint;            // Grammar hint shown in feedback
  final int order;               // For Firestore ordering

  factory QuizQuestion.fromMap(Map<String, dynamic> map, String id) {
    final typeStr = map['type'] as String? ?? 'multipleChoice';
    final type = QuestionType.values.firstWhere(
      (e) => e.name == typeStr,
      orElse: () => QuestionType.multipleChoice,
    );
    return QuizQuestion(
      id: id,
      type: type,
      prompt: map['prompt'] as String? ?? '',
      arabicText: map['arabicText'] as String?,
      audioUrl: map['audioUrl'] as String?,
      options: List<String>.from(map['options'] as List<dynamic>? ?? []),
      correctAnswer: map['correctAnswer'] as String? ?? '',
      words: List<String>.from(map['words'] as List<dynamic>? ?? []),
      hint: map['hint'] as String?,
      order: map['order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'prompt': prompt,
      'arabicText': arabicText,
      'audioUrl': audioUrl,
      'options': options,
      'correctAnswer': correctAnswer,
      'words': words,
      'hint': hint,
      'order': order,
    };
  }
}

// Static Arabic lesson data — replaced by Firestore in Sprint 3.5
List<QuizQuestion> getLessonQuestions(String unitId, String lessonId) {
  return [
    QuizQuestion(
      id: 'q1',
      type: QuestionType.multipleChoice,
      prompt: 'Apa artinya kata ini?',
      arabicText: 'كِتَابٌ',
      options: ['Buku', 'Meja', 'Kursi', 'Lampu'],
      correctAnswer: 'Buku',
      hint: 'كِتَابٌ (kitābun) adalah kata benda maskulin yang berarti buku.',
    ),
    QuizQuestion(
      id: 'q2',
      type: QuestionType.wordArrangement,
      prompt: 'Susun kata-kata ini menjadi kalimat yang benar:',
      correctAnswer: 'أَنَا أَذْهَبُ إِلَى الْمَدْرَسَةِ',
      words: ['الْمَدْرَسَةِ', 'أَنَا', 'إِلَى', 'أَذْهَبُ'],
      hint: 'Pola kalimat Arab: Subjek + Predikat + Objek',
    ),
    QuizQuestion(
      id: 'q3',
      type: QuestionType.multipleChoice,
      prompt: 'Pilih terjemahan yang benar untuk "Sekolah":',
      options: ['مَدْرَسَةٌ', 'بَيْتٌ', 'مَسْجِدٌ', 'سُوقٌ'],
      correctAnswer: 'مَدْرَسَةٌ',
      hint: 'مَدْرَسَةٌ (madrasatun) artinya sekolah.',
    ),
    QuizQuestion(
      id: 'q4',
      type: QuestionType.translation,
      prompt: 'Terjemahkan ke bahasa Arab:',
      arabicText: 'Saya pergi ke rumah',
      correctAnswer: 'أَنَا أَذْهَبُ إِلَى الْبَيْتِ',
      hint: 'أَذْهَبُ = saya pergi, إِلَى = ke, الْبَيْتِ = rumah (dengan artikel)',
    ),
    QuizQuestion(
      id: 'q5',
      type: QuestionType.pronunciation,
      prompt: 'Dengarkan dan ucapkan kata ini:',
      arabicText: 'صَبَاحُ الْخَيْرِ',
      correctAnswer: 'correct',
      hint: 'صَبَاحُ الْخَيْرِ (ṣabāḥu l-khayr) artinya Selamat Pagi.',
    ),
    QuizQuestion(
      id: 'q6',
      type: QuestionType.audio,
      prompt: 'Dengarkan audio dan pilih jawaban yang benar:',
      audioUrl: '',
      options: ['مَرْحَبًا', 'شُكْرًا', 'مَعَ السَّلَامَةِ', 'صَبَاحُ الْخَيْرِ'],
      correctAnswer: 'مَرْحَبًا',
      hint: 'مَرْحَبًا (marḥaban) artinya Halo / Selamat datang.',
    ),
  ];
}
