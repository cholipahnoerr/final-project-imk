import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/services/auth_service.dart';
import '../../../data/models/learning_path_model.dart';
import '../../../data/models/quiz_question_model.dart';
import '../../../data/models/stream_content_model.dart';
import '../../../data/models/user_model.dart';
import '../stream/stream_viewmodel.dart';

// ─── Providers ────────────────────────────────────────────────────────────────

final _allUsersProvider = FutureProvider<List<UserModel>>((ref) async {
  return ref.read(firestoreDataSourceProvider).getAllUsers();
});

final _appStatsProvider = FutureProvider<Map<String, int>>((ref) async {
  return ref.read(firestoreDataSourceProvider).getAppStats();
});

final _unitsProvider = FutureProvider.autoDispose<List<LearningUnit>>((ref) async {
  return ref.read(firestoreDataSourceProvider).getUnitsWithNodes();
});

final _questionsProvider =
    FutureProvider.autoDispose.family<List<QuizQuestion>, ({String unitId, String nodeId})>(
        (ref, args) async {
  return ref
      .read(firestoreDataSourceProvider)
      .getQuestions(args.unitId, args.nodeId);
});

// ─── Admin Screen ─────────────────────────────────────────────────────────────

class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

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
            decoration: const BoxDecoration(
              color: AppColors.surfaceVariant,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back_rounded,
                color: AppColors.textPrimary, size: 20),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Admin Panel',
          style: AppTypography.titleLarge.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded,
                color: AppColors.textSecondary),
            onPressed: () {
              ref.invalidate(_allUsersProvider);
              ref.invalidate(_appStatsProvider);
              ref.invalidate(_unitsProvider);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 2.5,
          labelStyle:
              AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700),
          unselectedLabelStyle: AppTypography.bodyMedium,
          tabs: const [
            Tab(text: 'Dashboard'),
            Tab(text: 'Pengguna'),
            Tab(text: 'Konten'),
            Tab(text: 'Seed'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: const [
          _DashboardTab(),
          _UsersTab(),
          _KontenTab(),
          _SeedTab(),
        ],
      ),
    );
  }
}

// ─── Dashboard Tab ────────────────────────────────────────────────────────────

class _DashboardTab extends ConsumerWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(_appStatsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ringkasan Aplikasi',
            style:
                AppTypography.headlineMedium.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          statsAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
            error: (e, _) => _ErrorCard(message: e.toString()),
            data: (stats) => Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        value: '${stats['totalUsers'] ?? 0}',
                        label: 'Total Pengguna',
                        icon: Icons.people_rounded,
                        color: AppColors.gems,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        value: '${stats['onboardedUsers'] ?? 0}',
                        label: 'Selesai Onboarding',
                        icon: Icons.check_circle_rounded,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        value: '${stats['activeStreakUsers'] ?? 0}',
                        label: 'Streak Aktif',
                        icon: Icons.local_fire_department_rounded,
                        color: AppColors.streak,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        value: '${stats['adminUsers'] ?? 0}',
                        label: 'Admin',
                        icon: Icons.admin_panel_settings_rounded,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'Info Konten',
            style:
                AppTypography.headlineMedium.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          _InfoRow(
            icon: Icons.layers_rounded,
            label: 'Total Unit Pembelajaran',
            value: '3 unit',
          ),
          _InfoRow(
            icon: Icons.stars_rounded,
            label: 'Total Pelajaran',
            value: '15 pelajaran',
          ),
          _InfoRow(
            icon: Icons.translate_rounded,
            label: 'Bahasa Target',
            value: 'Bahasa Arab',
          ),
        ],
      ),
    );
  }
}

// ─── Users Tab ────────────────────────────────────────────────────────────────

class _UsersTab extends ConsumerStatefulWidget {
  const _UsersTab();

  @override
  ConsumerState<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends ConsumerState<_UsersTab> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(_allUsersProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            onChanged: (v) => setState(() => _query = v.toLowerCase()),
            decoration: InputDecoration(
              hintText: 'Cari nama atau email...',
              hintStyle:
                  AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
              prefixIcon: const Icon(Icons.search_rounded,
                  color: AppColors.textMuted, size: 20),
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 1.6),
              ),
            ),
          ),
        ),
        Expanded(
          child: usersAsync.when(
            loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary)),
            error: (e, _) => _ErrorCard(message: e.toString()),
            data: (users) {
              final filtered = _query.isEmpty
                  ? users
                  : users
                      .where((u) =>
                          u.displayName.toLowerCase().contains(_query) ||
                          u.email.toLowerCase().contains(_query))
                      .toList();

              if (filtered.isEmpty) {
                return Center(
                  child: Text('Tidak ada pengguna ditemukan',
                      style: AppTypography.bodyMedium
                          .copyWith(color: AppColors.textMuted)),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                itemCount: filtered.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, i) => _UserCard(
                  user: filtered[i],
                  onToggleAdmin: (isAdmin) async {
                    await ref
                        .read(firestoreDataSourceProvider)
                        .setAdminRole(filtered[i].uid, isAdmin: isAdmin);
                    ref.invalidate(_allUsersProvider);
                    ref.invalidate(_appStatsProvider);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({required this.user, required this.onToggleAdmin});
  final UserModel user;
  final Future<void> Function(bool) onToggleAdmin;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: user.isAdmin
              ? AppColors.primary.withValues(alpha: 0.4)
              : AppColors.divider,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.surfaceVariant,
            child: Text(
              user.displayName.isNotEmpty
                  ? user.displayName[0].toUpperCase()
                  : '?',
              style:
                  AppTypography.titleMedium.copyWith(color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        user.displayName,
                        style: AppTypography.bodyMedium
                            .copyWith(fontWeight: FontWeight.w700),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (user.isAdmin)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Admin',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  user.email,
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.bolt_rounded, color: AppColors.gold, size: 14),
                    Text(
                      ' ${user.xp} XP',
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(width: 10),
                    Icon(Icons.local_fire_department_rounded,
                        color: AppColors.streak, size: 14),
                    Text(
                      ' ${user.currentStreak}',
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Switch(
            value: user.isAdmin,
            onChanged: (v) => onToggleAdmin(v),
            activeThumbColor: AppColors.primary,
            activeTrackColor: AppColors.primaryLight,
          ),
        ],
      ),
    );
  }
}

// ─── Konten Tab ───────────────────────────────────────────────────────────────

class _KontenTab extends StatelessWidget {
  const _KontenTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      children: const [
        _KataHariIniSection(),
        SizedBox(height: 12),
        _TriviaSection(),
        SizedBox(height: 12),
        _UnitSection(),
      ],
    );
  }
}

// ── Kata Hari Ini Section ─────────────────────────────────────────────────────

class _KataHariIniSection extends ConsumerWidget {
  const _KataHariIniSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wordsAsync = ref.watch(wordOfDayProvider);

    return ExpansionTile(
      title: Text('Kata Hari Ini',
          style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w700)),
      leading: const Icon(Icons.auto_awesome_rounded, color: AppColors.primary),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.add_circle_rounded,
                color: AppColors.primary, size: 22),
            onPressed: () => _showWordDialog(context, ref, null, null),
          ),
          const Icon(Icons.expand_more_rounded,
              color: AppColors.textSecondary),
        ],
      ),
      children: [
        wordsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (e, _) => _ErrorCard(message: e.toString()),
          data: (word) {
            if (word == null) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Belum ada kata.',
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.textMuted)),
              );
            }
            return _WordTile(word: word, ref: ref);
          },
        ),
      ],
    );
  }

  void _showWordDialog(
      BuildContext context, WidgetRef ref, WordOfDay? existing, String? id) {
    showDialog(
      context: context,
      builder: (_) => _WordFormDialog(
        existing: existing,
        existingId: id,
        onSave: (data) async {
          final ds = ref.read(firestoreDataSourceProvider);
          if (existing != null && id != null) {
            await ds.updateWord(id, data);
          } else {
            await ds.addWord(WordOfDay.fromMap(data, ''));
          }
        },
      ),
    );
  }
}

class _WordTile extends StatelessWidget {
  const _WordTile({required this.word, required this.ref});
  final WordOfDay word;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(word.arabic,
          style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
      subtitle: Text('${word.transliteration} — ${word.translation}',
          style: AppTypography.bodySmall
              .copyWith(color: AppColors.textSecondary)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit_rounded,
                color: AppColors.primary, size: 20),
            onPressed: () => showDialog(
              context: context,
              builder: (_) => _WordFormDialog(
                existing: word,
                existingId: word.id,
                onSave: (data) async {
                  await ref.read(firestoreDataSourceProvider).updateWord(word.id, data);
                },
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_rounded,
                color: AppColors.error, size: 20),
            onPressed: () async {
              await ref.read(firestoreDataSourceProvider).deleteWord(word.id);
            },
          ),
        ],
      ),
    );
  }
}

// ── Trivia Section ─────────────────────────────────────────────────────────────

class _TriviaSection extends ConsumerWidget {
  const _TriviaSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final triviasAsync = ref.watch(triviasProvider);

    return ExpansionTile(
      title: Text('Trivia Budaya',
          style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w700)),
      leading: const Icon(Icons.lightbulb_rounded, color: AppColors.gold),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.add_circle_rounded,
                color: AppColors.primary, size: 22),
            onPressed: () => showDialog(
              context: context,
              builder: (_) => _TriviaFormDialog(
                existing: null,
                existingId: null,
                onSave: (data) async {
                  await ref
                      .read(firestoreDataSourceProvider)
                      .addTrivia(CultureTrivia.fromMap(data, ''));
                },
              ),
            ),
          ),
          const Icon(Icons.expand_more_rounded,
              color: AppColors.textSecondary),
        ],
      ),
      children: [
        triviasAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (e, _) => _ErrorCard(message: e.toString()),
          data: (trivias) {
            if (trivias.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Belum ada trivia.',
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.textMuted)),
              );
            }
            return Column(
              children: trivias
                  .map((t) => _TriviaTile(trivia: t, ref: ref))
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _TriviaTile extends StatelessWidget {
  const _TriviaTile({required this.trivia, required this.ref});
  final CultureTrivia trivia;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(trivia.title,
          style:
              AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
      subtitle: Text(trivia.subtitle,
          style: AppTypography.bodySmall
              .copyWith(color: AppColors.textSecondary)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit_rounded,
                color: AppColors.primary, size: 20),
            onPressed: () => showDialog(
              context: context,
              builder: (_) => _TriviaFormDialog(
                existing: trivia.toMap(),
                existingId: trivia.id,
                onSave: (data) async {
                  await ref
                      .read(firestoreDataSourceProvider)
                      .updateTrivia(trivia.id, data);
                },
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_rounded,
                color: AppColors.error, size: 20),
            onPressed: () async {
              await ref
                  .read(firestoreDataSourceProvider)
                  .deleteTrivia(trivia.id);
            },
          ),
        ],
      ),
    );
  }
}

// ── Unit Section ───────────────────────────────────────────────────────────────

class _UnitSection extends ConsumerWidget {
  const _UnitSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unitsAsync = ref.watch(_unitsProvider);

    return ExpansionTile(
      title: Text('Unit Belajar',
          style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w700)),
      leading: const Icon(Icons.layers_rounded, color: AppColors.primary),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.add_circle_rounded,
                color: AppColors.primary, size: 22),
            onPressed: () => showDialog(
              context: context,
              builder: (_) => _UnitFormDialog(
                existing: null,
                onSave: (data) async {
                  await ref.read(firestoreDataSourceProvider).addUnit(data);
                  ref.invalidate(_unitsProvider);
                },
              ),
            ),
          ),
          const Icon(Icons.expand_more_rounded,
              color: AppColors.textSecondary),
        ],
      ),
      children: [
        unitsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (e, _) => _ErrorCard(message: e.toString()),
          data: (units) {
            if (units.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Belum ada unit.',
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.textMuted)),
              );
            }
            return Column(
              children: units
                  .map((u) => _UnitTile(unit: u))
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _UnitTile extends ConsumerWidget {
  const _UnitTile({required this.unit});
  final LearningUnit unit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ExpansionTile(
      title: Text(unit.title,
          style:
              AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
      subtitle: Text(unit.description,
          style: AppTypography.bodySmall
              .copyWith(color: AppColors.textSecondary)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit_rounded,
                color: AppColors.primary, size: 18),
            onPressed: () => showDialog(
              context: context,
              builder: (_) => _UnitFormDialog(
                existing: unit.toMap(),
                onSave: (data) async {
                  await ref
                      .read(firestoreDataSourceProvider)
                      .updateUnit(unit.id, data);
                  ref.invalidate(_unitsProvider);
                },
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_rounded,
                color: AppColors.error, size: 18),
            onPressed: () async {
              await ref
                  .read(firestoreDataSourceProvider)
                  .deleteUnit(unit.id);
              ref.invalidate(_unitsProvider);
            },
          ),
          const Icon(Icons.expand_more_rounded,
              color: AppColors.textSecondary),
        ],
      ),
      children: [
        // Add node button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: OutlinedButton.icon(
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Tambah Node'),
            onPressed: () => showDialog(
              context: context,
              builder: (_) => _NodeFormDialog(
                existing: null,
                onSave: (data) async {
                  await ref
                      .read(firestoreDataSourceProvider)
                      .addNode(unit.id, data);
                  ref.invalidate(_unitsProvider);
                },
              ),
            ),
          ),
        ),
        ...unit.nodes.map((node) => _NodeTile(unitId: unit.id, node: node)),
      ],
    );
  }
}

class _NodeTile extends ConsumerWidget {
  const _NodeTile({required this.unitId, required this.node});
  final String unitId;
  final LessonNode node;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questionsAsync = ref.watch(
        _questionsProvider((unitId: unitId, nodeId: node.id)));

    return ExpansionTile(
      tilePadding: const EdgeInsets.only(left: 32, right: 8),
      title: Text(node.title,
          style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w700)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit_rounded,
                color: AppColors.primary, size: 16),
            onPressed: () => showDialog(
              context: context,
              builder: (_) => _NodeFormDialog(
                existing: node.toMap(),
                onSave: (data) async {
                  await ref
                      .read(firestoreDataSourceProvider)
                      .updateNode(unitId, node.id, data);
                  ref.invalidate(_unitsProvider);
                },
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_rounded,
                color: AppColors.error, size: 16),
            onPressed: () async {
              await ref
                  .read(firestoreDataSourceProvider)
                  .deleteNode(unitId, node.id);
              ref.invalidate(_unitsProvider);
            },
          ),
          const Icon(Icons.expand_more_rounded,
              color: AppColors.textSecondary),
        ],
      ),
      children: [
        // Add question button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: OutlinedButton.icon(
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Tambah Soal'),
            onPressed: () => showDialog(
              context: context,
              builder: (_) => _QuestionFormDialog(
                existing: null,
                onSave: (data) async {
                  await ref
                      .read(firestoreDataSourceProvider)
                      .addQuestion(unitId, node.id, data);
                  ref.invalidate(_questionsProvider(
                      (unitId: unitId, nodeId: node.id)));
                },
              ),
            ),
          ),
        ),
        questionsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(8),
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (e, _) => Text(e.toString(),
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.error)),
          data: (questions) {
            if (questions.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Belum ada soal.',
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.textMuted)),
              );
            }
            return Column(
              children: questions
                  .map((q) => _QuestionTile(
                        unitId: unitId,
                        nodeId: node.id,
                        question: q,
                      ))
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _QuestionTile extends ConsumerWidget {
  const _QuestionTile({
    required this.unitId,
    required this.nodeId,
    required this.question,
  });
  final String unitId;
  final String nodeId;
  final QuizQuestion question;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      contentPadding: const EdgeInsets.only(left: 48, right: 8),
      title: Text(question.prompt,
          style:
              AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w700),
          maxLines: 2,
          overflow: TextOverflow.ellipsis),
      subtitle: Text(question.type.name,
          style: AppTypography.bodySmall
              .copyWith(color: AppColors.textSecondary)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit_rounded,
                color: AppColors.primary, size: 16),
            onPressed: () => showDialog(
              context: context,
              builder: (_) => _QuestionFormDialog(
                existing: question.toMap(),
                onSave: (data) async {
                  await ref
                      .read(firestoreDataSourceProvider)
                      .updateQuestion(unitId, nodeId, question.id, data);
                  ref.invalidate(_questionsProvider(
                      (unitId: unitId, nodeId: nodeId)));
                },
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_rounded,
                color: AppColors.error, size: 16),
            onPressed: () async {
              await ref
                  .read(firestoreDataSourceProvider)
                  .deleteQuestion(unitId, nodeId, question.id);
              ref.invalidate(
                  _questionsProvider((unitId: unitId, nodeId: nodeId)));
            },
          ),
        ],
      ),
    );
  }
}

// ─── Seed Tab ─────────────────────────────────────────────────────────────────

class _SeedTab extends ConsumerStatefulWidget {
  const _SeedTab();

  @override
  ConsumerState<_SeedTab> createState() => _SeedTabState();
}

class _SeedTabState extends ConsumerState<_SeedTab> {
  bool _loading = false;

  Future<void> _seed() async {
    setState(() => _loading = true);
    try {
      await ref.read(firestoreDataSourceProvider).seedContent();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Seed berhasil! Data telah ditambahkan ke Firestore.'),
            backgroundColor: AppColors.success,
          ),
        );
        ref.invalidate(_unitsProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal seed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_upload_rounded,
                color: AppColors.primary, size: 64),
            const SizedBox(height: 20),
            Text(
              'Seed Data ke Firestore',
              style: AppTypography.headlineMedium
                  .copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'Tambahkan data awal (kata hari ini, trivia, unit & node) '
              'ke Firestore jika belum ada.',
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _seed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5),
                      )
                    : Text(
                        'Seed Data ke Firestore',
                        style: AppTypography.bodyLarge
                            .copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Dialog Forms ─────────────────────────────────────────────────────────────

class _WordFormDialog extends StatefulWidget {
  const _WordFormDialog({
    required this.existing,
    required this.existingId,
    required this.onSave,
  });
  final WordOfDay? existing;
  final String? existingId;
  final Future<void> Function(Map<String, dynamic>) onSave;

  @override
  State<_WordFormDialog> createState() => _WordFormDialogState();
}

class _WordFormDialogState extends State<_WordFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _arabic;
  late final TextEditingController _transliteration;
  late final TextEditingController _translation;
  late final TextEditingController _partOfSpeech;
  late final TextEditingController _exampleArabic;
  late final TextEditingController _exampleTranslation;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final w = widget.existing;
    _arabic = TextEditingController(text: w?.arabic ?? '');
    _transliteration = TextEditingController(text: w?.transliteration ?? '');
    _translation = TextEditingController(text: w?.translation ?? '');
    _partOfSpeech = TextEditingController(text: w?.partOfSpeech ?? '');
    _exampleArabic = TextEditingController(text: w?.exampleArabic ?? '');
    _exampleTranslation =
        TextEditingController(text: w?.exampleTranslation ?? '');
  }

  @override
  void dispose() {
    _arabic.dispose();
    _transliteration.dispose();
    _translation.dispose();
    _partOfSpeech.dispose();
    _exampleArabic.dispose();
    _exampleTranslation.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await widget.onSave({
        'arabic': _arabic.text.trim(),
        'transliteration': _transliteration.text.trim(),
        'translation': _translation.text.trim(),
        'partOfSpeech': _partOfSpeech.text.trim(),
        'exampleArabic': _exampleArabic.text.trim(),
        'exampleTranslation': _exampleTranslation.text.trim(),
        'level': 1,
        'audioUrl': null,
      });
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return AlertDialog(
      title: Text(isEdit ? 'Edit Kata' : 'Tambah Kata'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _FormField(controller: _arabic, label: 'Arab', required: true),
              _FormField(
                  controller: _transliteration, label: 'Transliterasi', required: true),
              _FormField(
                  controller: _translation, label: 'Terjemahan', required: true),
              _FormField(
                  controller: _partOfSpeech, label: 'Kelas Kata', required: true),
              _FormField(
                  controller: _exampleArabic, label: 'Contoh Arab', required: true),
              _FormField(
                  controller: _exampleTranslation,
                  label: 'Contoh Terjemahan',
                  required: true),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal')),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : Text(isEdit ? 'Simpan' : 'Tambah'),
        ),
      ],
    );
  }
}

class _TriviaFormDialog extends StatefulWidget {
  const _TriviaFormDialog({
    required this.existing,
    required this.existingId,
    required this.onSave,
  });
  final Map<String, dynamic>? existing;
  final String? existingId;
  final Future<void> Function(Map<String, dynamic>) onSave;

  @override
  State<_TriviaFormDialog> createState() => _TriviaFormDialogState();
}

class _TriviaFormDialogState extends State<_TriviaFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _subtitle;
  late final TextEditingController _content;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _title = TextEditingController(text: e?['title'] as String? ?? '');
    _subtitle = TextEditingController(text: e?['subtitle'] as String? ?? '');
    _content = TextEditingController(text: e?['content'] as String? ?? '');
  }

  @override
  void dispose() {
    _title.dispose();
    _subtitle.dispose();
    _content.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await widget.onSave({
        'title': _title.text.trim(),
        'subtitle': _subtitle.text.trim(),
        'content': _content.text.trim(),
        'vocabulary': widget.existing?['vocabulary'] ?? [],
        'imageUrl': widget.existing?['imageUrl'],
      });
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return AlertDialog(
      title: Text(isEdit ? 'Edit Trivia' : 'Tambah Trivia'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _FormField(controller: _title, label: 'Judul', required: true),
              _FormField(
                  controller: _subtitle, label: 'Subjudul', required: true),
              _FormField(
                  controller: _content,
                  label: 'Isi',
                  required: true,
                  maxLines: 5),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal')),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : Text(isEdit ? 'Simpan' : 'Tambah'),
        ),
      ],
    );
  }
}

class _UnitFormDialog extends StatefulWidget {
  const _UnitFormDialog({required this.existing, required this.onSave});
  final Map<String, dynamic>? existing;
  final Future<void> Function(Map<String, dynamic>) onSave;

  @override
  State<_UnitFormDialog> createState() => _UnitFormDialogState();
}

class _UnitFormDialogState extends State<_UnitFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _order;
  bool _isUnlocked = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _title = TextEditingController(text: e?['title'] as String? ?? '');
    _description =
        TextEditingController(text: e?['description'] as String? ?? '');
    _order = TextEditingController(
        text: (e?['order'] as int? ?? 0).toString());
    _isUnlocked = e?['isUnlocked'] as bool? ?? false;
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _order.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await widget.onSave({
        'title': _title.text.trim(),
        'description': _description.text.trim(),
        'isUnlocked': _isUnlocked,
        'order': int.tryParse(_order.text) ?? 0,
      });
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return AlertDialog(
      title: Text(isEdit ? 'Edit Unit' : 'Tambah Unit'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _FormField(controller: _title, label: 'Judul', required: true),
              _FormField(
                  controller: _description,
                  label: 'Deskripsi',
                  required: true),
              _FormField(
                  controller: _order, label: 'Urutan', keyboardType: TextInputType.number),
              SwitchListTile(
                title: const Text('Terbuka'),
                value: _isUnlocked,
                onChanged: (v) => setState(() => _isUnlocked = v),
                activeThumbColor: AppColors.primary,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal')),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : Text(isEdit ? 'Simpan' : 'Tambah'),
        ),
      ],
    );
  }
}

class _NodeFormDialog extends StatefulWidget {
  const _NodeFormDialog({required this.existing, required this.onSave});
  final Map<String, dynamic>? existing;
  final Future<void> Function(Map<String, dynamic>) onSave;

  @override
  State<_NodeFormDialog> createState() => _NodeFormDialogState();
}

class _NodeFormDialogState extends State<_NodeFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _order;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _title = TextEditingController(text: e?['title'] as String? ?? '');
    _order = TextEditingController(
        text: (e?['order'] as int? ?? 0).toString());
  }

  @override
  void dispose() {
    _title.dispose();
    _order.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await widget.onSave({
        'title': _title.text.trim(),
        'order': int.tryParse(_order.text) ?? 0,
      });
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return AlertDialog(
      title: Text(isEdit ? 'Edit Node' : 'Tambah Node'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _FormField(controller: _title, label: 'Judul', required: true),
            _FormField(
                controller: _order,
                label: 'Urutan',
                keyboardType: TextInputType.number),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal')),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : Text(isEdit ? 'Simpan' : 'Tambah'),
        ),
      ],
    );
  }
}

class _QuestionFormDialog extends StatefulWidget {
  const _QuestionFormDialog({required this.existing, required this.onSave});
  final Map<String, dynamic>? existing;
  final Future<void> Function(Map<String, dynamic>) onSave;

  @override
  State<_QuestionFormDialog> createState() => _QuestionFormDialogState();
}

class _QuestionFormDialogState extends State<_QuestionFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _prompt;
  late final TextEditingController _arabicText;
  late final TextEditingController _options;
  late final TextEditingController _correctAnswer;
  late final TextEditingController _hint;
  late final TextEditingController _order;
  late String _type;
  bool _saving = false;

  static const _typeOptions = [
    'multipleChoice',
    'translation',
    'wordArrangement',
    'audio',
    'characterTracing',
    'pronunciation',
  ];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _type = e?['type'] as String? ?? 'multipleChoice';
    _prompt = TextEditingController(text: e?['prompt'] as String? ?? '');
    _arabicText =
        TextEditingController(text: e?['arabicText'] as String? ?? '');
    final opts = (e?['options'] as List<dynamic>? ?? []).join(', ');
    _options = TextEditingController(text: opts);
    _correctAnswer =
        TextEditingController(text: e?['correctAnswer'] as String? ?? '');
    _hint = TextEditingController(text: e?['hint'] as String? ?? '');
    _order = TextEditingController(
        text: (e?['order'] as int? ?? 0).toString());
  }

  @override
  void dispose() {
    _prompt.dispose();
    _arabicText.dispose();
    _options.dispose();
    _correctAnswer.dispose();
    _hint.dispose();
    _order.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final optsList = _options.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      await widget.onSave({
        'type': _type,
        'prompt': _prompt.text.trim(),
        'arabicText':
            _arabicText.text.trim().isEmpty ? null : _arabicText.text.trim(),
        'options': optsList,
        'correctAnswer': _correctAnswer.text.trim(),
        'hint': _hint.text.trim().isEmpty ? null : _hint.text.trim(),
        'words': optsList,
        'audioUrl': null,
        'order': int.tryParse(_order.text) ?? 0,
      });
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return AlertDialog(
      title: Text(isEdit ? 'Edit Soal' : 'Tambah Soal'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _type,
                decoration: const InputDecoration(labelText: 'Tipe Soal'),
                items: _typeOptions
                    .map((t) =>
                        DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _type = v);
                },
              ),
              const SizedBox(height: 8),
              _FormField(controller: _prompt, label: 'Instruksi', required: true),
              _FormField(
                  controller: _arabicText, label: 'Teks Arab (opsional)'),
              _FormField(
                  controller: _options,
                  label: 'Pilihan (pisahkan koma)'),
              _FormField(
                  controller: _correctAnswer, label: 'Jawaban Benar'),
              _FormField(controller: _hint, label: 'Petunjuk (opsional)'),
              _FormField(
                  controller: _order,
                  label: 'Urutan',
                  keyboardType: TextInputType.number),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal')),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : Text(isEdit ? 'Simpan' : 'Tambah'),
        ),
      ],
    );
  }
}

// ─── Shared Helpers ───────────────────────────────────────────────────────────

class _FormField extends StatelessWidget {
  const _FormField({
    required this.controller,
    required this.label,
    this.required = false,
    this.maxLines = 1,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final bool required;
  final int maxLines;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: required
            ? (v) => (v == null || v.trim().isEmpty) ? '$label wajib diisi' : null
            : null,
      ),
    );
  }
}

// ─── Shared Widgets ───────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 10),
          Text(
            value,
            style: AppTypography.headlineLarge.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style:
                  AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            value,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: AppColors.error, size: 48),
            const SizedBox(height: 12),
            Text(
              'Gagal memuat data',
              style:
                  AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              message,
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
