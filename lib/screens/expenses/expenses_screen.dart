import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../providers/app_provider.dart';

class ExpensesScreen extends StatelessWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);

    final totalExpensesAmount = provider.expenses.fold(0.0, (sum, e) => sum + e.amount);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Shop Expenses Tracker (Total Recorded: Rs. ${totalExpensesAmount.toStringAsFixed(2)})',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                onPressed: () => _showAddExpenseModal(context, provider),
                icon: const Icon(Icons.add_card_rounded),
                label: const Text('Record New Expense'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: provider.expenses.isEmpty
                  ? const Center(child: Text('No expenses recorded yet.'))
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: provider.expenses.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final exp = provider.expenses[index];

                        return ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Colors.redAccent,
                            child: Icon(Icons.money_off, color: Colors.white, size: 20),
                          ),
                          title: Row(
                            children: [
                              Text(exp.description, style: const TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(4)),
                                child: Text(exp.categoryName, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          subtitle: Text('Method: ${exp.paymentMethod} | Date: ${DateFormat('dd MMM yyyy HH:mm').format(exp.date)} | Ref: ${exp.reference}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '- Rs. ${exp.amount.toStringAsFixed(2)}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red),
                              ),
                              const SizedBox(width: 12),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                onPressed: () => provider.deleteExpense(exp.id),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddExpenseModal(BuildContext context, AppProvider provider) {
    String category = provider.expenseCategories.isNotEmpty ? provider.expenseCategories.first.name : 'Transport';
    final descCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final refCtrl = TextEditingController();
    String method = 'Cash';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Record New Expense Entry'),
        content: SizedBox(
          width: 450,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: category,
                decoration: const InputDecoration(labelText: 'Expense Category', border: OutlineInputBorder()),
                items: provider.expenseCategories.map((c) => DropdownMenuItem(value: c.name, child: Text(c.name))).toList(),
                onChanged: (val) {
                  if (val != null) category = val;
                },
              ),
              const SizedBox(height: 12),
              TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description / Purpose *', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: amountCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Expense Amount (Rs.) *', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: method,
                decoration: const InputDecoration(labelText: 'Payment Method', border: OutlineInputBorder()),
                items: ['Cash', 'Card', 'Bank Transfer', 'Petty Cash'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                onChanged: (val) {
                  if (val != null) method = val;
                },
              ),
              const SizedBox(height: 12),
              TextField(controller: refCtrl, decoration: const InputDecoration(labelText: 'Reference / Voucher #', border: OutlineInputBorder())),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
            onPressed: () {
              final amt = double.tryParse(amountCtrl.text) ?? 0;
              if (descCtrl.text.trim().isEmpty || amt <= 0) return;

              provider.addExpense(
                categoryName: category,
                description: descCtrl.text.trim(),
                amount: amt,
                paymentMethod: method,
                reference: refCtrl.text.trim(),
              );
              Navigator.of(context).pop();
            },
            child: const Text('Record Expense'),
          ),
        ],
      ),
    );
  }
}
