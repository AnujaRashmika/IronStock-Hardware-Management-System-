import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../core/utils/app_snackbar.dart';
import '../../core/utils/currency_utils.dart';
import '../../core/utils/activity_logger.dart';
import '../../core/database/database_helper.dart';
import '../../core/constants/db_constants.dart';
import '../../providers/product_provider.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/purchase_repository.dart';
import '../../models/product.dart';
import '../../models/supplier.dart';
import '../../widgets/app_header.dart';

class PurchasesScreen extends StatefulWidget {
  const PurchasesScreen({super.key});
  @override
  State<PurchasesScreen> createState() => _PurchasesScreenState();
}

class _PurchasesScreenState extends State<PurchasesScreen> {
  final _repo = PurchaseRepository();
  final _search = TextEditingController();
  List<Map<String, dynamic>> _list = [];
  List<Map<String, dynamic>> _filtered = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    _list = await _repo.getAll();
    _filtered = List.from(_list);
    setState(() => loading = false);
  }

  void _filter(String q) {
    if (q.trim().isEmpty) {
      _filtered = List.from(_list);
    } else {
      final lower = q.toLowerCase();
      _filtered = _list.where((p) =>
          (p['invoice_no']?.toString() ?? '').toLowerCase().contains(lower) ||
          (p['supplier_name']?.toString() ?? '').toLowerCase().contains(lower)).toList();
    }
    setState(() {});
  }

  Future<List<Supplier>> _loadSuppliers() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(DbConstants.suppliers, orderBy: 'name ASC');
    return rows.map(Supplier.fromMap).toList();
  }

  Future<void> _showDetails(Map<String, dynamic> p) async {
    final db = await DatabaseHelper.instance.database;
    final items = await db.query(DbConstants.purchaseItems, where: 'purchase_id = ?', whereArgs: [p['id']]);
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Dialog(
          backgroundColor: Colors.transparent,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480, maxHeight: 520),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p['invoice_no']?.toString() ?? 'Purchase', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text('Supplier: ${p['supplier_name'] ?? '-'}'),
                  Text('Date: ${(p['created_at'] ?? p['purchase_date'] ?? '').toString().length > 16 ? (p['created_at'] ?? p['purchase_date']).toString().substring(0, 16) : (p['created_at'] ?? p['purchase_date'] ?? '')}'),
                  Text('Total: ${CurrencyUtils.format((p['total'] as num?)?.toDouble() ?? 0)}', style: const TextStyle(fontWeight: FontWeight.w600)),
                  const Divider(height: 24),
                  const Text('Items', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Expanded(
                    child: items.isEmpty
                        ? const Text('No items')
                        : ListView.separated(
                            itemCount: items.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (_, i) {
                              final it = items[i];
                              return ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                title: Text(it['product_name']?.toString() ?? ''),
                                subtitle: Text('Qty: ${it['quantity']} × ${CurrencyUtils.format((it['unit_price'] as num?)?.toDouble() ?? 0)}'),
                                trailing: Text(CurrencyUtils.format((it['total'] as num?)?.toDouble() ?? 0), style: const TextStyle(fontWeight: FontWeight.w600)),
                              );
                            },
                          ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _newPurchase() async {
    final products = context.read<ProductProvider>().products;
    if (products.isEmpty) {
      showErrorSnackBar(context, 'Add products first');
      return;
    }
    final suppliers = await _loadSuppliers();
    if (suppliers.isEmpty) {
      showErrorSnackBar(context, 'Add a supplier first (Suppliers page)');
      return;
    }

    Supplier? selectedSupplier;
    Product? selectedProduct;
    final supplierSearch = TextEditingController();
    final productSearch = TextEditingController();
    final qtyCtrl = TextEditingController(text: '1');
    final priceCtrl = TextEditingController();
    final invCtrl = TextEditingController();
    List<Supplier> supplierHits = [];
    List<Product> productHits = [];
    bool showSupplierList = false;
    bool showProductList = false;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          final isDark = Theme.of(ctx).brightness == Brightness.dark;

          void trySave() {
            if (selectedSupplier == null) {
              showErrorSnackBar(context, 'Select a supplier');
              return;
            }
            if (selectedProduct == null) {
              showErrorSnackBar(context, 'Select a product');
              return;
            }
            final qty = double.tryParse(qtyCtrl.text) ?? 0;
            if (qty <= 0) {
              showErrorSnackBar(context, 'Enter quantity');
              return;
            }
            Navigator.pop(ctx, true);
          }

          return CallbackShortcuts(
            bindings: {
              const SingleActivator(LogicalKeyboardKey.enter): trySave,
              const SingleActivator(LogicalKeyboardKey.numpadEnter): trySave,
            },
            child: Focus(
              autofocus: true,
              child: Dialog(
                backgroundColor: Colors.transparent,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
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
                          const Text('New Purchase', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 16),
                          TextField(controller: invCtrl, decoration: const InputDecoration(labelText: 'Supplier Invoice No')),
                          const SizedBox(height: 12),
                          TextField(
                            controller: supplierSearch,
                            decoration: InputDecoration(
                              labelText: 'Supplier *',
                              hintText: 'Search supplier…',
                              prefixIcon: const Icon(Icons.local_shipping_outlined),
                              suffixIcon: selectedSupplier != null
                                  ? IconButton(
                                      icon: const Icon(Icons.close, size: 18),
                                      onPressed: () => setS(() {
                                        selectedSupplier = null;
                                        supplierSearch.clear();
                                        showSupplierList = false;
                                      }),
                                    )
                                  : null,
                            ),
                            onChanged: (q) {
                              final lower = q.toLowerCase();
                              setS(() {
                                selectedSupplier = null;
                                if (q.trim().isEmpty) {
                                  supplierHits = [];
                                  showSupplierList = false;
                                } else {
                                  supplierHits = suppliers
                                      .where((s) =>
                                          s.name.toLowerCase().contains(lower) ||
                                          (s.phone ?? '').contains(q) ||
                                          (s.company ?? '').toLowerCase().contains(lower))
                                      .take(8)
                                      .toList();
                                  showSupplierList = true;
                                }
                              });
                            },
                          ),
                          if (showSupplierList && supplierHits.isNotEmpty)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              constraints: const BoxConstraints(maxHeight: 140),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: supplierHits.length,
                                itemBuilder: (_, i) {
                                  final s = supplierHits[i];
                                  return ListTile(
                                    dense: true,
                                    title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                    subtitle: Text('${s.company ?? ''} • ${s.phone ?? ''}', style: const TextStyle(fontSize: 11)),
                                    onTap: () => setS(() {
                                      selectedSupplier = s;
                                      supplierSearch.text = s.name;
                                      showSupplierList = false;
                                    }),
                                  );
                                },
                              ),
                            ),
                          if (selectedSupplier != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text('Selected: ${selectedSupplier!.name}',
                                  style: const TextStyle(color: AppColors.green, fontWeight: FontWeight.w600, fontSize: 12)),
                            ),
                          const SizedBox(height: 12),
                          // Product search
                          TextField(
                            controller: productSearch,
                            decoration: InputDecoration(
                              labelText: 'Product *',
                              hintText: 'Search product…',
                              prefixIcon: const Icon(Icons.inventory_2_outlined),
                              suffixIcon: selectedProduct != null
                                  ? IconButton(
                                      icon: const Icon(Icons.close, size: 18),
                                      onPressed: () => setS(() {
                                        selectedProduct = null;
                                        productSearch.clear();
                                        priceCtrl.clear();
                                        showProductList = false;
                                      }),
                                    )
                                  : null,
                            ),
                            onChanged: (q) {
                              final lower = q.toLowerCase();
                              setS(() {
                                selectedProduct = null;
                                if (q.trim().isEmpty) {
                                  productHits = [];
                                  showProductList = false;
                                } else {
                                  productHits = products
                                      .where((p) =>
                                          p.name.toLowerCase().contains(lower) ||
                                          (p.sku ?? '').toLowerCase().contains(lower) ||
                                          (p.brand ?? '').toLowerCase().contains(lower))
                                      .take(10)
                                      .toList();
                                  showProductList = true;
                                }
                              });
                            },
                          ),
                          if (showProductList && productHits.isNotEmpty)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              constraints: const BoxConstraints(maxHeight: 140),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: productHits.length,
                                itemBuilder: (_, i) {
                                  final p = productHits[i];
                                  return ListTile(
                                    dense: true,
                                    title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                    subtitle: Text('${p.unit} • Cost: ${CurrencyUtils.format(p.purchasePrice)}', style: const TextStyle(fontSize: 11)),
                                    onTap: () => setS(() {
                                      selectedProduct = p;
                                      productSearch.text = p.name;
                                      priceCtrl.text = p.purchasePrice.toString();
                                      showProductList = false;
                                    }),
                                  );
                                },
                              ),
                            ),
                          if (selectedProduct != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text('Selected: ${selectedProduct!.name}',
                                  style: const TextStyle(color: AppColors.green, fontWeight: FontWeight.w600, fontSize: 12)),
                            ),
                          const SizedBox(height: 12),
                          Row(children: [
                            Expanded(
                              child: TextField(
                                controller: qtyCtrl,
                                decoration: const InputDecoration(labelText: 'Qty'),
                                keyboardType: TextInputType.number,
                                onSubmitted: (_) => trySave(),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: priceCtrl,
                                decoration: const InputDecoration(labelText: 'Unit Cost'),
                                keyboardType: TextInputType.number,
                                onSubmitted: (_) => trySave(),
                              ),
                            ),
                          ]),
                          const SizedBox(height: 20),
                          Row(children: [
                            Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel'))),
                            const SizedBox(width: 12),
                            Expanded(child: ElevatedButton(onPressed: trySave, child: const Text('Save'))),
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

    if (ok != true || selectedProduct == null || selectedSupplier == null) return;
    final qty = double.tryParse(qtyCtrl.text) ?? 0;
    final price = double.tryParse(priceCtrl.text) ?? 0;
    if (qty <= 0) return;

    try {
      await _repo.createPurchase(
        invoiceNo: invCtrl.text.isEmpty ? 'PO-${DateTime.now().millisecondsSinceEpoch}' : invCtrl.text,
        supplierId: selectedSupplier!.id,
        supplierName: selectedSupplier!.name,
        items: [
          {
            'productId': selectedProduct!.id,
            'productName': selectedProduct!.name,
            'unit': selectedProduct!.unit,
            'quantity': qty,
            'unitPrice': price,
          }
        ],
        paidAmount: qty * price,
        createdBy: context.read<AuthProvider>().currentUser?.id,
      );
      await ActivityLogger.log(
        action: 'create',
        entityType: 'purchase',
        details: 'Purchase from ${selectedSupplier!.name} — ${selectedProduct!.name} × $qty',
        username: context.read<AuthProvider>().currentUser?.username,
      );
      await context.read<ProductProvider>().load();
      await _load();
      if (mounted) showSuccessSnackBar(context, 'Purchase saved. Stock increased.');
    } catch (e) {
      if (mounted) showErrorSnackBar(context, '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.enter): _newPurchase,
        const SingleActivator(LogicalKeyboardKey.numpadEnter): _newPurchase,
      },
      child: Focus(
        autofocus: true,
        child: Column(
          children: [
            const AppHeader(
              title: 'Purchases',
              subtitle: 'Record purchases from registered suppliers',
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
                                hintText: 'Search purchases...',
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
                            onPressed: _newPurchase,
                            icon: const Icon(Icons.add),
                            label: const Text('New Purchase'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: loading
                          ? const Center(child: CircularProgressIndicator())
                          : _filtered.isEmpty
                              ? Center(child: Text('No purchases yet.', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)))
                              : Card(
                                  clipBehavior: Clip.antiAlias,
                                  child: ListView.separated(
                                    itemCount: _filtered.length,
                                    separatorBuilder: (_, __) => const Divider(height: 1),
                                    itemBuilder: (_, i) {
                                      final p = _filtered[i];
                                      return InkWell(
                                        onDoubleTap: () => _showDetails(p),
                                        child: ListTile(
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                          leading: CircleAvatar(
                                            backgroundColor: AppColors.blueSoft,
                                            child: Icon(Icons.shopping_cart_outlined, color: AppColors.blue, size: 20),
                                          ),
                                          title: Text(p['invoice_no'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                                          subtitle: Text(p['supplier_name'] ?? '-', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                          trailing: Text(CurrencyUtils.format((p['total'] as num?)?.toDouble() ?? 0), style: const TextStyle(fontWeight: FontWeight.w600)),
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
