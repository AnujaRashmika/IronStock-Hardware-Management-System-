import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/theme.dart';
import '../../core/utils/app_snackbar.dart';
import '../../core/utils/currency_utils.dart';
import '../../core/database/database_helper.dart';
import '../../core/constants/db_constants.dart';
import '../../models/supplier.dart';
import '../../widgets/app_header.dart';
import '../../widgets/confirmation_dialog.dart';

class SuppliersScreen extends StatefulWidget {
  const SuppliersScreen({super.key});
  @override
  State<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends State<SuppliersScreen> {
  final _search = TextEditingController();
  List<Supplier> _list = [];
  List<Supplier> _filtered = [];
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
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(DbConstants.suppliers, orderBy: 'name ASC');
    _list = rows.map(Supplier.fromMap).toList();
    _filter(_search.text);
    setState(() => loading = false);
  }

  void _filter(String q) {
    _filtered = q.trim().isEmpty
        ? List.from(_list)
        : _list.where((s) =>
            s.name.toLowerCase().contains(q.toLowerCase()) ||
            (s.phone ?? '').contains(q) ||
            (s.company ?? '').toLowerCase().contains(q.toLowerCase())).toList();
    setState(() {});
  }

  Future<void> _showAddEdit({Supplier? supplier}) async {
    final isEditing = supplier != null;
    final name = TextEditingController(text: supplier?.name ?? '');
    final phone = TextEditingController(text: supplier?.phone ?? '');
    final company = TextEditingController(text: supplier?.company ?? '');
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
            child: Dialog(
              backgroundColor: Colors.transparent,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
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
                                isEditing ? Icons.edit_outlined : Icons.local_shipping_outlined,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(isEditing ? 'Edit Supplier' : 'Add Supplier',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: name,
                          autofocus: true,
                          decoration: const InputDecoration(labelText: 'Name *', prefixIcon: Icon(Icons.person_outline)),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                          onFieldSubmitted: (_) => save(),
                        ),
                        const SizedBox(height: 10),
                        TextField(controller: company, decoration: const InputDecoration(labelText: 'Company', prefixIcon: Icon(Icons.business_outlined))),
                        const SizedBox(height: 10),
                        TextField(controller: phone, decoration: const InputDecoration(labelText: 'Phone', prefixIcon: Icon(Icons.phone_outlined))),
                        const SizedBox(height: 20),
                        Row(children: [
                          Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel'))),
                          const SizedBox(width: 12),
                          Expanded(child: ElevatedButton(onPressed: save, child: Text(isEditing ? 'Update' : 'Save'))),
                        ]),
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

    if (ok != true || name.text.trim().isEmpty) return;
    final db = await DatabaseHelper.instance.database;
    final map = Supplier(
      id: supplier?.id,
      name: name.text.trim(),
      company: company.text,
      phone: phone.text,
      currentBalance: supplier?.currentBalance ?? 0,
      creditLimit: supplier?.creditLimit ?? 0,
      createdAt: supplier?.createdAt ?? DateTime.now().toIso8601String(),
    ).toMap();
    if (isEditing) {
      await db.update(DbConstants.suppliers, map..remove('id'), where: 'id = ?', whereArgs: [supplier.id]);
      if (mounted) showSuccessSnackBar(context, 'Supplier updated');
    } else {
      await db.insert(DbConstants.suppliers, map..remove('id'));
      if (mounted) showSuccessSnackBar(context, 'Supplier added');
    }
    await _load();
  }

  Future<void> _delete(Supplier s) async {
    final ok = await showConfirmationDialog(
      context,
      title: 'Delete Supplier',
      message: 'Delete "${s.name}"?',
      confirmText: 'Delete',
      isDestructive: true,
    );
    if (!ok || s.id == null) return;
    final db = await DatabaseHelper.instance.database;
    await db.delete(DbConstants.suppliers, where: 'id = ?', whereArgs: [s.id]);
    await _load();
    if (mounted) showSuccessSnackBar(context, 'Supplier deleted');
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
            const AppHeader(title: 'Suppliers', subtitle: 'Manage suppliers — Enter to add, double-click to edit'),
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
                                hintText: 'Search suppliers...',
                                prefixIcon: const Icon(Icons.search),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onChanged: _filter,
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
                            label: const Text('Add Supplier'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: loading
                          ? const Center(child: CircularProgressIndicator())
                          : _filtered.isEmpty
                              ? Center(child: Text('No suppliers yet.', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)))
                              : Card(
                                  clipBehavior: Clip.antiAlias,
                                  child: ListView.separated(
                                    itemCount: _filtered.length,
                                    separatorBuilder: (_, __) => const Divider(height: 1),
                                    itemBuilder: (_, i) {
                                      final s = _filtered[i];
                                      return InkWell(
                                        onDoubleTap: () => _showAddEdit(supplier: s),
                                        child: ListTile(
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                          leading: CircleAvatar(
                                            backgroundColor: AppColors.purpleSoft,
                                            child: Text(s.name[0].toUpperCase(),
                                                style: const TextStyle(color: AppColors.purple, fontWeight: FontWeight.bold)),
                                          ),
                                          title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                          subtitle: Text('${s.company ?? ''} • ${s.phone ?? ''}',
                                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                          trailing: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              if (s.currentBalance > 0)
                                                Padding(
                                                  padding: const EdgeInsets.only(right: 8),
                                                  child: Text('Due: ${CurrencyUtils.format(s.currentBalance)}',
                                                      style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.w600, fontSize: 12)),
                                                ),
                                              IconButton(
                                                icon: const Icon(Icons.edit_outlined, color: Colors.orange),
                                                onPressed: () => _showAddEdit(supplier: s),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                                onPressed: () => _delete(s),
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
