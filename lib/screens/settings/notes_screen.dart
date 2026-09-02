import 'package:flutter/material.dart';
import '../../core/utils/activity_logger.dart';
import '../../core/utils/app_snackbar.dart';
import '../../models/note.dart';
import '../../repositories/note_repository.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../app/theme.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final _repo = NoteRepository();
  List<Note> _notes = [];
  List<Note> _filtered = [];
  bool _loading = true;
  String _search = '';
  String _period = 'all'; // all | today | yesterday | last_week | this_month

  static const _periods = [
    {'id': 'today', 'label': 'Today'},
    {'id': 'yesterday', 'label': 'Yesterday'},
    {'id': 'last_week', 'label': 'Last week'},
    {'id': 'this_month', 'label': 'This month'},
    {'id': 'all', 'label': 'All'},
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _notes = await _repo.getAll();
      _applyFilter();
    } catch (e) {
      debugPrint('Notes load error: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  void _applyFilter() {
    final now = DateTime.now();
    List<Note> list = List.from(_notes);

    if (_period == 'today') {
      final start = DateTime(now.year, now.month, now.day);
      list = list.where((n) => _parse(n.createdAt).isAfter(start) || _isSameDay(_parse(n.createdAt), start)).toList();
      list = list.where((n) {
        final d = _parse(n.updatedAt ?? n.createdAt);
        return d.isAfter(start.subtract(const Duration(seconds: 1)));
      }).toList();
    } else if (_period == 'yesterday') {
      final start = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 1));
      final end = DateTime(now.year, now.month, now.day);
      list = list.where((n) {
        final d = _parse(n.updatedAt ?? n.createdAt);
        return !d.isBefore(start) && d.isBefore(end);
      }).toList();
    } else if (_period == 'last_week') {
      final start = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 7));
      list = list.where((n) {
        final d = _parse(n.updatedAt ?? n.createdAt);
        return !d.isBefore(start);
      }).toList();
    } else if (_period == 'this_month') {
      final start = DateTime(now.year, now.month, 1);
      list = list.where((n) {
        final d = _parse(n.updatedAt ?? n.createdAt);
        return !d.isBefore(start);
      }).toList();
    }

    final q = _search.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((n) {
        return n.title.toLowerCase().contains(q) ||
            n.content.toLowerCase().contains(q);
      }).toList();
    }

    _filtered = list;
  }

  DateTime _parse(String iso) {
    try {
      return DateTime.parse(iso);
    } catch (_) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  void _setPeriod(String id) {
    setState(() {
      _period = id;
      _applyFilter();
    });
  }

  void _setSearch(String v) {
    setState(() {
      _search = v;
      _applyFilter();
    });
  }

  Future<void> _showEditor({Note? existing}) async {
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final contentCtrl = TextEditingController(text: existing?.content ?? '');

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(existing == null ? 'New Note' : 'Edit Note'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    hintText: 'e.g. Refund, Food issue',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: contentCtrl,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Note',
                    hintText: 'Write details…',
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleCtrl.text.trim().isEmpty &&
                    contentCtrl.text.trim().isEmpty) {
                  return;
                }
                Navigator.pop(ctx, true);
              },
              child: Text(existing == null ? 'Add' : 'Save'),
            ),
          ],
        );
      },
    );

    if (ok != true) return;

    final title =
        titleCtrl.text.trim().isEmpty ? 'Note' : titleCtrl.text.trim();
    final content = contentCtrl.text.trim();
    final now = DateTime.now().toIso8601String();

    try {
      if (existing == null) {
        final id = await _repo.insert(
          Note(title: title, content: content, createdAt: now),
        );
        await ActivityLogger.log(
          action: 'create',
          entityType: 'note',
          entityId: id,
          details: 'Note added: $title',
        );
      } else {
        await _repo.update(
          Note(
            id: existing.id,
            title: title,
            content: content,
            createdAt: existing.createdAt,
            updatedAt: now,
          ),
        );
        await ActivityLogger.log(
          action: 'update',
          entityType: 'note',
          entityId: existing.id,
          details: 'Note updated: $title',
        );
      }
      await _load();
      if (mounted) {
        showSuccessSnackBar(
          context,
          existing == null ? 'Note added' : 'Note saved',
        );
      }
    } catch (e) {
      if (mounted) showAppSnackBar(context, 'Failed: $e', isError: true);
    }
  }

  Future<void> _delete(Note note) async {
    final ok = await showConfirmationDialog(
      context,
      title: 'Delete note?',
      message: note.title.isEmpty ? 'This note will be permanently deleted.' : note.title,
      confirmText: 'Delete',
      isDestructive: true,
      icon: Icons.delete_outline_rounded,
    );
    if (!ok || note.id == null) return;
    try {
      await _repo.delete(note.id!);
      await ActivityLogger.log(
        action: 'delete',
        entityType: 'note',
        entityId: note.id,
        details: 'Note deleted: ${note.title}',
      );
      await _load();
      if (mounted) showSuccessSnackBar(context, 'Note deleted');
    } catch (e) {
      if (mounted) showAppSnackBar(context, 'Failed: $e', isError: true);
    }
  }

  String _fmt(String iso) {
    try {
      final d = DateTime.parse(iso);
      return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} '
          '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Notes'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            tooltip: 'New note',
            onPressed: () => _showEditor(),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showEditor(),
        icon: const Icon(Icons.note_add_outlined),
        label: const Text('New Note'),
        backgroundColor: AppColors.purple,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search notes…',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              onChanged: _setSearch,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _periods.map((p) {
                  final selected = _period == p['id'];
                  final isDark = theme.brightness == Brightness.dark;
                  return ChoiceChip(
                    label: Text(p['label']!),
                    selected: selected,
                    showCheckmark: false,
                    onSelected: (_) => _setPeriod(p['id']!),
                    selectedColor: isDark
                        ? const Color(0xFF009966).withOpacity(0.28)
                        : const Color(0xFF009966).withOpacity(0.16),
                    backgroundColor: isDark
                        ? const Color(0xFF242424)
                        : const Color(0xFFE4E6EB),
                    side: BorderSide(
                      color: selected
                          ? const Color(0xFF009966)
                          : theme.dividerColor,
                    ),
                    labelStyle: TextStyle(
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.w500,
                      color: selected
                          ? (isDark
                              ? const Color(0xFF8AB4F8)
                              : const Color(0xFF00754D))
                          : theme.colorScheme.onSurface,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _loading ? 'Loading…' : '${_filtered.length} note(s)',
                style: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.sticky_note_2_outlined,
                              size: 48,
                              color: theme.colorScheme.onSurface
                                  .withOpacity(0.35),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No notes for this filter',
                              style: TextStyle(
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
                        itemCount: _filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final n = _filtered[i];
                          return Container(
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1A1A1A)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: theme.dividerColor),
                            ),
                            child: ListTile(
                              contentPadding:
                                  const EdgeInsets.fromLTRB(16, 10, 8, 10),
                              title: Text(
                                n.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (n.content.isNotEmpty)
                                      Text(
                                        n.content,
                                        maxLines: 4,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: theme.colorScheme.onSurface
                                              .withOpacity(0.7),
                                        ),
                                      ),
                                    const SizedBox(height: 6),
                                    Text(
                                      _fmt(n.updatedAt ?? n.createdAt),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: theme.colorScheme.onSurface
                                            .withOpacity(0.45),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              isThreeLine: true,
                              trailing: PopupMenuButton<String>(
                                onSelected: (v) {
                                  if (v == 'edit') _showEditor(existing: n);
                                  if (v == 'delete') _delete(n);
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Text('Edit'),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Delete'),
                                  ),
                                ],
                              ),
                              onTap: () => _showEditor(existing: n),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
