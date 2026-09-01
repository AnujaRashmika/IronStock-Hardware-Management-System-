import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/theme.dart';
import '../../core/utils/app_snackbar.dart';
import '../../models/category.dart';
import '../../repositories/category_repository.dart';
import '../../widgets/app_header.dart';
import '../../widgets/confirmation_dialog.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});
  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final _repo = CategoryRepository();
  final _search = TextEditingController();
  List<Category> _list = [];
  List<Category> _filtered = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    _list = await _repo.getAll();
    _applyFilter(_search.text);
    setState(() => loading = false);
  }

  void _applyFilter(String q) {
    if (q.trim().isEmpty) {
      _filtered = List.from(_list);
    } else {
      _filtered = _list.where((c) => c.name.toLowerCase().contains(q.toLowerCase())).toList();
    }
    setState(() {});
  }

  Future<void> _showAddEdit({Category? category}) async {
    final isEditing = category != null;
    final ctrl = TextEditingController(text: category?.name ?? '');
    final formKey = GlobalKey<FormState>();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;

        Future<void> save() async {
          if (!formKey.currentState!.validate()) return;
          Navigator.pop(ctx, true);
        }

        return CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.enter): save,
            const SingleActivator(LogicalKeyboardKey.numpadEnter): save,
          },
          child: Focus(
            autofocus: true,
            child: Dialog(
              backgroundColor: Colors.transparent,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.5 : 0.15),
                        blurRadius: 30,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                gradient: AppTheme.primaryGradient,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                isEditing ? Icons.edit_outlined : Icons.category_outlined,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Text(
                              isEditing ? 'Edit Category' : 'Add Category',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        TextFormField(
                          controller: ctrl,
                          autofocus: true,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => save(),
                          decoration: const InputDecoration(
                            labelText: 'Category Name *',
                            prefixIcon: Icon(Icons.label_outline),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Name is required';
                            return null;
                          },
                        ),
                        const SizedBox(height: 22),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 13),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Cancel'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 13),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: save,
                                child: Text(isEditing ? 'Update' : 'Save'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    if (ok != true || ctrl.text.trim().isEmpty) return;
    try {
      if (isEditing) {
        await _repo.update(Category(
          id: category.id,
          name: ctrl.text.trim(),
          description: category.description,
          isActive: category.isActive,
          createdAt: category.createdAt,
        ));
        if (mounted) showSuccessSnackBar(context, 'Category updated');
      } else {
        await _repo.insert(Category(
          name: ctrl.text.trim(),
          createdAt: DateTime.now().toIso8601String(),
        ));
        if (mounted) showSuccessSnackBar(context, 'Category added');
      }
      await _load();
    } catch (e) {
      if (mounted) showErrorSnackBar(context, 'Failed: $e');
    }
  }

  Future<void> _delete(Category c) async {
    final ok = await showConfirmationDialog(
      context,
      title: 'Delete Category',
      message: 'Are you sure you want to delete "${c.name}"?',
      confirmText: 'Delete',
      isDestructive: true,
      icon: Icons.delete_outline_rounded,
    );
    if (!ok || c.id == null) return;
    await _repo.delete(c.id!);
    await _load();
    if (mounted) showSuccessSnackBar(context, 'Category deleted');
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.enter): () => _showAddEdit(),
        const SingleActivator(LogicalKeyboardKey.numpadEnter): () => _showAddEdit(),
      },
      child: Focus(
        autofocus: true,
        child: Column(
          children: [
            const AppHeader(
              title: 'Categories',
              subtitle: 'Organize products — Enter to add, double-click to edit',
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: TextField(
                              controller: _search,
                              decoration: InputDecoration(
                                hintText: 'Search categories...',
                                prefixIcon: const Icon(Icons.search),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onChanged: _applyFilter,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        SizedBox(
                          height: 48,
                          child: ElevatedButton.icon(
                            style: appButtonStyle(color: AppColors.green),
                            onPressed: () => _showAddEdit(),
                            icon: const Icon(Icons.add),
                            label: const Text('Add Category'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: loading
                          ? const Center(child: CircularProgressIndicator())
                          : _filtered.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.category_outlined, size: 50, color: Colors.grey.shade400),
                                      const SizedBox(height: 12),
                                      Text('No categories yet.', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                                    ],
                                  ),
                                )
                              : Card(
                                  clipBehavior: Clip.antiAlias,
                                  child: ListView.separated(
                                    itemCount: _filtered.length,
                                    separatorBuilder: (_, __) => const Divider(height: 1),
                                    itemBuilder: (_, i) {
                                      final c = _filtered[i];
                                      return InkWell(
                                        onDoubleTap: () => _showAddEdit(category: c),
                                        child: ListTile(
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                          leading: CircleAvatar(
                                            backgroundColor: AppColors.blueSoft,
                                            child: Text(
                                              c.name[0].toUpperCase(),
                                              style: const TextStyle(color: AppColors.blue, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                          title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                          trailing: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.edit_outlined, color: Colors.orange),
                                                tooltip: 'Edit',
                                                onPressed: () => _showAddEdit(category: c),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                                tooltip: 'Delete',
                                                onPressed: () => _delete(c),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
