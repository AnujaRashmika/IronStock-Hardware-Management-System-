import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../core/utils/app_snackbar.dart';
import '../../core/utils/currency_utils.dart';
import '../../core/constants/app_constants.dart';
import '../../models/product.dart';
import '../../models/customer.dart';
import '../../providers/cart_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/customer_provider.dart';
import '../../repositories/sale_repository.dart';
import '../../widgets/app_header.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});
  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  final _searchCtrl = TextEditingController();
  final _customerSearchCtrl = TextEditingController();
  final _saleRepo = SaleRepository();
  List<Product> _filtered = [];
  List<Customer> _customerResults = [];
  bool _checkingOut = false;
  bool _showCustomerResults = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<ProductProvider>().load();
      await context.read<CustomerProvider>().loadCustomers();
      _onSearch('');
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _customerSearchCtrl.dispose();
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

  void _onCustomerSearch(String q) {
    final cart = context.read<CartProvider>();
    if (q.trim().isEmpty) {
      setState(() {
        _customerResults = [];
        _showCustomerResults = false;
      });
      return;
    }
    final all = context.read<CustomerProvider>().customers;
    final lower = q.toLowerCase();
    setState(() {
      _customerResults = all
          .where((c) =>
              c.name.toLowerCase().contains(lower) ||
              (c.phone ?? '').contains(q))
          .take(8)
          .toList();
      _showCustomerResults = true;
    });
    // clear selection when typing again
    if (cart.customerId != null) {
      cart.clearCustomer();
    }
  }

  void _selectCustomer(Customer c) {
    context.read<CartProvider>().setCustomer(id: c.id, name: c.name);
    _customerSearchCtrl.text = c.name;
    setState(() {
      _showCustomerResults = false;
      _customerResults = [];
    });
  }

  void _clearCustomer() {
    context.read<CartProvider>().clearCustomer();
    _customerSearchCtrl.clear();
    setState(() {
      _showCustomerResults = false;
      _customerResults = [];
    });
  }

  IconData _productIcon(Product p) {
    final u = p.unit.toLowerCase();
    final n = p.name.toLowerCase();
    if (u.contains('bag') || n.contains('cement')) return Icons.inventory_2_rounded;
    if (u.contains('liter') || n.contains('paint')) return Icons.format_paint_rounded;
    if (u.contains('meter') || u.contains('feet') || n.contains('pipe') || n.contains('wire')) {
      return Icons.straighten_rounded;
    }
    if (u.contains('kg') || n.contains('sand') || n.contains('metal')) return Icons.scale_rounded;
    if (n.contains('tool') || n.contains('drill') || n.contains('hammer')) return Icons.build_rounded;
    if (n.contains('electric') || n.contains('switch') || n.contains('bulb')) {
      return Icons.electrical_services_rounded;
    }
    if (n.contains('plumb') || n.contains('tap') || n.contains('valve')) return Icons.plumbing_rounded;
    if (n.contains('nail') || n.contains('screw')) return Icons.push_pin_rounded;
    if (n.contains('brick') || n.contains('block')) return Icons.grid_view_rounded;
    if (n.contains('roof') || n.contains('sheet')) return Icons.roofing_rounded;
    return Icons.hardware_rounded;
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Checkout', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    if (cart.customerName != null && cart.customerName!.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: AppColors.greenSoft,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text('Customer: ${cart.customerName}',
                            style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.green)),
                      )
                    else
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text('Walk-in customer (no bill name)',
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
                      ),
                    Text('Total: ${CurrencyUtils.format(cart.total)}',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppTheme.primaryColor)),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: method,
                      decoration: const InputDecoration(labelText: 'Payment Method'),
                      items: AppConstants.paymentMethods
                          .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                          .toList(),
                      onChanged: (v) => setS(() => method = v ?? 'Cash'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: paidCtrl,
                      decoration: const InputDecoration(labelText: 'Paid Amount'),
                      keyboardType: TextInputType.number,
                    ),
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
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Complete Sale'),
                        ),
                      ),
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
        customerName: cart.customerName ?? 'Walk-in',
        discount: cart.discount,
        tax: cart.tax,
        deliveryCharge: cart.deliveryCharge,
        paidAmount: paid,
        payments: [
          {'amount': paid, 'method': method, 'reference': null},
        ],
        isCredit: paid < cart.total,
        createdBy: auth.currentUser?.id,
        createDelivery: needDelivery,
        deliveryInfo: needDelivery
            ? {
                'address': addrCtrl.text,
                'phone': phoneCtrl.text,
                'customer_name': cart.customerName ?? 'Walk-in',
              }
            : null,
      );
      cart.clear();
      _customerSearchCtrl.clear();
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
    final bg = isDark ? const Color(0xFF0F1613) : const Color(0xFFF3F7F5);
    final cardBg = isDark ? const Color(0xFF1A2420) : Colors.white;
    final border = isDark ? const Color(0xFF2A3530) : const Color(0xFFE6EAE8);

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.f2): _checkout,
      },
      child: Focus(
        autofocus: true,
        child: Column(
          children: [
            const AppHeader(
              title: 'Point of Sale',
              subtitle: 'Select products — optional customer for named bill',
            ),
            Expanded(
              child: Container(
                color: bg,
                child: Row(
                  children: [
                    // LEFT — products
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(28, 20, 16, 24),
                        child: Column(
                          children: [
                            // Search
                            Container(
                              height: 48,
                              decoration: BoxDecoration(
                                color: cardBg,
                                borderRadius: BorderRadius.circular(28),
                                border: Border.all(color: border),
                              ),
                              child: TextField(
                                controller: _searchCtrl,
                                decoration: InputDecoration(
                                  hintText: 'Search products...',
                                  prefixIcon: const Icon(Icons.search, size: 20),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                                  suffixIcon: _searchCtrl.text.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.clear, size: 18),
                                          onPressed: () {
                                            _searchCtrl.clear();
                                            _onSearch('');
                                          },
                                        )
                                      : null,
                                ),
                                onChanged: _onSearch,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Expanded(
                              child: _filtered.isEmpty
                                  ? Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey.shade400),
                                          const SizedBox(height: 12),
                                          Text('No products found', style: TextStyle(color: Colors.grey.shade600)),
                                        ],
                                      ),
                                    )
                                  : GridView.builder(
                                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 4,
                                        childAspectRatio: 0.95,
                                        crossAxisSpacing: 14,
                                        mainAxisSpacing: 14,
                                      ),
                                      itemCount: _filtered.length,
                                      itemBuilder: (_, i) {
                                        final p = _filtered[i];
                                        final out = p.stockQuantity <= 0;
                                        return Material(
                                          color: cardBg,
                                          borderRadius: BorderRadius.circular(18),
                                          elevation: 0,
                                          child: InkWell(
                                            borderRadius: BorderRadius.circular(18),
                                            onTap: out
                                                ? null
                                                : () => context.read<CartProvider>().addProduct(p),
                                            child: Container(
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(18),
                                                border: Border.all(color: border),
                                              ),
                                              padding: const EdgeInsets.all(16),
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Container(
                                                    width: 56,
                                                    height: 56,
                                                    decoration: BoxDecoration(
                                                      color: AppColors.greenSoft,
                                                      borderRadius: BorderRadius.circular(16),
                                                    ),
                                                    child: Icon(
                                                      _productIcon(p),
                                                      color: AppTheme.primaryColor,
                                                      size: 28,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 12),
                                                  Text(
                                                    p.name,
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                    textAlign: TextAlign.center,
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.w600,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Text(
                                                    CurrencyUtils.format(p.sellingPrice),
                                                    style: const TextStyle(
                                                      color: AppTheme.primaryColor,
                                                      fontWeight: FontWeight.w700,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    out
                                                        ? 'Out of stock'
                                                        : 'Stock: ${p.stockQuantity.toStringAsFixed(p.stockQuantity == p.stockQuantity.roundToDouble() ? 0 : 1)}',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: out ? Colors.red : Colors.grey.shade600,
                                                    ),
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

                    // RIGHT — current order / cart
                    Container(
                      width: 360,
                      color: cardBg,
                      child: Column(
                        children: [
                          // Header
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 20, 16, 8),
                            child: Row(
                              children: [
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Current Order', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: AppColors.greenSoft,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(Icons.shopping_cart_outlined, color: AppTheme.primaryColor, size: 22),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                cart.items.isEmpty
                                    ? 'No items added'
                                    : '${cart.itemCount} item${cart.itemCount == 1 ? '' : 's'}',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Cart items
                          Expanded(
                            child: cart.items.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 72,
                                          height: 72,
                                          decoration: BoxDecoration(
                                            color: AppColors.greenSoft,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.shopping_cart_outlined, size: 32, color: AppTheme.primaryColor),
                                        ),
                                        const SizedBox(height: 14),
                                        const Text('Your cart is empty', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                                        const SizedBox(height: 4),
                                        Text('Select a product to add it', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                      ],
                                    ),
                                  )
                                : ListView.builder(
                                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                                    itemCount: cart.items.length,
                                    itemBuilder: (_, i) {
                                      final item = cart.items[i];
                                      return Container(
                                        margin: const EdgeInsets.only(bottom: 8),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: bg,
                                          borderRadius: BorderRadius.circular(14),
                                          border: Border.all(color: border),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 40,
                                              height: 40,
                                              decoration: BoxDecoration(
                                                color: AppColors.greenSoft,
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: const Icon(Icons.hardware_rounded, color: AppTheme.primaryColor, size: 20),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    item.productName,
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                                  ),
                                                  Text(
                                                    '${CurrencyUtils.format(item.unitPrice)} × ${item.quantity}',
                                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                _qtyBtn(Icons.remove, () {
                                                  cart.updateQty(item.productId, item.quantity - 1);
                                                }),
                                                Padding(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                                  child: Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.w700)),
                                                ),
                                                _qtyBtn(Icons.add, () {
                                                  cart.updateQty(item.productId, item.quantity + 1);
                                                }),
                                              ],
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                          ),

                          // Customer search + totals + actions
                          Container(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                            decoration: BoxDecoration(
                              border: Border(top: BorderSide(color: border)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Customer search
                                Stack(
                                  children: [
                                    Container(
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: bg,
                                        borderRadius: BorderRadius.circular(22),
                                        border: Border.all(color: border),
                                      ),
                                      child: TextField(
                                        controller: _customerSearchCtrl,
                                        decoration: InputDecoration(
                                          hintText: 'Search customer (optional)',
                                          prefixIcon: const Icon(Icons.person_outline, size: 20),
                                          border: InputBorder.none,
                                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                                          suffixIcon: cart.customerId != null
                                              ? IconButton(
                                                  icon: const Icon(Icons.close, size: 18),
                                                  onPressed: _clearCustomer,
                                                  tooltip: 'Clear customer',
                                                )
                                              : null,
                                        ),
                                        onChanged: _onCustomerSearch,
                                        onTap: () {
                                          if (_customerSearchCtrl.text.isNotEmpty) {
                                            _onCustomerSearch(_customerSearchCtrl.text);
                                          }
                                        },
                                      ),
                                    ),
                                    if (_showCustomerResults && _customerResults.isNotEmpty)
                                      Positioned(
                                        left: 0,
                                        right: 0,
                                        bottom: 48,
                                        child: Material(
                                          elevation: 6,
                                          borderRadius: BorderRadius.circular(12),
                                          color: cardBg,
                                          child: ConstrainedBox(
                                            constraints: const BoxConstraints(maxHeight: 180),
                                            child: ListView.builder(
                                              shrinkWrap: true,
                                              itemCount: _customerResults.length,
                                              itemBuilder: (_, i) {
                                                final c = _customerResults[i];
                                                return ListTile(
                                                  dense: true,
                                                  leading: CircleAvatar(
                                                    radius: 14,
                                                    backgroundColor: AppColors.greenSoft,
                                                    child: Text(
                                                      c.name.isNotEmpty ? c.name[0].toUpperCase() : 'C',
                                                      style: const TextStyle(fontSize: 12, color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
                                                    ),
                                                  ),
                                                  title: Text(c.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                                  subtitle: Text(c.phone ?? '', style: const TextStyle(fontSize: 11)),
                                                  onTap: () => _selectCustomer(c),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                if (cart.customerName != null && cart.customerName!.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: AppColors.greenSoft,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.check_circle, size: 16, color: AppColors.green),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Bill for: ${cart.customerName}',
                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.green),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 12),
                                _totalRow('Subtotal', CurrencyUtils.format(cart.subtotal)),
                                _totalRow('Discount', CurrencyUtils.format(cart.discount)),
                                const SizedBox(height: 4),
                                _totalRow('Total', CurrencyUtils.format(cart.total), bold: true),
                                const SizedBox(height: 14),
                                OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size.fromHeight(44),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  onPressed: cart.items.isEmpty
                                      ? null
                                      : () {
                                          cart.clear();
                                          _clearCustomer();
                                        },
                                  child: const Text('Clear Cart'),
                                ),
                                const SizedBox(height: 10),
                                SizedBox(
                                  height: 48,
                                  child: ElevatedButton(
                                    style: appButtonStyle(color: AppTheme.primaryColor),
                                    onPressed: _checkingOut || cart.items.isEmpty ? null : _checkout,
                                    child: _checkingOut
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                          )
                                        : const Text('Checkout', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
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
        child: SizedBox(
          width: 28,
          height: 28,
          child: Icon(icon, size: 16, color: AppTheme.primaryColor),
        ),
      ),
    );
  }

  Widget _totalRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: bold ? 15 : 13, fontWeight: bold ? FontWeight.w700 : FontWeight.w500)),
          Text(value, style: TextStyle(fontSize: bold ? 16 : 13, fontWeight: bold ? FontWeight.w700 : FontWeight.w600)),
        ],
      ),
    );
  }
}
