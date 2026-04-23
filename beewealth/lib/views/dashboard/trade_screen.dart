import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/trade_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/app_widgets.dart';

class TradeScreen extends StatefulWidget {
  const TradeScreen({super.key});

  @override
  State<TradeScreen> createState() => _TradeScreenState();
}

class _TradeScreenState extends State<TradeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initTrade();
    });
  }

  void _initTrade() {
    final trade = Provider.of<TradeProvider>(context, listen: false);
    trade.connectWebSocket();
    trade.fetchTodayOrders();
  }

  @override
  void dispose() {
    // Since we are using IndexedStack, this might not be called often,
    // but if the whole MainLayout is disposed, we clean up.
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<TradeProvider>(
        builder: (context, trade, _) {
          return RefreshIndicator(
            onRefresh: () => trade.fetchTodayOrders(),
            color: AppColors.primary,
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 100,
                  floating: true,
                  pinned: true,
                  backgroundColor: AppColors.background,
                  flexibleSpace: const FlexibleSpaceBar(
                    title: Text('Trading Terminal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    titlePadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                  actions: [
                    IconButton(
                      onPressed: () => trade.fetchTodayOrders(),
                      icon: const Icon(Icons.refresh, color: AppColors.primary),
                    ),
                  ],
                ),
                if (trade.error != null && trade.positions.isEmpty && trade.closedOrders.isEmpty)
                  SliverFillRemaining(
                    child: _buildMarketClosedMessage(trade.error!),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.all(20),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _buildSectionTitle('LIVE POSITIONS', Icons.sensors),
                        const SizedBox(height: 12),
                        _buildPositionsList(trade.positions),
                        const SizedBox(height: 32),
                        _buildSectionTitle("TODAY'S ORDERS", Icons.history_edu),
                        const SizedBox(height: 12),
                        _buildOrdersList(trade.closedOrders),
                        const BrandedFooter(),
                      ]),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 16),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildPositionsList(List<Position> positions) {
    if (positions.isEmpty) {
      return const GlassCard(
        height: 80,
        child: Center(child: Text('No open positions', style: TextStyle(color: Colors.white24, fontSize: 12))),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: positions.length,
      itemBuilder: (context, index) {
        final p = positions[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: GlassCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.symbol, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text('LTP: ${p.ltp.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white38, fontSize: 11)),
                  ],
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${p.pnlPercentage >= 0 ? '+' : ''}${p.pnlPercentage.toStringAsFixed(2)}%',
                      style: TextStyle(
                        color: p.pnlPercentage >= 0 ? AppColors.success : AppColors.error,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const Text('UNREALIZED P/L', style: TextStyle(color: Colors.white24, fontSize: 7)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOrdersList(List<PaperOrder> orders) {
    if (orders.isEmpty) {
      return const GlassCard(
        height: 80,
        child: Center(child: Text('No closed orders today', style: TextStyle(color: Colors.white24, fontSize: 12))),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final o = orders[index];
        DateTime? exitDate;
        try {
          exitDate = DateTime.parse(o.exitTime);
        } catch (_) {}

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(o.symbol, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      if (exitDate != null)
                        Text(
                          'Exit: ${DateFormat('HH:mm').format(exitDate)}',
                          style: const TextStyle(color: Colors.white38, fontSize: 10),
                        ),
                    ],
                  ),
                ),
                Text(
                  '${o.pnlPercentage >= 0 ? '+' : ''}${o.pnlPercentage.toStringAsFixed(2)}%',
                  style: TextStyle(
                    color: o.pnlPercentage >= 0 ? AppColors.success : AppColors.error,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }


  Widget _buildMarketClosedMessage(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.query_stats, size: 60, color: AppColors.primary.withAlpha(40)),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: () => Provider.of<TradeProvider>(context, listen: false).fetchTodayOrders(),
            child: const Text('Try Refresh', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}
