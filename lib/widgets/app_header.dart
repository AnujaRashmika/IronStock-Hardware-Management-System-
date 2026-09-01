import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/inventory_provider.dart';
import '../providers/product_provider.dart';
import '../app/theme.dart';
import '../app/app.dart';

class AppHeader extends StatefulWidget {
  final String title;
  final String? subtitle;
  final Widget? action;

  const AppHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  State<AppHeader> createState() => _AppHeaderState();
}

class _AppHeaderState extends State<AppHeader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _blink;

  @override
  void initState() {
    super.initState();
    _blink = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        context.read<ProductProvider>().load();
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _blink.dispose();
    super.dispose();
  }

  int _outOfStockCount(BuildContext context) {
    try {
      final products = context.watch<ProductProvider>().products;
      return products.where((p) => p.stockQuantity <= 0 && p.isActive).length;
    } catch (_) {
      return 0;
    }
  }

  void _openOutOfStock() {
    try {
      context.read<InventoryProvider>().pendingFilter = 'Out of Stock';
    } catch (_) {}
    MainLayout.of(context)?.navigateTo(AppPages.inventory);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeProvider = context.watch<ThemeProvider>();
    final auth = context.watch<AuthProvider>();
    final outCount = _outOfStockCount(context);
    final showStockAlert = outCount > 0;

    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2420) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF2A3530) : const Color(0xFFE6EAE8),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                if (widget.subtitle != null)
                  Text(
                    widget.subtitle!,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey.shade500 : Colors.grey,
                    ),
                  ),
              ],
            ),
          ),
          if (widget.action != null) widget.action!,
          const SizedBox(width: 12),
          if (showStockAlert)
            FadeTransition(
              opacity: Tween<double>(begin: 0.35, end: 1.0).animate(_blink),
              child: Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Material(
                  color: Colors.red.shade600,
                  borderRadius: BorderRadius.circular(24),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: _openOutOfStock,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.warning_amber_rounded, size: 16, color: Colors.white),
                          const SizedBox(width: 6),
                          Text(
                            'Out of Stock ($outCount)',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          Material(
            color: isDark ? const Color(0xFF24302B) : const Color(0xFFF0F4F2),
            borderRadius: BorderRadius.circular(24),
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () => themeProvider.toggleTheme(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      themeProvider.isDarkMode
                          ? Icons.light_mode_outlined
                          : Icons.dark_mode_outlined,
                      size: 18,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      themeProvider.isDarkMode ? 'Light Mode' : 'Dark Mode',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.grey.shade200 : Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            radius: 18,
            backgroundColor: isDark
                ? AppTheme.primaryColor.withOpacity(0.25)
                : const Color(0xFFE6F5F0),
            child: Text(
              (auth.currentUser?.fullName.isNotEmpty == true
                      ? auth.currentUser!.fullName[0]
                      : 'U')
                  .toUpperCase(),
              style: const TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
