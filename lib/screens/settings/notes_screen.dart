import 'package:flutter/material.dart';
import '../../core/database/database_helper.dart';
import '../../core/utils/app_snackbar.dart';
import '../../widgets/page_header.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});
  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  List<Map<String, dynamic>> notes = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    final db = await DatabaseHelper.instance.database;
    // notes table may exist from helper
    try {
      notes = await db.query('notes', orderBy: 'created_at DESC');
    } catch (_) {
      await db.execute(
        'CREATE TABLE IF NOT EXISTS notes (id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT NOT NULL, content TEXT, created_at TEXT NOT NULL, updated_at TEXT)',
      );
      notes = [];
    }
    setState(() => loading = false);
  }

  Future<void> _add() async {
    final title = TextEditingController();
    final content = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New note'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: title, decoration: const InputDecoration(labelText: 'Title')),
            const SizedBox(height: 8),
            TextField(controller: content, decoration: const InputDecoration(labelText: 'Content'), maxLines: 4),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      ),
    );
    if (ok == true && title.text.trim().isNotEmpty) {
      final db = await DatabaseHelper.instance.database;
      await db.insert('notes', {
        'title': title.text.trim(),
        'content': content.text.trim(),
        'created_at': DateTime.now().toIso8601String(),
      });
      await _load();
      if (mounted) showSuccessSnackBar(context, 'Note saved');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes'),
        actions: [
          IconButton(onPressed: _add, icon: const Icon(Icons.add)),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : notes.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('No notes yet'),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(onPressed: _add, icon: const Icon(Icons.add), label: const Text('Add note')),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: notes.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final n = notes[i];
                      return Card(
                        child: ListTile(
                          title: Text(n['title']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w500)),
                          subtitle: Text(n['content']?.toString() ?? '', maxLines: 2, overflow: TextOverflow.ellipsis),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
