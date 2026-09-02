import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app/app.dart';
import '../app/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import 'confirmation_dialog.dart';

class AppSidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  const AppSidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final settings = context.watch<SettingsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 240,
      decoration: BoxDecoration(
        gradient: isDark ? AppTheme.sidebarGradientDark : AppTheme.sidebarGradientLight,
        border: Border(
          right: BorderSide(color: isDark ? const Color(0xFF2A3530) : const Color(0xFFE6EAE8)),
        ),
      ),
      child: Column(
        children: [
          // Logo
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
            child: Row(
              children: [
                SizedBox(
                  width: 40,
                  height: 40,
                  child: settings.logoPath.isNotEmpty && File(settings.logoPath).existsSync()
                      ? Image.file(File(settings.logoPath), fit: BoxFit.contain)
                      : const Icon(Icons.hardware, size: 28, color: AppTheme.primaryColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    settings.shopName.isEmpty ? 'Hardware Store' : settings.shopName,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              children: [
                _section('MAIN'),
                _item(context, Icons.dashboard_outlined, 'Dashboard', AppPages.dashboard),
                _item(context, Icons.point_of_sale_outlined, 'New Sale', AppPages.pos),
                _item(context, Icons.receipt_long_outlined, 'Sales History', AppPages.salesHistory),
                const SizedBox(height: 10),
                _section('CATALOG'),
                _item(context, Icons.inventory_2_outlined, 'Products', AppPages.products),
                _item(context, Icons.category_outlined, 'Categories', AppPages.categories),
                _item(context, Icons.warehouse_outlined, 'Inventory', AppPages.inventory),
                const SizedBox(height: 10),
                _section('SUPPLY'),
                _item(context, Icons.shopping_cart_outlined, 'Purchases', AppPages.purchases),
                _item(context, Icons.local_shipping_outlined, 'Suppliers', AppPages.suppliers),
                const SizedBox(height: 10),
                _section('CUSTOMERS'),
                _item(context, Icons.people_outline, 'Customers', AppPages.customers),
                _item(context, Icons.assignment_return_outlined, 'Returns', AppPages.returns),
                _item(context, Icons.verified_outlined, 'Warranty', AppPages.warranty),
                _item(context, Icons.delivery_dining_outlined, 'Delivery', AppPages.delivery),
                const SizedBox(height: 10),
                _section('FINANCE'),
                _item(context, Icons.payments_outlined, 'Expenses', AppPages.expenses),
                _item(context, Icons.bar_chart_outlined, 'Reports', AppPages.reports),
                const SizedBox(height: 10),
                _section('SYSTEM'),
                _item(context, Icons.settings_outlined, 'Settings', AppPages.settings),
              ],
            ),
          ),
          const Divider(height: 1),
          // User + logout
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.greenSoft,
                  child: Text(
                    (auth.currentUser?.fullName.isNotEmpty == true
                            ? auth.currentUser!.fullName[0]
                            : 'A')
                        .toUpperCase(),
                    style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        auth.currentUser?.fullName ?? 'User',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        auth.currentUser?.role ?? '',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Logout',
                  icon: const Icon(Icons.logout, size: 18),
                  onPressed: () async {
                    final ok = await showConfirmationDialog(
                      context,
                      title: 'Logout',
                      message: 'Are you sure you want to logout?',
                      confirmText: 'Logout',
                      isDestructive: true,
                      icon: Icons.logout,
                    );
                    if (ok) auth.logout();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 6),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: Colors.grey.shade500,
        ),
      ),
    );
  }

  Widget _item(BuildContext context, IconData icon, String title, int index) {
    final selected = selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: selected ? AppTheme.primaryColor.withOpacity(0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => onItemSelected(index),
          child: SizedBox(
            height: 42,
            child: Row(
              children: [
                const SizedBox(width: 12),
                Icon(icon, size: 20, color: selected ? AppTheme.primaryColor : Colors.grey.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      color: selected ? AppTheme.primaryColor : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
