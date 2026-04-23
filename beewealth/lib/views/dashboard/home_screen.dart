import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/app_widgets.dart';
import '../../models/app_models.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
  int _touchedIndex = -1;
  String _selectedRange = 'ALL';

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
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _loadData,
        backgroundColor: AppColors.primary,
        color: AppColors.background,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildAppBar(auth),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 12),
                  _buildMainPortfolioCard(dashboard),
                  const SizedBox(height: 32),
                  _buildChartSection(dashboard),
                  const SizedBox(height: 32),
                  _buildSecondaryStats(dashboard),
                  const BrandedFooter(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(AuthProvider auth) {
    return SliverAppBar(
      expandedHeight: 100,
      collapsedHeight: 70,
      pinned: true,
      backgroundColor: AppColors.background,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(color: AppColors.background),
        titlePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TERMINAL',
                  style: TextStyle(
                    color: AppColors.primary.withOpacity(0.6),
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.5,
                  ),
                ),
                Text(
                  auth.user?.name.toUpperCase() ?? 'Hedge Account',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const Spacer(),
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primary.withOpacity(0.12),
              child: const Icon(Icons.bolt, color: AppColors.primary, size: 18),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainPortfolioCard(DashboardProvider dashboard) {
    if (dashboard.isLoading && dashboard.dashboardData == null) {
      return Shimmer.fromColors(
        baseColor: Colors.white.withOpacity(0.05),
        highlightColor: Colors.white.withOpacity(0.1),
        child: Container(height: 140, decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(24))),
      );
    }
    final data = dashboard.dashboardData;
    final isProfit = (data?.totalProfitLoss ?? 0) >= 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'TOTAL EQUITY',
          style: TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              currencyFormat.format(data?.currentValue ?? 0).split('.')[0],
              style: const TextStyle(fontSize: 38, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            Text(
              '.${(data?.currentValue ?? 0).toStringAsFixed(2).split('.')[1]}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white.withOpacity(0.5)),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: (isProfit ? AppColors.success : AppColors.error).withOpacity(0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${isProfit ? '▲' : '▼'} ${((data?.totalProfitLoss ?? 0) / (data?.totalInvestment ?? 1) * 100).toStringAsFixed(2)}%',
                style: TextStyle(
                  color: isProfit ? AppColors.success : AppColors.error,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChartSection(DashboardProvider dashboard) {
    if (dashboard.isLoading && dashboard.performanceChart.isEmpty) {
      return const SizedBox(height: 300, child: Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 1)));
    }
    
    final chartData = List<PerformanceData>.from(dashboard.performanceChart);
    chartData.sort((a, b) => a.date.compareTo(b.date));

    // Handle empty data
    if (chartData.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.02), borderRadius: BorderRadius.circular(20)),
        child: const Center(child: Text('WAITING FOR DATA FEED', style: TextStyle(color: Colors.white24, fontSize: 10))),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ANALYTICS',
                  style: TextStyle(
                    color: AppColors.primary.withOpacity(0.6),
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.5,
                  ),
                ),
                const Text(
                  'PERFORMANCE HISTORY',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const Spacer(),
            _buildRangeSelector(),
          ],
        ),
        const SizedBox(height: 32),
        SizedBox(
          height: 260,
          child: LineChart(
            LineChartData(
              lineTouchData: LineTouchData(
                touchCallback: (FlTouchEvent event, LineTouchResponse? response) {
                  if (response == null || response.lineBarSpots == null) {
                    setState(() { _touchedIndex = -1; });
                    return;
                  }
                  setState(() {
                    _touchedIndex = response.lineBarSpots!.first.spotIndex;
                  });
                },
                handleBuiltInTouches: true,
                getTouchedSpotIndicator: (LineChartBarData barData, List<int> spotIndexes) {
                  return spotIndexes.map((index) {
                    return TouchedSpotIndicatorData(
                      FlLine(
                        color: AppColors.primary.withOpacity(0.15),
                        strokeWidth: 20, // Wide aura bar
                      ),
                      FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                          radius: 4,
                          color: AppColors.primary,
                          strokeColor: AppColors.background,
                          strokeWidth: 2,
                        ),
                      ),
                    );
                  }).toList();
                },
                touchTooltipData: LineTouchTooltipData(
                  tooltipBgColor: const Color(0xFF1A1D23).withOpacity(0.9),
                  tooltipRoundedRadius: 8,
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      final data = chartData[spot.x.toInt()];
                      return LineTooltipItem(
                        '${currencyFormat.format(data.amount)}\n',
                        const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        children: [
                          TextSpan(
                            text: DateFormat('dd MMM, HH:mm').format(DateTime.tryParse(data.date) ?? DateTime.now()),
                            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 9, fontWeight: FontWeight.normal),
                          ),
                        ],
                      );
                    }).toList();
                  },
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false, // Horizontal only for professional look
                horizontalInterval: 50000,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: Colors.white.withOpacity(0.03),
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      if (value == meta.min || value == meta.max) return const SizedBox();
                      return Text(
                        NumberFormat.compact().format(value),
                        style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 9, fontWeight: FontWeight.bold),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    interval: (chartData.length / 3).clamp(1, 100).toDouble(),
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() >= chartData.length) return const SizedBox();
                      final dateStr = chartData[value.toInt()].date;
                      return Padding(
                        padding: const EdgeInsets.only(top: 12.0),
                        child: Text(
                          DateFormat('MMM dd').format(DateTime.tryParse(dateStr) ?? DateTime.now()).toUpperCase(),
                          style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: chartData.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.amount)).toList(),
                  isCurved: true,
                  curveSmoothness: 0.15, // Tension for professional look
                  color: AppColors.primary,
                  barWidth: 1.5, // Thinner line
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withOpacity(0.08),
                        AppColors.primary.withOpacity(0.02),
                        Colors.transparent,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.0, 0.4, 1.0],
                    ),
                  ),
                  shadow: Shadow(
                    color: AppColors.primary.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRangeSelector() {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: ['1D', '1W', '1M', 'ALL'].map((r) {
          final isSelected = _selectedRange == r;
          return GestureDetector(
            onTap: () => setState(() => _selectedRange = r),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                r,
                style: TextStyle(
                  color: isSelected ? Colors.black : Colors.white24,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSecondaryStats(DashboardProvider dashboard) {
    final data = dashboard.dashboardData;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ACCOUNT OVERVIEW',
          style: TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 16),
        _buildSimplifiedStatRow('Invested Principal', currencyFormat.format(data?.totalInvestment ?? 0), Icons.wallet),
        const Divider(color: Colors.white10, height: 24),
        _buildSimplifiedStatRow('Total Withdrawals', currencyFormat.format(data?.totalWithdrawn ?? 0), Icons.north_east),
        const Divider(color: Colors.white10, height: 24),
        _buildSimplifiedStatRow('P/L Unfilled', currencyFormat.format(data?.totalProfitLoss ?? 0), Icons.query_stats_outlined),
      ],
    );
  }

  Widget _buildSimplifiedStatRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white70, size: 16),
        ),
        const SizedBox(width: 16),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w500)),
        const Spacer(),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
