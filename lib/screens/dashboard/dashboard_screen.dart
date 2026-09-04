import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../app/theme.dart';
import '../../core/utils/currency_utils.dart';
import '../../repositories/dashboard_repository.dart';
import '../../app/app.dart';
import '../../widgets/app_header.dart';
import '../../screens/delivery/delivery_screen.dart';
import '../../screens/returns/returns_screen.dart';
import '../../screens/warranty/warranty_screen.dart';
import '../../core/database/database_helper.dart';
import '../../core/constants/db_constants.dart';
import '../inventory/inventory_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _repo = DashboardRepository();
  Map<String, dynamic>? stats;
  List<Map<String, dynamic>> recent = [];
  List<double> weekSales = List.filled(7, 0);
  List<double> monthSales = List.filled(12, 0);
  String chartMode = 'week'; // week | month
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
    weekSales = await _loadWeekChart();
    monthSales = await _loadMonthChart();
    setState(() => loading = false);
  }

  Future<List<double>> _loadWeekChart() async {
    final db = await DatabaseHelper.instance.database;
    final result = List<double>.filled(7, 0);
    final now = DateTime.now();
    for (int i = 6; i >= 0; i--) {
      final day = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      final start = day.toIso8601String();
      final end = DateTime(day.year, day.month, day.day, 23, 59, 59).toIso8601String();
      final r = await db.rawQuery(
        'SELECT COALESCE(SUM(total),0) as t FROM ${DbConstants.sales} WHERE created_at BETWEEN ? AND ?',
        [start, end],
      );
      result[6 - i] = (r.first['t'] as num).toDouble();
    }
    return result;
  }

  Future<List<double>> _loadMonthChart() async {
    final db = await DatabaseHelper.instance.database;
    final result = List<double>.filled(12, 0);
    final now = DateTime.now();
    for (int i = 11; i >= 0; i--) {
      final monthDate = DateTime(now.year, now.month - i, 1);
      final start = DateTime(monthDate.year, monthDate.month, 1);
      final end = DateTime(monthDate.year, monthDate.month + 1, 0, 23, 59, 59);
      final r = await db.rawQuery(
        'SELECT COALESCE(SUM(total),0) as t FROM ${DbConstants.sales} WHERE created_at BETWEEN ? AND ?',
        [start.toIso8601String(), end.toIso8601String()],
      );
      result[11 - i] = (r.first['t'] as num).toDouble();
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final s = stats!;
    final series = chartMode == 'week' ? weekSales : monthSales;
    final maxY = series.fold<double>(0, (a, b) => a > b ? a : b);
    final chartMax = maxY <= 0 ? 1000.0 : maxY * 1.2;

    return Column(
      children: [
        const AppHeader(
          title: 'Dashboard',
          subtitle: 'Overview of your hardware store',
        ),
        Expanded(
          child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 32),
          children: [
            // Main KPI cards
            LayoutBuilder(builder: (context, constraints) {
              final w = constraints.maxWidth;
              final cardW = w > 900 ? (w - 48) / 4 : (w > 500 ? (w - 16) / 2 : w);
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _kpi(cardW, 'Today\'s Sales', CurrencyUtils.format(s['todaySales']), Icons.point_of_sale_outlined, AppColors.green),
                  _kpi(cardW, 'Today\'s Purchases', CurrencyUtils.format(s['todayPurchases']), Icons.shopping_cart_outlined, AppColors.blue),
                  _kpi(cardW, 'Today\'s Profit', CurrencyUtils.format(s['todayProfit']), Icons.trending_up, AppColors.teal),
                  _kpiTap(cardW, 'Pending Returns', '${s['pendingReturns']}', Icons.assignment_return_outlined, AppColors.orange, () {
                    ReturnsScreen.pendingStatusFilter = 'pending';
                    MainLayout.of(context)?.navigateTo(AppPages.returns);
                  }),
                ],
              );
            }),
            const SizedBox(height: 16),
            LayoutBuilder(builder: (context, constraints) {
              final w = constraints.maxWidth;
              // Larger alert cards (3 across when wide)
              final cardW = w > 700 ? (w - 40) / 3 : (w - 16) / 2;
              return Wrap(
                spacing: 20,
                runSpacing: 18,
                children: [
                  _alert(cardW, 'Low Stock', '${s['lowStock']}', Icons.warning_amber_rounded, AppColors.red, () {
                    // set via InventoryProvider in build — use static bridge
                    InventoryScreen.bridgeFilter = 'Low Stock';
                    MainLayout.of(context)?.navigateTo(AppPages.inventory);
                  }),
                  _alert(cardW, 'Pending Deliveries', '${s['pendingDeliveries']}', Icons.local_shipping_outlined, AppColors.purple, () {
                    DeliveryScreen.pendingStatusFilter = 'Pending';
                    MainLayout.of(context)?.navigateTo(AppPages.delivery);
                  }),
                  _alert(cardW, 'Warranty Claims', '${s['warrantyClaims']}', Icons.verified_outlined, AppColors.indigo, () {
                    WarrantyScreen.openClaimsTab = true;
                    MainLayout.of(context)?.navigateTo(AppPages.warranty);
                  }),
                ],
              );
            }),
            const SizedBox(height: 24),
            // Charts row
            LayoutBuilder(builder: (context, constraints) {
              final wide = constraints.maxWidth > 800;
              final chartCard = Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              chartMode == 'week' ? 'Sales — Last 7 Days' : 'Sales — Last 12 Months',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                            ),
                          ),
                          SegmentedButton<String>(
                            segments: const [
                              ButtonSegment(value: 'week', label: Text('7 Days'), icon: Icon(Icons.bar_chart, size: 16)),
                              ButtonSegment(value: 'month', label: Text('Monthly'), icon: Icon(Icons.show_chart, size: 16)),
                            ],
                            selected: {chartMode},
                            onSelectionChanged: (s) => setState(() => chartMode = s.first),
                            style: ButtonStyle(
                              visualDensity: VisualDensity.compact,
                              textStyle: WidgetStatePropertyAll(TextStyle(fontSize: 12)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 200,
                        child: chartMode == 'week'
                            ? BarChart(
                                BarChartData(
                                  maxY: chartMax,
                                  gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: chartMax / 4),
                                  borderData: FlBorderData(show: false),
                                  titlesData: FlTitlesData(
                                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 42,
                                        getTitlesWidget: (v, _) => Text(
                                          v >= 1000 ? '${(v / 1000).toStringAsFixed(0)}k' : v.toStringAsFixed(0),
                                          style: const TextStyle(fontSize: 10),
                                        ),
                                      ),
                                    ),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        getTitlesWidget: (v, _) {
                                          final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                                          final i = v.toInt();
                                          if (i < 0 || i > 6) return const SizedBox();
                                          return Padding(
                                            padding: const EdgeInsets.only(top: 6),
                                            child: Text(days[i], style: const TextStyle(fontSize: 11)),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  barGroups: List.generate(7, (i) {
                                    return BarChartGroupData(
                                      x: i,
                                      barRods: [
                                        BarChartRodData(
                                          toY: weekSales[i],
                                          width: 18,
                                          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                                          color: AppTheme.primaryColor,
                                        ),
                                      ],
                                    );
                                  }),
                                ),
                              )
                            : LineChart(
                                LineChartData(
                                  maxY: chartMax,
                                  minY: 0,
                                  gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: chartMax / 4),
                                  borderData: FlBorderData(show: false),
                                  titlesData: FlTitlesData(
                                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 42,
                                        getTitlesWidget: (v, _) => Text(
                                          v >= 1000 ? '${(v / 1000).toStringAsFixed(0)}k' : v.toStringAsFixed(0),
                                          style: const TextStyle(fontSize: 10),
                                        ),
                                      ),
                                    ),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        interval: 1,
                                        getTitlesWidget: (v, _) {
                                          const labels = ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];
                                          // last 12 months ending current month
                                          final now = DateTime.now();
                                          final i = v.toInt();
                                          if (i < 0 || i > 11) return const SizedBox();
                                          final m = DateTime(now.year, now.month - (11 - i), 1).month - 1;
                                          return Padding(
                                            padding: const EdgeInsets.only(top: 6),
                                            child: Text(labels[m], style: const TextStyle(fontSize: 10)),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  lineBarsData: [
                                    LineChartBarData(
                                      spots: List.generate(12, (i) => FlSpot(i.toDouble(), monthSales[i])),
                                      isCurved: true,
                                      color: AppTheme.primaryColor,
                                      barWidth: 3,
                                      dotData: const FlDotData(show: true),
                                      belowBarData: BarAreaData(
                                        show: true,
                                        color: AppTheme.primaryColor.withOpacity(0.12),
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

              final recentCard = Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Recent Sales', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      if (recent.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(child: Text('No sales yet')),
                        )
                      else
                        ...recent.take(8).map((r) => ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              title: Text(r['invoice_no'] ?? '', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                              subtitle: Text(r['customer_name'] ?? 'Walk-in', style: const TextStyle(fontSize: 12)),
                              trailing: Text(CurrencyUtils.format(r['total'] ?? 0),
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            )),
                    ],
                  ),
                ),
              );
              if (wide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: chartCard),
                    const SizedBox(width: 16),
                    Expanded(flex: 2, child: recentCard),
                  ],
                );
              }
              return Column(children: [chartCard, const SizedBox(height: 16), recentCard]);
            }),
          ],
        ),
          ),
        ),
      ],
    );
  }

  Widget _kpi(double width, String title, String value, IconData icon, Color color) {
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
              Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w400)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _kpiTap(double width, String title, String value, IconData icon, Color color, VoidCallback onTap) {
    return SizedBox(
      width: width,
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppColors.softOf(color), borderRadius: BorderRadius.circular(10)),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(height: 12),
                Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _alert(double width, String title, String value, IconData icon, Color color, VoidCallback onTap) {
    return SizedBox(
      width: width,
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Row(
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                      Text(title, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, size: 18, color: Colors.grey.shade400),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
