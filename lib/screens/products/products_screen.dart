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
    final discountCtrl = TextEditingController(text: existing?.discount.toString() ?? '0');
    final stockCtrl = TextEditingController(text: existing?.stockQuantity.toString() ?? '0');
    final reorderCtrl = TextEditingController(text: existing?.reorderLevel.toString() ?? '10');
    final warrantyCtrl = TextEditingController(text: existing?.warrantyMonths.toString() ?? '0');
    String unit = existing?.unit ?? 'Piece';
    int? catId = existing?.categoryId;
    bool isActive = existing?.isActive ?? true;
    final catSearchCtrl = TextEditingController(
      text: existing == null
          ? ''
          : (_cats.where((c) => c.id == existing.categoryId).map((c) => c.name).cast<String?>().followedBy([null]).first ?? ''),
    );
    List<Category> catHits = [];

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          final isDark = Theme.of(ctx).brightness == Brightness.dark;
          void submit() {
            if (nameCtrl.text.trim().isEmpty) {
              showErrorSnackBar(context, 'Product name is required');
              return;
            }
            final sell = double.tryParse(sellCtrl.text);
            if (sell == null || sell < 0) {
              showErrorSnackBar(context, 'Selling price is required');
              return;
            }
            Navigator.pop(ctx, true);
          }
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextField(
                                controller: catSearchCtrl,
                                decoration: InputDecoration(
                                  labelText: 'Category (type to search)',
                                  suffixIcon: catId != null
                                      ? IconButton(
                                          icon: const Icon(Icons.close, size: 18),
                                          onPressed: () => setS(() {
                                            catId = null;
                                            catSearchCtrl.clear();
                                            catHits = [];
                                          }),
                                        )
                                      : null,
                                ),
                                onChanged: (v) {
                                  final q = v.trim().toLowerCase();
                                  setS(() {
                                    catId = null;
                                    catHits = q.isEmpty
                                        ? []
                                        : _cats.where((c) => c.name.toLowerCase().contains(q)).take(8).toList();
                                  });
                                },
                              ),
                              if (catHits.isNotEmpty)
                                Container(
                                  constraints: const BoxConstraints(maxHeight: 120),
                                  margin: const EdgeInsets.only(top: 4),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: catHits.length,
                                    itemBuilder: (_, i) {
                                      final c = catHits[i];
                                      return ListTile(
                                        dense: true,
                                        title: Text(c.name, style: const TextStyle(fontSize: 13)),
                                        onTap: () => setS(() {
                                          catId = c.id;
                                          catSearchCtrl.text = c.name;
                                          catHits = [];
                                        }),
                                      );
                                    },
                                  ),
                                ),
                            ],
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
                      TextField(controller: discountCtrl, decoration: const InputDecoration(labelText: 'Discount (per unit)'), keyboardType: TextInputType.number),
                      const SizedBox(height: 10),
                      Row(children: [
                        Expanded(child: TextField(controller: stockCtrl, decoration: const InputDecoration(labelText: 'Stock'), keyboardType: TextInputType.number)),
                        const SizedBox(width: 10),
                        Expanded(child: TextField(controller: reorderCtrl, decoration: const InputDecoration(labelText: 'Reorder Level'), keyboardType: TextInputType.number)),
                      ]),
                      const SizedBox(height: 10),
                      TextField(controller: warrantyCtrl, decoration: const InputDecoration(labelText: 'Warranty (months)'), keyboardType: TextInputType.number),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Active'),
                        value: isActive,
                        onChanged: (v) => setS(() => isActive = v),
                      ),
                      const SizedBox(height: 12),
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
      discount: double.tryParse(discountCtrl.text) ?? 0,
      stockQuantity: double.tryParse(stockCtrl.text) ?? 0,
      reorderLevel: double.tryParse(reorderCtrl.text) ?? 10,
      minStock: double.tryParse(reorderCtrl.text) ?? 10,
      warrantyMonths: int.tryParse(warrantyCtrl.text) ?? 0,
      isActive: isActive,
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



  Future<void> _toggleActive(Product p) async {
    final ok = await context.read<ProductProvider>().toggleActive(p);
    if (!mounted) return;
    if (ok) {
      showSuccessSnackBar(
        context,
        p.isActive ? 'Product deactivated' : 'Product activated',
      );
      _applyFilter(_search.text);
    } else {
      showErrorSnackBar(
        context,
        context.read<ProductProvider>().error ?? 'Failed to update status',
      );
    }
  }

  Future<void> _deleteProduct(Product p) async {
    final confirm = await showConfirmationDialog(
      context,
      title: 'Delete Product',
      message: 'Delete "${p.name}" permanently? This cannot be undone.',
      confirmText: 'Delete',
      isDestructive: true,
      icon: Icons.delete_outline_rounded,
    );
    if (!confirm) return;
    final ok = await context.read<ProductProvider>().delete(p.id!);
    if (!mounted) return;
    if (ok) {
      showSuccessSnackBar(context, 'Product deleted');
      _applyFilter(_search.text);
    } else {
      showErrorSnackBar(
        context,
        context.read<ProductProvider>().error ?? 'Failed to delete',
      );
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
                                  child: Column(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
                                        child: Row(
                                          children: [
                                            const Expanded(flex: 3, child: Text('Product', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey))),
                                            const Expanded(flex: 2, child: Text('Price', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey))),
                                            const Expanded(flex: 2, child: Text('Stock', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey))),
                                            const Expanded(flex: 2, child: Text('Status', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey))),
                                            const SizedBox(width: 72, child: Text('Active', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey))),
                                            const SizedBox(width: 84),
                                          ],
                                        ),
                                      ),
                                      Divider(height: 1, thickness: 1, color: Colors.grey.shade200),
                                      Expanded(
                                        child: ListView.separated(
                                    itemCount: _filtered.length,
                                    separatorBuilder: (_, __) => Divider(height: 1, thickness: 1, color: Colors.grey.shade200),
                                    itemBuilder: (_, i) {
                                      final p = _filtered[i];
                                      final isOut = p.isOutOfStock;
                                      final isLow = p.isLowStock;
                                      final stockLabel = isOut ? 'Out of Stock' : (isLow ? 'Low Stock' : 'In Stock');
                                      final stockColor = isOut ? Colors.red : (isLow ? Colors.orange.shade800 : AppColors.green);

                                      return InkWell(
                                        onDoubleTap: () => _addEdit(p),
                                        child: Padding(
                                          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
                                          child: Row(
                                            children: [
                                              // Product
                                              Expanded(
                                                flex: 3,
                                                child: Row(
                                                  children: [
                                                    Container(
                                                      width: 36,
                                                      height: 36,
                                                      alignment: Alignment.center,
                                                      decoration: const BoxDecoration(
                                                        color: AppColors.greenSoft,
                                                        shape: BoxShape.circle,
                                                      ),
                                                      child: Text(
                                                        p.name.isNotEmpty ? p.name[0].toUpperCase() : 'P',
                                                        style: const TextStyle(
                                                          fontWeight: FontWeight.w700,
                                                          color: AppColors.green,
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 14),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text(
                                                            p.name,
                                                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                                                            maxLines: 1,
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                          if (p.sku != null && p.sku!.isNotEmpty) ...[
                                                            const SizedBox(height: 2),
                                                            Text(
                                                              'SKU: ${p.sku}',
                                                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                                              maxLines: 1,
                                                              overflow: TextOverflow.ellipsis,
                                                            ),
                                                          ],
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              // Price
                                              Expanded(
                                                flex: 2,
                                                child: Text(
                                                  CurrencyUtils.format(p.sellingPrice),
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                    color: AppColors.green,
                                                  ),
                                                ),
                                              ),
                                              // Stock
                                              Expanded(
                                                flex: 2,
                                                child: Text(
                                                  '${p.stockQuantity.toStringAsFixed(0)} ${p.unit}',
                                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                                ),
                                              ),
                                              // Status
                                              Expanded(
                                                flex: 2,
                                                child: Text(
                                                  stockLabel,
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                    color: stockColor,
                                                  ),
                                                ),
                                              ),
                                              // Active — fixed, next to actions
                                              SizedBox(
                                                width: 72,
                                                child: Text(
                                                  p.isActive ? 'Active' : 'Inactive',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                    color: p.isActive ? AppColors.green : Colors.grey.shade600,
                                                  ),
                                                ),
                                              ),
                                              // Actions — tight to Active
                                              SizedBox(
                                                width: 84,
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.end,
                                                  children: [
                                                    IconButton(
                                                      tooltip: 'Edit',
                                                      onPressed: () => _addEdit(p),
                                                      visualDensity: VisualDensity.compact,
                                                      padding: EdgeInsets.zero,
                                                      constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                                                      icon: Icon(Icons.edit_outlined, size: 20, color: Colors.grey.shade700),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    IconButton(
                                                      tooltip: 'Delete',
                                                      onPressed: () => _deleteProduct(p),
                                                      visualDensity: VisualDensity.compact,
                                                      padding: EdgeInsets.zero,
                                                      constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                                                      icon: Icon(Icons.delete_outline, size: 20, color: Colors.red.shade400),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                      ),
                                    ],
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
