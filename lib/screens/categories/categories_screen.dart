import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/utils/app_snackbar.dart';
import '../../models/category.dart';
import '../../repositories/category_repository.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});
  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final _repo = CategoryRepository();
  List<Category> _list = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    _list = await _repo.getAll();
    setState(() => loading = false);
  }

  Future<void> _add() async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Category'),
        content: TextField(controller: ctrl, autofocus: true, decoration: const InputDecoration(labelText: 'Category Name'),
          onSubmitted: (_) => Navigator.pop(ctx, true)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Add')),
        ],
      ),
    );
    if (ok == true && ctrl.text.trim().isNotEmpty) {
      await _repo.insert(Category(name: ctrl.text.trim(), createdAt: DateTime.now().toIso8601String()));
      await _load();
      if (mounted) showSuccessSnackBar(context, 'Category added');
    }
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.enter): _add,
        const SingleActivator(LogicalKeyboardKey.numpadEnter): _add,
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Text('Categories', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                  const Spacer(),
                  ElevatedButton.icon(onPressed: _add, icon: const Icon(Icons.add), label: const Text('Add Category')),
                ]),
                const SizedBox(height: 16),
                Expanded(
                  child: loading
                      ? const Center(child: CircularProgressIndicator())
                      : _list.isEmpty
                          ? const Center(child: Text('No categories. Press Enter to add.'))
                          : Card(
                              child: ListView.separated(
                                itemCount: _list.length,
                                separatorBuilder: (_, __) => const Divider(height: 1),
                                itemBuilder: (_, i) => ListTile(
                                  title: Text(_list[i].name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 18),
                                    onPressed: () async {
                                      await _repo.delete(_list[i].id!);
                                      await _load();
                                    },
                                  ),
                                ),
                              ),
                            ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
