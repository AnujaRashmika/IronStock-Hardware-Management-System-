import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../core/utils/app_snackbar.dart';
import '../../core/utils/currency_utils.dart';
import '../../core/constants/app_constants.dart';
import '../../models/product.dart';
import '../../providers/product_provider.dart';
import '../../repositories/category_repository.dart';
import '../../models/category.dart';
import '../../widgets/app_header.dart';
import '../../widgets/confirmation_dialog.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});
  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final _search = TextEditingController();
  List<Category> _cats = [];
  List<Product> _filtered = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<ProductProvider>().load();
      _cats = await CategoryRepository().getAll();
      _applyFilter('');
      setState(() {});
    });
  }

  void _applyFilter(String q) {
    final all = context.read<ProductProvider>().products;
    if (q.trim().isEmpty) {
      _filtered = List.from(all);
    } else {
      final lower = q.toLowerCase();
      _filtered = all.where((p) =>
          p.name.toLowerCase().contains(lower) ||
          (p.sku ?? '').toLowerCase().contains(lower) ||
          (p.brand ?? '').toLowerCase().contains(lower)).toList();
    }
    setState(() {});
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _addEdit([Product? existing]) async {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final skuCtrl = TextEditingController(text: existing?.sku ?? '');
    final brandCtrl = TextEditingController(text: existing?.brand ?? '');
    final purchaseCtrl = TextEditingController(text: existing?.purchasePrice.toString() ?? '0');
    final sellCtrl = TextEditingController(text: existing?.sellingPrice.toString() ?? '0');
    final stockCtrl = TextEditingController(text: existing?.stockQuantity.toString() ?? '0');
    final reorderCtrl = TextEditingController(text: existing?.reorderLevel.toString() ?? '10');
    final warrantyCtrl = TextEditingController(text: existing?.warrantyMonths.toString() ?? '0');
    String unit = existing?.unit ?? 'Piece';
    int? catId = existing?.categoryId;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          final isDark = Theme.of(ctx).brightness == Brightness.dark;
          void submit() => Navigator.pop(ctx, true);
          return CallbackShortcuts(
            bindings: {
              const SingleActivator(LogicalKeyboardKey.enter): submit,
              const SingleActivator(LogicalKeyboardKey.numpadEnter): submit,
            },
            child: Focus(
              autofocus: true,
              child: Dialog(
            backgroundColor: Colors.transparent,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(existing == null ? 'Add Product' : 'Edit Product',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 16),
                      TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Product Name *')),
                      const SizedBox(height: 10),
                      Row(children: [
                        Expanded(child: TextField(controller: skuCtrl, decoration: const InputDecoration(labelText: 'SKU'))),
                        const SizedBox(width: 10),
                        Expanded(child: TextField(controller: brandCtrl, decoration: const InputDecoration(labelText: 'Brand'))),
                      ]),
                      const SizedBox(height: 10),
                      Row(children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: unit,
                            decoration: const InputDecoration(labelText: 'Unit'),
                            items: AppConstants.units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                            onChanged: (v) => setS(() => unit = v ?? 'Piece'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<int?>(
                            value: catId,
                            decoration: const InputDecoration(labelText: 'Category'),
                            items: [
                              const DropdownMenuItem(value: null, child: Text('None')),
                              ..._cats.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
                            ],
                            onChanged: (v) => setS(() => catId = v),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 10),
                      Row(children: [
                        Expanded(child: TextField(controller: purchaseCtrl, decoration: const InputDecoration(labelText: 'Purchase Price'), keyboardType: TextInputType.number)),
                        const SizedBox(width: 10),
                        Expanded(child: TextField(controller: sellCtrl, decoration: const InputDecoration(labelText: 'Selling Price'), keyboardType: TextInputType.number)),
                      ]),
                      const SizedBox(height: 10),
                      Row(children: [
                        Expanded(child: TextField(controller: stockCtrl, decoration: const InputDecoration(labelText: 'Stock'), keyboardType: TextInputType.number)),
                        const SizedBox(width: 10),
                        Expanded(child: TextField(controller: reorderCtrl, decoration: const InputDecoration(labelText: 'Reorder Level'), keyboardType: TextInputType.number)),
                      ]),
                      const SizedBox(height: 10),
                      TextField(controller: warrantyCtrl, decoration: const InputDecoration(labelText: 'Warranty (months)'), keyboardType: TextInputType.number),
                      const SizedBox(height: 20),
                      Row(children: [
                        Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel'))),
                        const SizedBox(width: 12),
                        Expanded(child: ElevatedButton(onPressed: submit, child: Text(existing == null ? 'Save' : 'Update'))),
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
      ),
    );
    if (ok != true || nameCtrl.text.trim().isEmpty) return;
    final p = Product(
      id: existing?.id,
      name: nameCtrl.text.trim(),
      sku: skuCtrl.text.trim().isEmpty ? null : skuCtrl.text.trim(),
      brand: brandCtrl.text.trim().isEmpty ? null : brandCtrl.text.trim(),
      categoryId: catId,
      unit: unit,
      purchasePrice: double.tryParse(purchaseCtrl.text) ?? 0,
      sellingPrice: double.tryParse(sellCtrl.text) ?? 0,
      stockQuantity: double.tryParse(stockCtrl.text) ?? 0,
      reorderLevel: double.tryParse(reorderCtrl.text) ?? 10,
      minStock: double.tryParse(reorderCtrl.text) ?? 10,
      warrantyMonths: int.tryParse(warrantyCtrl.text) ?? 0,
      createdAt: existing?.createdAt ?? DateTime.now().toIso8601String(),
      updatedAt: DateTime.now().toIso8601String(),
    );
    final prov = context.read<ProductProvider>();
    final success = existing == null ? await prov.add(p) : await prov.update(p);
    if (mounted) {
      if (success) {
        _applyFilter(_search.text);
        showSuccessSnackBar(context, existing == null ? 'Product added' : 'Product updated');
      } else {
        showErrorSnackBar(context, prov.error ?? 'Failed');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.enter): () => _addEdit(),
        const SingleActivator(LogicalKeyboardKey.numpadEnter): () => _addEdit(),
      },
      child: Focus(
        autofocus: true,
        child: Column(
          children: [
            const AppHeader(title: 'Products', subtitle: 'Manage store products and stock'),
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
                                hintText: 'Search by name, SKU or brand...',
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
                            onPressed: () => _addEdit(),
                            icon: const Icon(Icons.add),
                            label: const Text('Add Product'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: context.watch<ProductProvider>().loading
                          ? const Center(child: CircularProgressIndicator())
                          : _filtered.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.inventory_2_outlined, size: 50, color: Colors.grey.shade400),
                                      const SizedBox(height: 12),
                                      Text('No products yet.', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                                    ],
                                  ),
                                )
                              : Card(
                                  clipBehavior: Clip.antiAlias,
                                  child: ListView.separated(
                                    itemCount: _filtered.length,
                                    separatorBuilder: (_, __) => const Divider(height: 1),
                                    itemBuilder: (_, i) {
                                      final p = _filtered[i];
                                      Color statusColor = Colors.green;
                                      String status = 'In Stock';
                                      if (p.isOutOfStock) {
                                        status = 'Out';
                                        statusColor = Colors.red;
                                      } else if (p.isLowStock) {
                                        status = 'Low';
                                        statusColor = Colors.orange;
                                      }
                                      return InkWell(
                                        onDoubleTap: () => _addEdit(p),
                                        child: ListTile(
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                          leading: CircleAvatar(
                                            backgroundColor: AppColors.greenSoft,
                                            child: Text(
                                              p.name.isNotEmpty ? p.name[0].toUpperCase() : 'P',
                                              style: const TextStyle(color: AppColors.green, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                          title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                          subtitle: Text(
                                            '${p.unit} • ${CurrencyUtils.format(p.sellingPrice)} • Stock: ${p.stockQuantity}',
                                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                          ),
                                          trailing: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.w600, fontSize: 12)),
                                              const SizedBox(width: 8),
                                              IconButton(
                                                icon: const Icon(Icons.edit_outlined, color: Colors.orange),
                                                onPressed: () => _addEdit(p),
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
