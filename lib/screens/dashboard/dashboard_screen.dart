import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../core/utils/currency_utils.dart';
import '../../repositories/dashboard_repository.dart';
import '../../app/app.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _repo = DashboardRepository();
  Map<String, dynamic>? stats;
  List<Map<String, dynamic>> recent = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    stats = await _repo.getStats();
    recent = await _repo.recentSales();
    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    final s = stats!;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Row(
              children: [
                const Text('Dashboard', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                const Spacer(),
                IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
              ],
            ),
            const SizedBox(height: 8),
            Text('Overview of your hardware store', style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 20),
            // Main cards
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _card('Today\'s Sales', CurrencyUtils.format(s['todaySales']), Icons.point_of_sale, AppColors.green),
                _card('Today\'s Purchases', CurrencyUtils.format(s['todayPurchases']), Icons.shopping_cart, AppColors.blue),
                _card('Today\'s Profit', CurrencyUtils.format(s['todayProfit']), Icons.trending_up, AppColors.teal),
                _card('Pending Payments', CurrencyUtils.format(s['pendingPayments']), Icons.account_balance_wallet, AppColors.orange),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _smallCard('Low Stock', '${s['lowStock']} Items', Icons.warning_amber, AppColors.red, AppPages.inventory),
                _smallCard('Pending Deliveries', '${s['pendingDeliveries']}', Icons.local_shipping, AppColors.purple, AppPages.delivery),
                _smallCard('Pending Returns', '${s['pendingReturns']}', Icons.assignment_return, AppColors.orange, AppPages.returns),
                _smallCard('Warranty Claims', '${s['warrantyClaims']}', Icons.verified, AppColors.indigo, AppPages.warranty),
              ],
            ),
            const SizedBox(height: 24),
            // Recent sales
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Recent Sales', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    const SizedBox(height: 12),
                    if (recent.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: Text('No sales yet')),
                      )
                    else
                      ...recent.take(8).map((r) => ListTile(
                            dense: true,
                            title: Text(r['invoice_no'] ?? ''),
                            subtitle: Text(r['customer_name'] ?? 'Walk-in'),
                            trailing: Text(CurrencyUtils.format(r['total'] ?? 0),
                                style: const TextStyle(fontWeight: FontWeight.w700)),
                          )),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(String title, String value, IconData icon, Color color) {
    return SizedBox(
      width: 220,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: AppColors.softOf(color), borderRadius: BorderRadius.circular(10)),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const Spacer(),
                ],
              ),
              const SizedBox(height: 12),
              Text(title, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _smallCard(String title, String value, IconData icon, Color color, int page) {
    return SizedBox(
      width: 180,
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => MainLayout.of(context)?.navigateTo(page),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                      Text(title, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                    ],
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
