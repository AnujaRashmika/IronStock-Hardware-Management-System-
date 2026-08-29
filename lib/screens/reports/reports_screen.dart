import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_provider.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Hardware Shop Analytical Reports', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report generated for printing/export!')));
                },
                icon: const Icon(Icons.print_rounded),
                label: const Text('Print Current Report View'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Tabs Header
          TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: Colors.orange,
            unselectedLabelColor: Colors.grey.shade700,
            indicatorColor: Colors.orange,
            tabs: const [
              Tab(text: 'Profit & Loss Report'),
              Tab(text: 'Sales Analytics'),
              Tab(text: 'Purchase Reports'),
              Tab(text: 'Inventory Valuation'),
              Tab(text: 'Customer Receivables'),
              Tab(text: 'Expense Breakdown'),
            ],
          ),

          const SizedBox(height: 16),

          // Tab Views Body
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildProfitReport(provider),
                  _buildSalesReport(provider),
                  _buildPurchaseReport(provider),
                  _buildInventoryValuationReport(provider),
                  _buildCustomerReceivablesReport(provider),
                  _buildExpenseReport(provider),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfitReport(AppProvider provider) {
    double totalRevenue = provider.sales.where((s) => s.status != 'Cancelled').fold(0.0, (sum, s) => sum + s.totalAmount);

    double totalCostOfGoods = 0.0;
    for (var s in provider.sales.where((s) => s.status != 'Cancelled')) {
      for (var i in s.items) {
        totalCostOfGoods += (i.purchasePrice * i.quantity);
      }
    }

    double grossProfit = totalRevenue - totalCostOfGoods;
    double totalExpenses = provider.expenses.fold(0.0, (sum, e) => sum + e.amount);
    double netProfit = grossProfit - totalExpenses;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Income Statement & Profitability Overview', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const Divider(height: 24),
          _buildReportRow('Total Sales Revenue (Turnover):', 'Rs. ${totalRevenue.toStringAsFixed(2)}', isBold: true),
          _buildReportRow('Cost of Goods Sold (COGS):', '- Rs. ${totalCostOfGoods.toStringAsFixed(2)}', color: Colors.grey.shade800),
          const Divider(),
          _buildReportRow('GROSS PROFIT:', 'Rs. ${grossProfit.toStringAsFixed(2)}', isBold: true, color: Colors.blue.shade900),
          const SizedBox(height: 12),
          _buildReportRow('Total Operating Expenses:', '- Rs. ${totalExpenses.toStringAsFixed(2)}', color: Colors.red),
          const Divider(thickness: 2),
          _buildReportRow(
            'NET PROFIT (BOTTOM LINE):',
            'Rs. ${netProfit.toStringAsFixed(2)}',
            isBold: true,
            color: netProfit >= 0 ? Colors.green.shade900 : Colors.red.shade900,
          ),
        ],
      ),
    );
  }

  Widget _buildSalesReport(AppProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Total Completed Sales Invoices: ${provider.sales.length}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.separated(
            itemCount: provider.sales.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final s = provider.sales[index];
              return ListTile(
                title: Text('${s.invoiceNo} - ${s.customerName}', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Method: ${s.primaryPaymentMethod} | Items: ${s.items.length}'),
                trailing: Text('Rs. ${s.totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPurchaseReport(AppProvider provider) {
    double totalPurchases = provider.purchases.fold(0.0, (s, p) => s + p.totalAmount);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Total Purchases Cost: Rs. ${totalPurchases.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.separated(
            itemCount: provider.purchases.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final p = provider.purchases[index];
              return ListTile(
                title: Text('${p.purchaseNo} - ${p.supplierName}', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Paid: Rs. ${p.paidAmount.toStringAsFixed(2)} | Credit: Rs. ${p.creditAmount.toStringAsFixed(2)}'),
                trailing: Text('Rs. ${p.totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildInventoryValuationReport(AppProvider provider) {
    double totalStockCostValuation = provider.products.fold(0.0, (s, p) => s + (p.currentStock * p.purchasePrice));
    double totalStockSellingValuation = provider.products.fold(0.0, (s, p) => s + (p.currentStock * p.sellingPrice));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Stock Valuation (Cost Basis): Rs. ${totalStockCostValuation.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            Text('Stock Valuation (Retail Basis): Rs. ${totalStockSellingValuation.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.green)),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.separated(
            itemCount: provider.products.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final p = provider.products[index];
              final valuation = p.currentStock * p.purchasePrice;

              return ListTile(
                title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Category: ${p.category} | Stock: ${p.currentStock.toStringAsFixed(0)} ${p.unit}'),
                trailing: Text('Valuation: Rs. ${valuation.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerReceivablesReport(AppProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Total Customer Outstanding Receivable: Rs. ${provider.totalCustomerOutstanding.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.purple)),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.separated(
            itemCount: provider.customers.where((c) => c.balance > 0).length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final c = provider.customers.where((cust) => cust.balance > 0).toList()[index];
              return ListTile(
                title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Type: ${c.customerType} | Phone: ${c.phone}'),
                trailing: Text('Rs. ${c.balance.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.purple, fontSize: 16)),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildExpenseReport(AppProvider provider) {
    double totalExp = provider.expenses.fold(0.0, (s, e) => s + e.amount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Total Expense Cost: Rs. ${totalExp.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red)),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.separated(
            itemCount: provider.expenses.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final e = provider.expenses[index];
              return ListTile(
                title: Text('${e.categoryName} - ${e.description}', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Method: ${e.paymentMethod}'),
                trailing: Text('- Rs. ${e.amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildReportRow(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: color)),
        ],
      ),
    );
  }
}
