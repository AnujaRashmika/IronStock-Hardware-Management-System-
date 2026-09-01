import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../core/utils/currency_utils.dart';
import '../../core/utils/app_snackbar.dart';
import '../../core/database/database_helper.dart';
import '../../core/constants/db_constants.dart';
import '../../providers/settings_provider.dart';
import '../../services/printer_service.dart';
import '../../widgets/page_header.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String period = 'today';
  DateTime? customFrom;
  DateTime? customTo;
  double sales = 0, purchases = 0, expenses = 0, returns = 0;
  int salesCount = 0;
  bool loading = true;
  bool printing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  (DateTime, DateTime) _range() {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
    switch (period) {
      case 'yesterday':
        final y = todayStart.subtract(const Duration(days: 1));
        return (y, DateTime(y.year, y.month, y.day, 23, 59, 59));
      case 'week':
        final start = todayStart.subtract(Duration(days: now.weekday - 1));
        return (start, todayEnd);
      case 'month':
        return (DateTime(now.year, now.month, 1), todayEnd);
      case 'custom':
        final from = customFrom ?? todayStart;
        final to = customTo ?? todayEnd;
        return (
          DateTime(from.year, from.month, from.day),
          DateTime(to.year, to.month, to.day, 23, 59, 59),
        );
      default:
        return (todayStart, todayEnd);
    }
  }

  String get _periodLabel {
    final (from, to) = _range();
    String fmt(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    switch (period) {
      case 'today':
        return 'Today (${fmt(from)})';
      case 'yesterday':
        return 'Yesterday (${fmt(from)})';
      case 'week':
        return 'This week (${fmt(from)} to ${fmt(to)})';
      case 'month':
        return 'This month (${fmt(from)} to ${fmt(to)})';
      case 'custom':
        return 'Custom (${fmt(from)} to ${fmt(to)})';
      default:
        return fmt(from);
    }
  }

  Future<void> _load() async {
    setState(() => loading = true);
    final (from, to) = _range();
    final db = await DatabaseHelper.instance.database;
    final s = await db.rawQuery(
      'SELECT COALESCE(SUM(total),0) as t, COUNT(*) as c FROM ${DbConstants.sales} WHERE created_at BETWEEN ? AND ?',
      [from.toIso8601String(), to.toIso8601String()],
    );
    final p = await db.rawQuery(
      'SELECT COALESCE(SUM(total),0) as t FROM ${DbConstants.purchases} WHERE created_at BETWEEN ? AND ?',
      [from.toIso8601String(), to.toIso8601String()],
    );
    final e = await db.rawQuery(
      'SELECT COALESCE(SUM(amount),0) as t FROM ${DbConstants.expenses} WHERE expense_date BETWEEN ? AND ?',
      [from.toIso8601String(), to.toIso8601String()],
    );
    final r = await db.rawQuery(
      'SELECT COALESCE(SUM(total),0) as t FROM ${DbConstants.returns} WHERE created_at BETWEEN ? AND ?',
      [from.toIso8601String(), to.toIso8601String()],
    );
    sales = (s.first['t'] as num).toDouble();
    salesCount = s.first['c'] as int;
    purchases = (p.first['t'] as num).toDouble();
    expenses = (e.first['t'] as num).toDouble();
    returns = (r.first['t'] as num).toDouble();
    setState(() => loading = false);
  }

  Future<void> _print() async {
    setState(() => printing = true);
    try {
      final settings = context.read<SettingsProvider>();
      final gross = sales - purchases;
      final net = gross - expenses - returns;
      await PrinterService.instance.printReport(
        shopName: settings.shopName,
        title: 'Business Report',
        period: _periodLabel,
        totals: {
          'Sales ($salesCount invoices)': sales,
          'Purchases': purchases,
          'Returns': returns,
          'Expenses': expenses,
          'Gross Profit': gross,
          'Net Profit': net,
        },
      );
    } catch (e) {
      if (mounted) showErrorSnackBar(context, 'Print failed: $e');
    }
    if (mounted) setState(() => printing = false);
  }

  Future<void> _pickFrom() async {
    final d = await showDatePicker(
      context: context,
      initialDate: customFrom ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (d != null) {
      setState(() {
        customFrom = d;
        period = 'custom';
      });
      await _load();
    }
  }

  Future<void> _pickTo() async {
    final d = await showDatePicker(
      context: context,
      initialDate: customTo ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (d != null) {
      setState(() {
        customTo = d;
        period = 'custom';
      });
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final gross = sales - purchases;
    final net = gross - expenses - returns;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeader(
              title: 'Reports',
              subtitle: 'Sales, purchases, profit and expenses',
              actions: [
                ElevatedButton.icon(
                  onPressed: printing ? null : _print,
                  icon: printing
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.print, size: 18),
                  label: const Text('Print Report'),
                ),
              ],
            ),
            // Period filters
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _chip('Today', 'today'),
                _chip('Yesterday', 'yesterday'),
                _chip('This Week', 'week'),
                _chip('This Month', 'month'),
                _chip('Custom Range', 'custom'),
              ],
            ),
            if (period == 'custom') ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _pickFrom,
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(customFrom == null
                        ? 'From date'
                        : '${customFrom!.year}-${customFrom!.month.toString().padLeft(2, '0')}-${customFrom!.day.toString().padLeft(2, '0')}'),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    onPressed: _pickTo,
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(customTo == null
                        ? 'To date'
                        : '${customTo!.year}-${customTo!.month.toString().padLeft(2, '0')}-${customTo!.day.toString().padLeft(2, '0')}'),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Text(_periodLabel, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            const SizedBox(height: 16),
            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      children: [
                        LayoutBuilder(builder: (context, c) {
                          final w = c.maxWidth > 700 ? (c.maxWidth - 32) / 3 : c.maxWidth;
                          return Wrap(
                            spacing: 16,
                            runSpacing: 16,
                            children: [
                              _card(w, 'Sales', CurrencyUtils.format(sales), '$salesCount invoices', Icons.point_of_sale_outlined, AppColors.green),
                              _card(w, 'Purchases', CurrencyUtils.format(purchases), 'Stock in', Icons.shopping_cart_outlined, AppColors.blue),
                              _card(w, 'Returns', CurrencyUtils.format(returns), 'Refunds & returns', Icons.assignment_return_outlined, AppColors.orange),
                              _card(w, 'Expenses', CurrencyUtils.format(expenses), 'Operating costs', Icons.payments_outlined, AppColors.red),
                              _card(w, 'Gross Profit', CurrencyUtils.format(gross), 'Sales − Purchases', Icons.trending_up, AppColors.teal),
                              _card(w, 'Net Profit', CurrencyUtils.format(net), 'After expenses & returns', Icons.account_balance_wallet_outlined, AppColors.purple),
                            ],
                          );
                        }),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, String value) {
    final selected = period == value;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) async {
        setState(() => period = value);
        await _load();
      },
    );
  }

  Widget _card(double width, String title, String value, String subtitle, IconData icon, Color color) {
    return SizedBox(
      width: width,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.softOf(color),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 14),
              Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
            ],
          ),
        ),
      ),
    );
  }
}
