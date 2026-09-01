import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../core/utils/app_snackbar.dart';
import '../../core/utils/currency_utils.dart';
import '../../core/constants/app_constants.dart';
import '../../models/product.dart';
import '../../providers/product_provider.dart';
import '../../repositories/category_repository.dart';
import '../../models/category.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});
  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  List<Category> _cats = [];
  final _catRepo = CategoryRepository();

  @override
  void initState() {
    super.initState();
    context.read<ProductProvider>().load();
    _catRepo.getAll().then((c) => setState(() => _cats = c));
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
        builder: (ctx, setS) => AlertDialog(
          title: Text(existing == null ? 'Add Product' : 'Edit Product'),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Product Name *')),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: TextField(controller: skuCtrl, decoration: const InputDecoration(labelText: 'SKU / Code'))),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: brandCtrl, decoration: const InputDecoration(labelText: 'Brand'))),
                  ]),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: unit,
                        decoration: const InputDecoration(labelText: 'Unit'),
                        items: AppConstants.units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                        onChanged: (v) => setS(() => unit = v ?? 'Piece'),
                      ),
                    ),
                    const SizedBox(width: 8),
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
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: TextField(controller: purchaseCtrl, decoration: const InputDecoration(labelText: 'Purchase Price'), keyboardType: TextInputType.number)),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: sellCtrl, decoration: const InputDecoration(labelText: 'Selling Price'), keyboardType: TextInputType.number)),
                  ]),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: TextField(controller: stockCtrl, decoration: const InputDecoration(labelText: 'Stock'), keyboardType: TextInputType.number)),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: reorderCtrl, decoration: const InputDecoration(labelText: 'Reorder Level'), keyboardType: TextInputType.number)),
                  ]),
                  const SizedBox(height: 8),
                  TextField(controller: warrantyCtrl, decoration: const InputDecoration(labelText: 'Warranty (months)'), keyboardType: TextInputType.number),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: Text(existing == null ? 'Add' : 'Save')),
          ],
        ),
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
        showSuccessSnackBar(context, existing == null ? 'Product added' : 'Product updated');
      } else {
        showErrorSnackBar(context, prov.error ?? 'Failed');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ProductProvider>();
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Text('Products', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              const Spacer(),
              ElevatedButton.icon(onPressed: () => _addEdit(), icon: const Icon(Icons.add), label: const Text('Add Product')),
            ]),
            const SizedBox(height: 16),
            Expanded(
              child: prov.loading
                  ? const Center(child: CircularProgressIndicator())
                  : prov.products.isEmpty
                      ? const Center(child: Text('No products. Add your first product.'))
                      : Card(
                          child: SingleChildScrollView(
                            child: DataTable(
                              columns: const [
                                DataColumn(label: Text('Name')),
                                DataColumn(label: Text('Unit')),
                                DataColumn(label: Text('Purchase')),
                                DataColumn(label: Text('Selling')),
                                DataColumn(label: Text('Stock')),
                                DataColumn(label: Text('Status')),
                                DataColumn(label: Text('')),
                              ],
                              rows: prov.products.map((p) {
                                String status = 'In Stock';
                                Color statusColor = Colors.green;
                                if (p.isOutOfStock) {
                                  status = 'Out';
                                  statusColor = Colors.red;
                                } else if (p.isLowStock) {
                                  status = 'Low';
                                  statusColor = Colors.orange;
                                }
                                return DataRow(cells: [
                                  DataCell(Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600))),
                                  DataCell(Text(p.unit)),
                                  DataCell(Text(CurrencyUtils.formatPlain(p.purchasePrice))),
                                  DataCell(Text(CurrencyUtils.formatPlain(p.sellingPrice))),
                                  DataCell(Text('${p.stockQuantity}')),
                                  DataCell(Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.w600))),
                                  DataCell(IconButton(icon: const Icon(Icons.edit, size: 18), onPressed: () => _addEdit(p))),
                                ]);
                              }).toList(),
                            ),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
