import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';

class GuideScreen extends StatelessWidget {
  const GuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
                color: AppColors.surfaceVariant, shape: BoxShape.circle),
            child: const Icon(Icons.arrow_back_rounded,
                color: AppColors.textPrimary, size: 20),
          ),
          onPressed: () => context.pop(),
        ),
        title: Text('Buku Panduan',
            style: AppTypography.titleLarge.copyWith(
                color: AppColors.primary, fontWeight: FontWeight.w800)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          // ── Hero ──────────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Text('🐪', style: TextStyle(fontSize: 52)),
                const SizedBox(height: 10),
                Text('Selamat datang di Hayyarabic!',
                    style: AppTypography.headlineMedium
                        .copyWith(color: Colors.white, fontWeight: FontWeight.w800),
                    textAlign: TextAlign.center),
                const SizedBox(height: 6),
                Text(
                  'Panduan lengkap untuk membantu kamu\nbelajar bahasa Arab dengan menyenangkan.',
                  style: AppTypography.bodyMedium
                      .copyWith(color: Colors.white.withValues(alpha: 0.85)),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Sections ──────────────────────────────────────────────────
          _GuideSection(
            emoji: '🗺️',
            title: 'Cara Belajar',
            color: AppColors.primary,
            items: const [
              _GuideItem(
                icon: Icons.route_rounded,
                title: 'Jalur Belajar',
                body:
                    'Setiap unit berisi beberapa node (bulatan). Kamu harus menyelesaikan node satu per satu dari atas ke bawah.',
              ),
              _GuideItem(
                icon: Icons.lock_open_rounded,
                title: 'Membuka Node',
                body:
                    'Node yang terkunci (abu-abu 🔒) belum bisa dimainkan. Selesaikan node aktif (hijau ⭐) terlebih dahulu untuk membukanya.',
              ),
              _GuideItem(
                icon: Icons.touch_app_rounded,
                title: 'Mulai Pelajaran',
                body:
                    'Tap node yang aktif (berwarna hijau dengan ikon bintang) untuk memulai pelajaran. Kamu akan menjawab soal pilihan ganda.',
              ),
              _GuideItem(
                icon: Icons.emoji_events_rounded,
                title: 'Selesaikan Unit',
                body:
                    'Setelah semua node dalam satu unit selesai, unit berikutnya akan terbuka secara otomatis.',
              ),
            ],
          ),

          _GuideSection(
            emoji: '❤️',
            title: 'Nyawa',
            color: Colors.red,
            items: const [
              _GuideItem(
                icon: Icons.favorite_rounded,
                title: 'Kamu Punya 5 Nyawa',
                body:
                    'Di pojok kiri atas layar pelajaran terdapat 5 ikon hati yang menunjukkan nyawa kamu.',
              ),
              _GuideItem(
                icon: Icons.close_rounded,
                title: 'Jawaban Salah',
                body:
                    'Setiap kali menjawab salah, 1 nyawa berkurang. Jika nyawa habis, sesi belajar kamu berakhir.',
              ),
              _GuideItem(
                icon: Icons.check_circle_outline_rounded,
                title: 'Tips',
                body:
                    'Baca soal dengan teliti sebelum menjawab. Lebih baik hati-hati daripada terburu-buru dan kehilangan nyawa.',
              ),
            ],
          ),

          _GuideSection(
            emoji: '⚡',
            title: 'XP & Berlian',
            color: const Color(0xFFFFB800),
            items: const [
              _GuideItem(
                icon: Icons.bolt_rounded,
                title: 'Mendapatkan XP',
                body:
                    'Kamu mendapatkan XP (poin pengalaman) setiap kali menjawab soal dengan benar. Bonus XP ekstra saat menyelesaikan pelajaran penuh.',
              ),
              _GuideItem(
                icon: Icons.diamond_rounded,
                title: 'Mendapatkan Berlian',
                body:
                    'Berlian (💎) diperoleh setiap kali kamu menyelesaikan satu pelajaran. Berlian ditampilkan di pojok kanan atas.',
              ),
              _GuideItem(
                icon: Icons.bar_chart_rounded,
                title: 'Kegunaan XP',
                body:
                    'XP menentukan peringkatmu di papan liga mingguan. Semakin banyak XP, semakin tinggi posisimu dan semakin besar peluang naik liga.',
              ),
            ],
          ),

          _GuideSection(
            emoji: '🔥',
            title: 'Streak Harian',
            color: AppColors.streak,
            items: const [
              _GuideItem(
                icon: Icons.local_fire_department_rounded,
                title: 'Apa itu Streak?',
                body:
                    'Streak adalah hitungan berapa hari berturut-turut kamu belajar. Angka streak ditampilkan di pojok kiri atas setiap halaman.',
              ),
              _GuideItem(
                icon: Icons.calendar_today_rounded,
                title: 'Menjaga Streak',
                body:
                    'Selesaikan minimal 1 pelajaran setiap hari untuk menjaga streak. Jika skip sehari, streak akan kembali ke 0.',
              ),
              _GuideItem(
                icon: Icons.military_tech_rounded,
                title: 'Manfaat Streak',
                body:
                    'Streak panjang membuka lencana khusus. Streak 3, 7, dan 30 hari masing-masing mendapatkan lencana berbeda di profilmu.',
              ),
            ],
          ),

          _GuideSection(
            emoji: '🏆',
            title: 'Liga & Papan Peringkat',
            color: const Color(0xFFFFD700),
            items: const [
              _GuideItem(
                icon: Icons.shield_rounded,
                title: '4 Tingkat Liga',
                body:
                    'Ada 4 liga: Perunggu 🥉 → Perak 🥈 → Emas 🥇 → Berlian 💎. Semua pengguna baru mulai dari Liga Perunggu.',
              ),
              _GuideItem(
                icon: Icons.trending_up_rounded,
                title: 'Naik Liga',
                body:
                    'Setiap minggu, 10 pengguna dengan XP terbanyak di liganya akan naik ke liga berikutnya. XP liga di-reset setiap Senin.',
              ),
              _GuideItem(
                icon: Icons.leaderboard_rounded,
                title: 'Papan Peringkat',
                body:
                    'Lihat posisimu dibandingkan pengguna lain di liga yang sama di tab Pencapaian. Bersaing untuk mendapatkan posisi teratas!',
              ),
            ],
          ),

          _GuideSection(
            emoji: '🏅',
            title: 'Lencana & Pencapaian',
            color: AppColors.gold,
            items: const [
              _GuideItem(
                icon: Icons.workspace_premium_rounded,
                title: 'Kumpulkan Lencana',
                body:
                    'Lencana diperoleh dengan mencapai milestone tertentu, seperti menyelesaikan pelajaran pertama, mencapai streak 7 hari, atau mengumpulkan 500 XP.',
              ),
              _GuideItem(
                icon: Icons.visibility_rounded,
                title: 'Lihat Lencana',
                body:
                    'Semua lencana yang sudah dan belum kamu dapatkan bisa dilihat di halaman Profil → Lencana → Lihat Semua.',
              ),
            ],
          ),

          _GuideSection(
            emoji: '💬',
            title: 'Fitur Bincang',
            color: AppColors.gems,
            items: const [
              _GuideItem(
                icon: Icons.person_search_rounded,
                title: 'Cari Teman Belajar',
                body:
                    'Buka tab Bincang, lalu tap tombol + di kanan bawah. Ketik email teman yang sudah mendaftar di Hayyarabic untuk mulai percakapan.',
              ),
              _GuideItem(
                icon: Icons.mic_rounded,
                title: 'Kirim Voice Note',
                body:
                    'Di ruang obrolan, tekan dan tahan tombol mikrofon untuk merekam. Lepaskan untuk mengirim. Berlatih mengucapkan bahasa Arab dengan teman!',
              ),
              _GuideItem(
                icon: Icons.call_rounded,
                title: 'Panggilan Suara & Video',
                body:
                    'Klik ikon telepon atau video di sudut kanan atas ruang obrolan untuk melakukan panggilan langsung dengan teman belajarmu.',
              ),
            ],
          ),

          _GuideSection(
            emoji: '📰',
            title: 'Fitur Kabar',
            color: const Color(0xFF2196F3),
            items: const [
              _GuideItem(
                icon: Icons.auto_stories_rounded,
                title: 'Kata Hari Ini',
                body:
                    'Setiap hari ada kata bahasa Arab baru yang bisa kamu pelajari. Lengkap dengan arti, contoh kalimat, dan audio pengucapan.',
              ),
              _GuideItem(
                icon: Icons.temple_buddhist_rounded,
                title: 'Trivia Budaya',
                body:
                    'Pelajari fakta menarik seputar budaya dan sejarah Arab. Perluas wawasanmu di luar kosakata.',
              ),
            ],
          ),

          _GuideSection(
            emoji: '💡',
            title: 'Tips Belajar Efektif',
            color: const Color(0xFF4CAF50),
            items: const [
              _GuideItem(
                icon: Icons.repeat_rounded,
                title: 'Konsistensi adalah Kunci',
                body:
                    'Belajar 10–15 menit setiap hari jauh lebih efektif daripada belajar 2 jam sekali seminggu. Jaga streakmu!',
              ),
              _GuideItem(
                icon: Icons.record_voice_over_rounded,
                title: 'Praktik Berbicara',
                body:
                    'Gunakan fitur Bincang untuk berkomunikasi dengan teman dalam bahasa Arab. Praktik percakapan nyata mempercepat kemajuanmu.',
              ),
              _GuideItem(
                icon: Icons.volume_up_rounded,
                title: 'Dengarkan & Ulangi',
                body:
                    'Setiap kali menemukan kata baru, coba ucapkan dengan keras. Pengulangan vokal membantu memori jangka panjang.',
              ),
              _GuideItem(
                icon: Icons.notifications_active_rounded,
                title: 'Aktifkan Pengingat',
                body:
                    'Aktifkan notifikasi di Profil → Pengaturan → Pengingat Streak Harian agar tidak lupa belajar setiap hari.',
              ),
            ],
          ),

          const SizedBox(height: 8),

          // ── Footer ────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Text('🐪', style: TextStyle(fontSize: 32)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Siap belajar?',
                          style: AppTypography.titleMedium.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      Text(
                        'Kembali ke beranda dan mulai pelajaran pertamamu!',
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Guide Section ────────────────────────────────────────────────────────────

class _GuideSection extends StatefulWidget {
  const _GuideSection({
    required this.emoji,
    required this.title,
    required this.color,
    required this.items,
  });

  final String emoji;
  final String title;
  final Color color;
  final List<_GuideItem> items;

  @override
  State<_GuideSection> createState() => _GuideSectionState();
}

class _GuideSectionState extends State<_GuideSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          // Header (always visible)
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: widget.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(widget.emoji,
                          style: const TextStyle(fontSize: 20)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: AppTypography.titleMedium
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.keyboard_arrow_down_rounded,
                        color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),

          // Expandable content
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: _expanded
                ? Column(
                    children: [
                      const Divider(height: 1),
                      ...widget.items.map((item) => _GuideItemTile(
                            item: item,
                            color: widget.color,
                          )),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// ─── Guide Item ───────────────────────────────────────────────────────────────

class _GuideItem {
  const _GuideItem({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;
}

class _GuideItemTile extends StatelessWidget {
  const _GuideItemTile({required this.item, required this.color});
  final _GuideItem item;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(item.icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title,
                    style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 3),
                Text(item.body,
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.textSecondary, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
