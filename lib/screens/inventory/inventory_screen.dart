import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../providers/product_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/stock_service.dart';
import '../../core/utils/app_snackbar.dart';
import '../../widgets/app_header.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});
  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  String filter = 'All';
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ProductProvider>().load();
      final pending = context.read<InventoryProvider>().pendingFilter;
      if (pending != null) {
        setState(() => filter = pending);
        context.read<InventoryProvider>().pendingFilter = null;
      }
    });
  }

  Future<void> _adjust(int productId, String name, double current) async {
    final ctrl = TextEditingController(text: current.toString());
    final reasonCtrl = TextEditingController();
    final ok = await showDialog<bool>(context: context, builder: (ctx) {
      final isDark = Theme.of(ctx).brightness == Brightness.dark;
      return Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: isDark ? const Color(0xFF1A1A1A) : Colors.white, borderRadius: BorderRadius.circular(20)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('Adjust Stock — $name', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('Current: $current'),
            const SizedBox(height: 12),
            TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'New Quantity'), keyboardType: TextInputType.number),
            const SizedBox(height: 10),
            TextField(controller: reasonCtrl, decoration: const InputDecoration(labelText: 'Reason')),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel'))),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save'))),
            ]),
          ]),
        ),
      );
    });
    if (ok != true) return;
    final newQty = double.tryParse(ctrl.text);
    if (newQty == null) return;
    try {
      await StockService.instance.move(
        productId: productId, productName: name, type: 'adjustment',
        quantity: newQty - current, notes: reasonCtrl.text,
        createdBy: context.read<AuthProvider>().currentUser?.id,
      );
      await context.read<ProductProvider>().load();
      if (mounted) showSuccessSnackBar(context, 'Stock adjusted');
    } catch (e) {
      if (mounted) showErrorSnackBar(context, '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final products = context.watch<ProductProvider>().products;
    var filtered = products.where((p) {
      if (filter == 'Low Stock') return p.isLowStock;
      if (filter == 'Out of Stock') return p.isOutOfStock;
      return true;
    }).toList();
    final q = _search.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      filtered = filtered.where((p) => p.name.toLowerCase().contains(q)).toList();
    }

    return Column(children: [
      const AppHeader(title: 'Inventory', subtitle: 'Stock levels and adjustments'),
      Expanded(child: Padding(padding: const EdgeInsets.all(28), child: Column(children: [
        Row(children: [
          Expanded(child: SizedBox(height: 48, child: TextField(
            controller: _search,
            decoration: InputDecoration(hintText: 'Search products...', prefixIcon: const Icon(Icons.search), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            onChanged: (_) => setState(() {}),
          ))),
          const SizedBox(width: 12),
          ...['All', 'Low Stock', 'Out of Stock'].map((f) => Padding(
            padding: const EdgeInsets.only(left: 6),
            child: FilterChip(label: Text(f), selected: filter == f, onSelected: (_) => setState(() => filter = f)),
          )),
        ]),
        const SizedBox(height: 24),
        Expanded(child: filtered.isEmpty
          ? Center(child: Text('No items.', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)))
          : Card(clipBehavior: Clip.antiAlias, child: ListView.separated(
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final p = filtered[i];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: p.isOutOfStock ? AppColors.redSoft : p.isLowStock ? AppColors.orangeSoft : AppColors.greenSoft,
                    child: Icon(Icons.inventory_2_outlined, size: 20, color: p.isOutOfStock ? AppColors.red : p.isLowStock ? AppColors.orange : AppColors.green),
                  ),
                  title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('${p.unit} • Reorder: ${p.reorderLevel}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text('${p.stockQuantity}', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16,
                      color: p.isOutOfStock ? Colors.red : p.isLowStock ? Colors.orange : Colors.green)),
                    IconButton(icon: const Icon(Icons.tune, size: 18), onPressed: () => _adjust(p.id!, p.name, p.stockQuantity)),
                  ]),
                );
              },
            ))),
      ]))),
    ]);
  }
}
