class WordOfDay {
  const WordOfDay({
    required this.id,
    required this.arabic,
    required this.transliteration,
    required this.translation,
    required this.partOfSpeech,
    required this.exampleArabic,
    required this.exampleTranslation,
    this.level = 1,
    this.audioUrl,
    this.scheduledDate,
  });

  final String id;
  final String arabic;
  final String transliteration;
  final String translation;
  final String partOfSpeech;
  final String exampleArabic;
  final String exampleTranslation;
  final int level;
  final String? audioUrl;
  final String? scheduledDate; // format: "YYYY-MM-DD"

  factory WordOfDay.fromMap(Map<String, dynamic> map, String id) {
    return WordOfDay(
      id: id,
      arabic: map['arabic'] as String? ?? '',
      transliteration: map['transliteration'] as String? ?? '',
      translation: map['translation'] as String? ?? '',
      partOfSpeech: map['partOfSpeech'] as String? ?? '',
      exampleArabic: map['exampleArabic'] as String? ?? '',
      exampleTranslation: map['exampleTranslation'] as String? ?? '',
      level: map['level'] as int? ?? 1,
      audioUrl: map['audioUrl'] as String?,
      scheduledDate: map['scheduledDate'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'arabic': arabic,
      'transliteration': transliteration,
      'translation': translation,
      'partOfSpeech': partOfSpeech,
      'exampleArabic': exampleArabic,
      'exampleTranslation': exampleTranslation,
      'level': level,
      'audioUrl': audioUrl,
      'scheduledDate': scheduledDate,
    };
  }
}

class SocialPost {
  const SocialPost({
    required this.id,
    required this.userName,
    required this.content,
    required this.streakDays,
    required this.timeAgo,
    this.userAvatar,
    this.isLiked = false,
  });

  final String id;
  final String userName;
  final String content;
  final int streakDays;
  final String timeAgo;
  final String? userAvatar;
  final bool isLiked;
}

class CultureTrivia {
  const CultureTrivia({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.content,
    required this.vocabulary,
    this.imageUrl,
  });

  final String id;
  final String title;
  final String subtitle;
  final String content;
  final List<VocabEntry> vocabulary; // Arabic words highlighted in article
  final String? imageUrl;

  factory CultureTrivia.fromMap(Map<String, dynamic> map, String id) {
    final rawVocab = map['vocabulary'] as List<dynamic>? ?? [];
    final vocabulary = rawVocab
        .map((e) => VocabEntry.fromMap(e as Map<String, dynamic>))
        .toList();
    return CultureTrivia(
      id: id,
      title: map['title'] as String? ?? '',
      subtitle: map['subtitle'] as String? ?? '',
      content: map['content'] as String? ?? '',
      vocabulary: vocabulary,
      imageUrl: map['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'subtitle': subtitle,
      'content': content,
      'vocabulary': vocabulary.map((v) => v.toMap()).toList(),
      'imageUrl': imageUrl,
    };
  }
}

class VocabEntry {
  const VocabEntry({required this.arabic, required this.translation, this.transliteration});
  final String arabic;
  final String translation;
  final String? transliteration;

  factory VocabEntry.fromMap(Map<String, dynamic> map) {
    return VocabEntry(
      arabic: map['arabic'] as String? ?? '',
      translation: map['translation'] as String? ?? '',
      transliteration: map['transliteration'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'arabic': arabic,
      'translation': translation,
      'transliteration': transliteration,
    };
  }
}

// Static content — replaced by Firestore in production
class StreamContent {
  static WordOfDay get wordOfDay => const WordOfDay(
    id: 'wod-001',
    arabic: 'مَرْحَبًا',
    transliteration: 'Marhaban',
    translation: '"Selamat Datang"',
    partOfSpeech: 'Kata Seru (Interjeksi)',
    exampleArabic: 'مَرْحَبًا بِكَ',
    exampleTranslation: 'Selamat datang kepadamu',
    level: 1,
  );

  static const List<SocialPost> socialPosts = [
    SocialPost(
      id: 'post-1',
      userName: 'Ahmad',
      content: 'Berhasil mencapai 10 hari berturut-turut! Konsistensi adalah kuncinya 🚀',
      streakDays: 10,
      timeAgo: '2j lalu',
    ),
    SocialPost(
      id: 'post-2',
      userName: 'Layla',
      content: 'Baru saja menguasai 100 kata kerja paling umum! Merasa percaya diri untuk pelajaran selanjutnya 📖',
      streakDays: 10,
      timeAgo: '2j lalu',
    ),
    SocialPost(
      id: 'post-3',
      userName: 'Rafi',
      content: 'Akhirnya bisa membaca surah pendek tanpa harakat. Alhamdulillah! 🤲',
      streakDays: 5,
      timeAgo: '4j lalu',
    ),
  ];

  static const List<CultureTrivia> triviaList = [
    CultureTrivia(
      id: 'trivia-0',
      title: 'Sejarah Huruf Hijaiyah',
      subtitle: 'Asal-usul aksara Arab kuno',
      content:
          'Huruf Hijaiyah adalah huruf abjad yang digunakan untuk menuliskan bahasa Arab, '
          'terdiri dari 28 huruf dasar. Huruf Arab ditulis dari kanan ke kiri dan bersifat kursif.\n\n'
          'Asal usul aksara Arab dapat ditelusuri ke aksara Nabataean pada abad pertama Masehi. '
          'Aksara ini kemudian berkembang menjadi standar penulisan bahasa Arab yang kita kenal sekarang. '
          'Pada abad ke-7, aksara Arab mulai digunakan untuk menuliskan Al-Qur\'an, yang mempercepat '
          'penyebarannya ke seluruh dunia Islam.',
      vocabulary: [
        VocabEntry(arabic: 'حَرْفٌ', translation: 'Huruf', transliteration: 'ḥarfun'),
        VocabEntry(arabic: 'كِتَابَةٌ', translation: 'Tulisan', transliteration: 'kitābatun'),
        VocabEntry(arabic: 'تَارِيخٌ', translation: 'Sejarah', transliteration: 'tārīkhun'),
      ],
    ),
    CultureTrivia(
      id: 'trivia-1',
      title: 'Tradisi Kaligrafi Arab',
      subtitle: 'Seni menulis indah dari Timur Tengah',
      content:
          'Kaligrafi Arab (الخط العربي) adalah salah satu bentuk seni tertinggi dalam budaya Islam. '
          'Seni ini berkembang pesat sejak abad ke-7 Masehi, didorong oleh kebutuhan menyalin Al-Qur\'an.\n\n'
          'Ada berbagai gaya kaligrafi Arab, antara lain Naskhi (paling umum), Thuluth (megah), '
          'Kufi (geometris dan kuno), serta Diwani (dekoratif). Setiap gaya memiliki karakter dan '
          'kegunaan tersendiri dalam dunia seni dan arsitektur Islam.',
      vocabulary: [
        VocabEntry(arabic: 'خَطٌّ', translation: 'Kaligrafi / Tulisan', transliteration: 'khaṭṭun'),
        VocabEntry(arabic: 'فَنٌّ', translation: 'Seni', transliteration: 'fannun'),
        VocabEntry(arabic: 'جَمِيلٌ', translation: 'Indah', transliteration: 'jamīlun'),
      ],
    ),
    CultureTrivia(
      id: 'trivia-2',
      title: 'Sistem Angka Arab',
      subtitle: 'Bagaimana angka modern sampai ke Eropa',
      content:
          'Angka yang kita gunakan sehari-hari (0–9) sebenarnya berasal dari India, namun disebarluaskan '
          'ke Eropa melalui dunia Arab pada abad ke-9–12 Masehi. Itulah mengapa disebut "angka Arab".\n\n'
          'Matematikawan Arab Al-Khawarizmi (780–850 M) memainkan peran besar dalam mempopulerkan '
          'sistem desimal berbasis posisi ini. Kata "algoritma" bahkan berasal dari nama beliau.',
      vocabulary: [
        VocabEntry(arabic: 'عَدَدٌ', translation: 'Angka', transliteration: '\'adadun'),
        VocabEntry(arabic: 'رِيَاضِيَّاتٌ', translation: 'Matematika', transliteration: 'riyāḍiyyātun'),
        VocabEntry(arabic: 'صِفْرٌ', translation: 'Nol', transliteration: 'ṣifrun'),
      ],
    ),
    CultureTrivia(
      id: 'trivia-3',
      title: 'Bulan dalam Kalender Hijriyah',
      subtitle: 'Sistem penanggalan lunar Islam',
      content:
          'Kalender Hijriyah (التقويم الهجري) adalah kalender lunar yang digunakan umat Islam. '
          'Tahun Hijriyah dimulai dari peristiwa Hijrahnya Nabi Muhammad SAW dari Mekkah ke Madinah '
          'pada tahun 622 Masehi.\n\n'
          'Satu tahun Hijriyah terdiri dari 12 bulan dengan total 354 atau 355 hari — sekitar 11 hari '
          'lebih pendek dari tahun Masehi. Bulan suci Ramadhan adalah bulan ke-9 dalam kalender ini.',
      vocabulary: [
        VocabEntry(arabic: 'شَهْرٌ', translation: 'Bulan', transliteration: 'shahrun'),
        VocabEntry(arabic: 'رَمَضَانُ', translation: 'Ramadhan', transliteration: 'ramaḍānu'),
        VocabEntry(arabic: 'سَنَةٌ', translation: 'Tahun', transliteration: 'sanatun'),
      ],
    ),
  ];
}
