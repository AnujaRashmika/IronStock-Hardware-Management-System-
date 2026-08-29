import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../providers/app_provider.dart';

class DayClosingScreen extends StatefulWidget {
  const DayClosingScreen({super.key});

  @override
  State<DayClosingScreen> createState() => _DayClosingScreenState();
}

class _DayClosingScreenState extends State<DayClosingScreen> {
  final TextEditingController _openingCashCtrl = TextEditingController(text: '10000');
  final TextEditingController _actualCashCtrl = TextEditingController(text: '0');
  final TextEditingController _notesCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);

    final openingCash = double.tryParse(_openingCashCtrl.text) ?? 10000.0;
    final actualCash = double.tryParse(_actualCashCtrl.text) ?? 0.0;

    final today = DateTime.now();
    final todaySales = provider.sales
        .where((s) => s.date.year == today.year && s.date.month == today.month && s.date.day == today.day && s.status != 'Cancelled');

    double cashSales = 0.0;
    for (var s in todaySales) {
      for (var p in s.payments) {
        if (p.method == 'Cash') cashSales += p.amount;
      }
    }

    final todayRefunds = provider.refunds
        .where((r) => r.date.year == today.year && r.date.month == today.month && r.date.day == today.day && r.refundMethod == 'Cash')
        .fold(0.0, (sum, r) => sum + r.amount);

    final todayExpenses = provider.expenses
        .where((e) => e.date.year == today.year && e.date.month == today.month && e.date.day == today.day && e.paymentMethod == 'Cash')
        .fold(0.0, (sum, e) => sum + e.amount);

    final expectedCash = openingCash + cashSales - todayRefunds - todayExpenses;
    final diff = actualCash - expectedCash;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: Cash Closing Calculation Card
          SizedBox(
            width: 450,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.lock_clock, color: Colors.orange, size: 28),
                      const SizedBox(width: 8),
                      Text(
                        'Day-End Cash Closing (${DateFormat('dd MMM yyyy').format(DateTime.now())})',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  TextField(
                    controller: _openingCashCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Shift Opening Drawer Cash (Rs.)', border: OutlineInputBorder()),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.grey.shade50,
                    child: Column(
                      children: [
                        _buildRow('Opening Cash Balance:', 'Rs. ${openingCash.toStringAsFixed(2)}'),
                        _buildRow('Today Cash Sales (+):', 'Rs. ${cashSales.toStringAsFixed(2)}', color: Colors.green),
                        _buildRow('Today Cash Refunds (-):', '- Rs. ${todayRefunds.toStringAsFixed(2)}', color: Colors.red),
                        _buildRow('Today Cash Expenses (-):', '- Rs. ${todayExpenses.toStringAsFixed(2)}', color: Colors.red),
                        const Divider(),
                        _buildRow('Expected Cash in Drawer:', 'Rs. ${expectedCash.toStringAsFixed(2)}', isBold: true),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                  TextField(
                    controller: _actualCashCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Actual Physical Counted Cash (Rs.) *', border: OutlineInputBorder()),
                    onChanged: (_) => setState(() {}),
                  ),

                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: diff == 0 ? Colors.green.shade50 : (diff < 0 ? Colors.red.shade50 : Colors.amber.shade50),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Drawer Variance / Diff:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(
                          'Rs. ${diff.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: diff == 0 ? Colors.green.shade900 : (diff < 0 ? Colors.red.shade900 : Colors.amber.shade900),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),
                  TextField(
                    controller: _notesCtrl,
                    decoration: const InputDecoration(labelText: 'Closing Remarks / Notes', border: OutlineInputBorder()),
                  ),

                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    onPressed: () async {
                      final cashierName = provider.currentUser?.name ?? 'Cashier 01';
                      await provider.performDayClosing(
                        cashierName: cashierName,
                        openingCash: openingCash,
                        actualCash: actualCash,
                        notes: _notesCtrl.text.trim(),
                      );

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Day Closing shift reconciliation saved successfully!')),
                        );
                      }
                    },
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('SUBMIT DAY CLOSING SHIFT', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 20),

          // Right: Past Day Closings Log
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Past Cashier Shift Closings History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Expanded(
                    child: provider.dayClosings.isEmpty
                        ? const Center(child: Text('No previous shift closing records found.'))
                        : ListView.separated(
                            itemCount: provider.dayClosings.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final dc = provider.dayClosings[index];

                              return ListTile(
                                leading: const CircleAvatar(
                                  backgroundColor: Color(0xFF1E293B),
                                  child: Icon(Icons.lock, color: Colors.orange, size: 18),
                                ),
                                title: Text('Closing Date: ${DateFormat('dd MMM yyyy').format(dc.date)} (${dc.cashierName})', style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('Opening: Rs. ${dc.openingCash.toStringAsFixed(0)} | Cash Sales: Rs. ${dc.cashSales.toStringAsFixed(0)} | Exp Cash: Rs. ${dc.expectedCash.toStringAsFixed(0)}'),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('Actual: Rs. ${dc.actualCash.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                    Text(
                                      'Diff: Rs. ${dc.difference.toStringAsFixed(0)}',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: dc.difference == 0 ? Colors.green : Colors.red),
                                    ),
                                  ],
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
    );
  }

  Widget _buildRow(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(fontSize: 12, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: color)),
        ],
      ),
    );
  }
}
