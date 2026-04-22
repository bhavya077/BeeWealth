import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/app_widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final dashboard = Provider.of<DashboardProvider>(context, listen: false);
    await Future.wait([
      dashboard.fetchDashboard(),
      dashboard.fetchPerformance(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final dashboard = Provider.of<DashboardProvider>(context);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadData,
        backgroundColor: AppColors.primary,
        color: AppColors.background,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 120,
              floating: true,
              pinned: true,
              backgroundColor: AppColors.background,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                title: Text(
                  'Hello, ${auth.user?.name.split(' ')[0] ?? 'User'}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                background: Container(color: AppColors.background),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBalanceCard(dashboard),
                    const SizedBox(height: 24),
                    _buildStatsGrid(dashboard),
                    const SizedBox(height: 32),
                    const Text(
                      'Performance',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    _buildPerformanceChart(dashboard),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(DashboardProvider dashboard) {
    if (dashboard.isLoading && dashboard.dashboardData == null) {
      return Shimmer.fromColors(
        baseColor: Colors.grey[900]!,
        highlightColor: Colors.grey[800]!,
        child: Container(height: 180, decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(20))),
      );
    }

    final data = dashboard.dashboardData;
    return GlassCard(
      height: 180,
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('CURRENT VALUE', style: TextStyle(color: Colors.white70, letterSpacing: 2, fontSize: 12)),
          const SizedBox(height: 8),
          Text(
            currencyFormat.format(data?.currentValue ?? 0),
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.primary),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('TOTAL P/L', style: TextStyle(color: Colors.white54, fontSize: 10)),
                  Row(
                    children: [
                      Text(
                        '${(data?.totalProfitLoss ?? 0) >= 0 ? '+' : ''}${currencyFormat.format(data?.totalProfitLoss ?? 0)}',
                        style: TextStyle(
                          color: (data?.totalProfitLoss ?? 0) >= 0 ? AppColors.success : AppColors.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(${((data?.totalProfitLoss ?? 0) / (data?.totalInvestment ?? 1) * 100).toStringAsFixed(2)}%)',
                        style: TextStyle(
                          color: (data?.totalProfitLoss ?? 0) >= 0 ? AppColors.success : AppColors.error,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Icon(Icons.hive, color: AppColors.primary, size: 32),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(DashboardProvider dashboard) {
    final data = dashboard.dashboardData;
    return Row(
      children: [
        Expanded(
          child: _buildStatItem(
            'Invested',
            currencyFormat.format(data?.totalInvestment ?? 0),
            Icons.account_balance_wallet_outlined,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatItem(
            'Withdrawn',
            currencyFormat.format(data?.totalWithdrawn ?? 0),
            Icons.outbox_outlined,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String title, String value, IconData icon) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildPerformanceChart(DashboardProvider dashboard) {
    if (dashboard.isLoading && dashboard.performanceChart.isEmpty) {
      return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
    }
    
    if (dashboard.performanceChart.isEmpty) {
      return const GlassCard(
        height: 200,
        child: Center(child: Text('No data available yet', style: TextStyle(color: Colors.white38))),
      );
    }

    final chartData = dashboard.performanceChart;
    return GlassCard(
      height: 250,
      padding: const EdgeInsets.fromLTRB(8, 24, 24, 8),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: chartData.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.amount)).toList(),
              isCurved: true,
              color: AppColors.primary,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [AppColors.primary.withAlpha(50), AppColors.primary.withAlpha(0)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
