import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../services/stock_service.dart';
import '../../core/utils/app_snackbar.dart';
import '../../providers/auth_provider.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});
  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  String filter = 'All';

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
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: Text('Adjust Stock — $name'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('Current: $current'),
        TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'New Quantity'), keyboardType: TextInputType.number),
        TextField(controller: reasonCtrl, decoration: const InputDecoration(labelText: 'Reason')),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
      ],
    ));
    if (ok != true) return;
    final newQty = double.tryParse(ctrl.text);
    if (newQty == null) return;
    final delta = newQty - current;
    try {
      await StockService.instance.move(
        productId: productId,
        productName: name,
        type: 'adjustment',
        quantity: delta,
        notes: reasonCtrl.text,
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
    final filtered = products.where((p) {
      if (filter == 'Low Stock') return p.isLowStock;
      if (filter == 'Out of Stock') return p.isOutOfStock;
      return true;
    }).toList();

    return Scaffold(
      body: Padding(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Inventory', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        Wrap(spacing: 8, children: ['All', 'Low Stock', 'Out of Stock'].map((f) => ChoiceChip(
          label: Text(f), selected: filter == f, onSelected: (_) => setState(() => filter = f),
        )).toList()),
        const SizedBox(height: 16),
        Expanded(child: filtered.isEmpty ? const Center(child: Text('No items'))
          : Card(child: ListView.separated(
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final p = filtered[i];
                return ListTile(
                  title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('${p.unit} • Reorder: ${p.reorderLevel}'),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text('${p.stockQuantity}', style: TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 16,
                      color: p.isOutOfStock ? Colors.red : p.isLowStock ? Colors.orange : Colors.green,
                    )),
                    IconButton(icon: const Icon(Icons.tune, size: 18), onPressed: () => _adjust(p.id!, p.name, p.stockQuantity)),
                  ]),
                );
              },
            ))),
      ])),
    );
  }
}
