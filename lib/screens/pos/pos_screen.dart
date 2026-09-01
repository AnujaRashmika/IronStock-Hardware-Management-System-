import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../core/utils/app_snackbar.dart';
import '../../core/utils/currency_utils.dart';
import '../../core/constants/app_constants.dart';
import '../../models/product.dart';
import '../../providers/cart_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/sale_repository.dart';
import '../../widgets/app_header.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});
  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  final _searchCtrl = TextEditingController();
  final _saleRepo = SaleRepository();
  List<Product> _filtered = [];
  bool _checkingOut = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prods = context.read<ProductProvider>().products.where((p) => p.isActive).toList();
      setState(() => _filtered = prods);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch(String q) {
    final all = context.read<ProductProvider>().products.where((p) => p.isActive).toList();
    setState(() {
      _filtered = q.isEmpty
          ? all
          : all.where((p) =>
              p.name.toLowerCase().contains(q.toLowerCase()) ||
              (p.sku ?? '').toLowerCase().contains(q.toLowerCase()) ||
              (p.barcode ?? '').contains(q) ||
              (p.brand ?? '').toLowerCase().contains(q.toLowerCase())).toList();
    });
  }

  IconData _productIcon(Product p) {
    final u = p.unit.toLowerCase();
    final n = p.name.toLowerCase();
    if (u.contains('bag') || n.contains('cement')) return Icons.inventory_2_outlined;
    if (u.contains('liter') || n.contains('paint')) return Icons.format_paint_outlined;
    if (u.contains('meter') || u.contains('feet') || n.contains('pipe') || n.contains('wire')) {
      return Icons.linear_scale;
    }
    if (u.contains('kg') || n.contains('sand') || n.contains('metal')) return Icons.scale_outlined;
    if (n.contains('tool') || n.contains('drill')) return Icons.build_outlined;
    if (n.contains('electric') || n.contains('switch') || n.contains('bulb')) return Icons.electrical_services_outlined;
    if (n.contains('plumb') || n.contains('tap') || n.contains('valve')) return Icons.plumbing;
    if (n.contains('nail') || n.contains('screw')) return Icons.push_pin_outlined;
    if (n.contains('brick') || n.contains('block')) return Icons.grid_view_rounded;
    return Icons.hardware_outlined;
  }

  Color _productColor(Product p) {
    final colors = [
      AppColors.green, AppColors.blue, AppColors.teal, AppColors.orange,
      AppColors.purple, AppColors.indigo, AppColors.pink,
    ];
    return colors[(p.id ?? p.name.hashCode).abs() % colors.length];
  }

  Future<void> _checkout() async {
    final cart = context.read<CartProvider>();
    if (cart.items.isEmpty) {
      showErrorSnackBar(context, 'Cart is empty');
      return;
    }

    final paidCtrl = TextEditingController(text: cart.total.toStringAsFixed(2));
    String method = 'Cash';
    bool needDelivery = false;
    final addrCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          final isDark = Theme.of(ctx).brightness == Brightness.dark;
          return Dialog(
            backgroundColor: Colors.transparent,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Checkout', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    Text('Total: ${CurrencyUtils.format(cart.total)}',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppTheme.primaryColor)),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: method,
                      decoration: const InputDecoration(labelText: 'Payment Method'),
                      items: AppConstants.paymentMethods.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                      onChanged: (v) => setS(() => method = v ?? 'Cash'),
                    ),
                    const SizedBox(height: 12),
                    TextField(controller: paidCtrl, decoration: const InputDecoration(labelText: 'Paid Amount'), keyboardType: TextInputType.number),
                    CheckboxListTile(
                      value: needDelivery,
                      onChanged: (v) => setS(() => needDelivery = v ?? false),
                      title: const Text('Create Delivery'),
                      contentPadding: EdgeInsets.zero,
                    ),
                    if (needDelivery) ...[
                      TextField(controller: addrCtrl, decoration: const InputDecoration(labelText: 'Delivery Address')),
                      const SizedBox(height: 8),
                      TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone')),
                    ],
                    const SizedBox(height: 16),
                    Row(children: [
                      Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel'))),
                      const SizedBox(width: 12),
                      Expanded(child: ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Complete Sale'))),
                    ]),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );

    if (ok != true || !mounted) return;
    setState(() => _checkingOut = true);
    try {
      final paid = double.tryParse(paidCtrl.text) ?? cart.total;
      final auth = context.read<AuthProvider>();
      await _saleRepo.createSale(
        items: cart.items,
        customerId: cart.customerId,
        customerName: cart.customerName,
        discount: cart.discount,
        tax: cart.tax,
        deliveryCharge: cart.deliveryCharge,
        paidAmount: paid,
        payments: [{'amount': paid, 'method': method, 'reference': null}],
        isCredit: paid < cart.total,
        createdBy: auth.currentUser?.id,
        createDelivery: needDelivery,
        deliveryInfo: needDelivery
            ? {'address': addrCtrl.text, 'phone': phoneCtrl.text, 'customer_name': cart.customerName}
            : null,
      );
      cart.clear();
      await context.read<ProductProvider>().load();
      _onSearch(_searchCtrl.text);
      if (mounted) showSuccessSnackBar(context, 'Sale completed successfully');
    } catch (e) {
      if (mounted) showErrorSnackBar(context, 'Sale failed: $e');
    }
    setState(() => _checkingOut = false);
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.f2): _checkout,
      },
      child: Focus(
        autofocus: true,
        child: Column(
          children: [
            const AppHeader(
              title: 'New Sale',
              subtitle: 'Search products and add to cart — F2 to checkout',
            ),
            Expanded(
              child: Row(
                children: [
                  // Products grid
                  Expanded(
                    flex: 3,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 12, 20),
                      child: Column(
                        children: [
                          SizedBox(
                            height: 48,
                            child: TextField(
                              controller: _searchCtrl,
                              decoration: InputDecoration(
                                hintText: 'Search product name, SKU, barcode...',
                                prefixIcon: const Icon(Icons.search),
                                suffixIcon: _searchCtrl.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear),
                                        onPressed: () {
                                          _searchCtrl.clear();
                                          _onSearch('');
                                        },
                                      )
                                    : null,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onChanged: _onSearch,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: _filtered.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey.shade400),
                                        const SizedBox(height: 12),
                                        Text('No products found', style: TextStyle(color: Colors.grey.shade600, fontSize: 15)),
                                      ],
                                    ),
                                  )
                                : GridView.builder(
                                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 3,
                                      childAspectRatio: 1.15,
                                      crossAxisSpacing: 12,
                                      mainAxisSpacing: 12,
                                    ),
                                    itemCount: _filtered.length,
                                    itemBuilder: (_, i) {
                                      final p = _filtered[i];
                                      final color = _productColor(p);
                                      final out = p.stockQuantity <= 0;
                                      return Material(
                                        color: isDark ? const Color(0xFF1A2420) : Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(16),
                                          onTap: out ? null : () => context.read<CartProvider>().addProduct(p),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(16),
                                              border: Border.all(
                                                color: isDark ? const Color(0xFF2A3530) : const Color(0xFFE6EAE8),
                                              ),
                                            ),
                                            padding: const EdgeInsets.all(14),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Container(
                                                      width: 40,
                                                      height: 40,
                                                      decoration: BoxDecoration(
                                                        color: AppColors.softOf(color),
                                                        borderRadius: BorderRadius.circular(12),
                                                      ),
                                                      child: Icon(_productIcon(p), color: color, size: 22),
                                                    ),
                                                    const Spacer(),
                                                    if (out)
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                        decoration: BoxDecoration(
                                                          color: AppColors.redSoft,
                                                          borderRadius: BorderRadius.circular(20),
                                                        ),
                                                        child: const Text('Out', style: TextStyle(fontSize: 10, color: AppColors.red, fontWeight: FontWeight.w600)),
                                                      )
                                                    else if (p.isLowStock)
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                        decoration: BoxDecoration(
                                                          color: AppColors.orangeSoft,
                                                          borderRadius: BorderRadius.circular(20),
                                                        ),
                                                        child: const Text('Low', style: TextStyle(fontSize: 10, color: AppColors.orange, fontWeight: FontWeight.w600)),
                                                      ),
                                                  ],
                                                ),
                                                const Spacer(),
                                                Text(
                                                  p.name,
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  CurrencyUtils.format(p.sellingPrice),
                                                  style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 14),
                                                ),
                                                Text(
                                                  '${p.stockQuantity} ${p.unit}',
                                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                                ),
                                              ],
                                            ),
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
                  // Cart panel
                  Container(
                    width: 360,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF141D19) : const Color(0xFFF8FAF9),
                      border: Border(left: BorderSide(color: isDark ? const Color(0xFF2A3530) : const Color(0xFFE6EAE8))),
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.greenSoft,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.shopping_cart_outlined, color: AppColors.green, size: 20),
                              ),
                              const SizedBox(width: 10),
                              const Text('Cart', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                              const Spacer(),
                              if (cart.items.isNotEmpty)
                                TextButton(
                                  onPressed: () => cart.clear(),
                                  child: const Text('Clear'),
                                ),
                            ],
                          ),
                        ),
                        if (cart.items.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                '${cart.itemCount} item${cart.itemCount == 1 ? '' : 's'}',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              ),
                            ),
                          ),
                        Expanded(
                          child: cart.items.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.shopping_bag_outlined, size: 48, color: Colors.grey.shade400),
                                      const SizedBox(height: 10),
                                      Text('Cart is empty', style: TextStyle(color: Colors.grey.shade600)),
                                      const SizedBox(height: 4),
                                      Text('Tap a product to add', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                                  itemCount: cart.items.length,
                                  itemBuilder: (_, i) {
                                    final item = cart.items[i];
                                    final color = [
                                      AppColors.green, AppColors.blue, AppColors.teal,
                                      AppColors.orange, AppColors.purple,
                                    ][item.productId % 5];
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: isDark ? const Color(0xFF1A2420) : Colors.white,
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(color: isDark ? const Color(0xFF2A3530) : const Color(0xFFE6EAE8)),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              color: AppColors.softOf(color),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Icon(Icons.hardware_outlined, color: color, size: 20),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(item.productName, maxLines: 1, overflow: TextOverflow.ellipsis,
                                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                                Text(
                                                  '${CurrencyUtils.formatPlain(item.unitPrice)} / ${item.unit}',
                                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                                ),
                                                Text(
                                                  CurrencyUtils.format(item.lineTotal),
                                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              _qtyBtn(Icons.remove, () => cart.updateQty(item.productId, item.quantity - 1)),
                                              Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                                child: Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.w700)),
                                              ),
                                              _qtyBtn(Icons.add, () => cart.updateQty(item.productId, item.quantity + 1)),
                                              IconButton(
                                                icon: Icon(Icons.close, size: 16, color: Colors.grey.shade500),
                                                onPressed: () => cart.remove(item.productId),
                                                visualDensity: VisualDensity.compact,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1A2420) : Colors.white,
                            border: Border(top: BorderSide(color: isDark ? const Color(0xFF2A3530) : const Color(0xFFE6EAE8))),
                          ),
                          child: Column(
                            children: [
                              _row('Subtotal', CurrencyUtils.format(cart.subtotal)),
                              const SizedBox(height: 4),
                              _row('Total', CurrencyUtils.format(cart.total), bold: true),
                              const SizedBox(height: 14),
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: ElevatedButton.icon(
                                  style: appButtonStyle(color: AppColors.green),
                                  onPressed: _checkingOut || cart.items.isEmpty ? null : _checkout,
                                  icon: _checkingOut
                                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                      : const Icon(Icons.check_circle_outline),
                                  label: Text(_checkingOut ? 'Processing...' : 'Checkout'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap) {
    return Material(
      color: AppColors.greenSoft,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: SizedBox(width: 28, height: 28, child: Icon(icon, size: 16, color: AppColors.green)),
      ),
    );
  }

  Widget _row(String l, String v, {bool bold = false}) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(l, style: TextStyle(fontWeight: bold ? FontWeight.w700 : FontWeight.w500, fontSize: bold ? 15 : 13)),
          Text(v, style: TextStyle(fontWeight: bold ? FontWeight.w700 : FontWeight.w600, fontSize: bold ? 18 : 14)),
        ],
      );
}
