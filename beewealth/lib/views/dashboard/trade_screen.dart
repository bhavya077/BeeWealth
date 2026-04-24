import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:animate_do/animate_do.dart';
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

  Future<void> _handleRefresh() async {
    HapticFeedback.lightImpact();
    final trade = Provider.of<TradeProvider>(context, listen: false);
    await Future.wait([
      trade.connectWebSocket(),
      trade.fetchTodayOrders(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer<TradeProvider>(
        builder: (context, trade, _) {
          return RefreshIndicator(
            onRefresh: _handleRefresh,
            color: AppColors.primary,
            backgroundColor: AppColors.background,
            displacement: 40,
            edgeOffset: 20,
            strokeWidth: 2,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              slivers: [
                _buildModernAppBar(trade),
                if (trade.error != null && trade.positions.isEmpty && trade.closedOrders.isEmpty)
                  SliverFillRemaining(
                    child: _buildInstitutionalOffline(trade.error!),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _buildTitledSection('LIVE INVENTORY', Icons.sensors_rounded, trade.positions.length),
                        const SizedBox(height: 20),
                        _buildPositionsGrid(trade.positions),
                        const SizedBox(height: 48),
                        _buildTitledSection('TODAYS SETTLEMENT LOG', Icons.history_edu_rounded, trade.closedOrders.length),
                        const SizedBox(height: 20),
                        _buildOrdersLog(trade.closedOrders),
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

  Widget _buildModernAppBar(TradeProvider trade) {
    final isLive = trade.isConnected && trade.error == null;
    return SliverAppBar(
      expandedHeight: 120,
      collapsedHeight: 80,
      pinned: true,
      backgroundColor: AppColors.background,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(color: AppColors.background),
        titlePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'EXCHANGE',
                  style: TextStyle(color: Colors.white24, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 2),
                ),
                const Text(
                  'TERMINAL',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: (isLive ? AppColors.success : AppColors.error).withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: (isLive ? AppColors.success : AppColors.error).withOpacity(0.2), width: 0.5),
              ),
              child: Row(
                children: [
                  if (isLive) 
                    Pulse(
                      infinite: true,
                      child: Container(width: 4, height: 4, decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle)),
                    ),
                  const SizedBox(width: 6),
                  Text(
                    isLive ? 'LIVE FEED' : 'OFFLINE',
                    style: TextStyle(
                      color: isLive ? AppColors.success : AppColors.error,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitledSection(String title, IconData icon, int count) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 14),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2.5),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            count.toString().padLeft(2, '0'),
            style: const TextStyle(color: Colors.white24, fontSize: 9, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildPositionsGrid(List<Position> positions) {
    if (positions.isEmpty) {
      return FadeIn(
        child: GlassCard(
          height: 100,
          child: Center(
            child: Text(
              'NO ACTIVE MARKET EXPOSURE',
              style: TextStyle(color: Colors.white.withOpacity(0.1), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
            ),
          ),
        ),
      );
    }

    return Column(
      children: positions.asMap().entries.map((entry) {
        final index = entry.key;
        final p = entry.value;
        final isProfit = p.pnlPercentage >= 0;

        return FadeInRight(
          delay: Duration(milliseconds: 100 * index),
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: GlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.symbol.toUpperCase(),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 0.5),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Text('LTP ', style: TextStyle(color: Colors.white24, fontSize: 9, fontWeight: FontWeight.bold)),
                              Text(
                                '₹${p.ltp.toStringAsFixed(2)}',
                                style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.w900),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${isProfit ? '+' : ''}${p.pnlPercentage.toStringAsFixed(2)}%',
                            style: TextStyle(
                              color: isProfit ? AppColors.success : AppColors.error,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              shadows: [
                                Shadow(color: (isProfit ? AppColors.success : AppColors.error).withOpacity(0.3), blurRadius: 12),
                              ],
                            ),
                          ),
                          Text(
                            'UNREALIZED RETURN',
                            style: TextStyle(color: (isProfit ? AppColors.success : AppColors.error).withOpacity(0.3), fontSize: 7, fontWeight: FontWeight.w900, letterSpacing: 1),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildOrdersLog(List<PaperOrder> orders) {
    if (orders.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.02),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: const Center(child: Text('NO ARCHIVED SETTLEMENTS', style: TextStyle(color: Colors.white10, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2))),
      );
    }

    return Column(
      children: orders.asMap().entries.map((entry) {
        final index = entry.key;
        final o = entry.value;
        final isProfit = o.pnlPercentage >= 0;
        DateTime? entryDate;
        DateTime? exitDate;
        try { entryDate = DateTime.parse(o.entryTime); } catch (_) {}
        try { exitDate = DateTime.parse(o.exitTime); } catch (_) {}

        return FadeInLeft(
          delay: Duration(milliseconds: 50 * index),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(o.symbol.toUpperCase(), style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5)),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(3)),
                              child: const Text('SETTLED', style: TextStyle(color: Colors.white24, fontSize: 7, fontWeight: FontWeight.w900)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('EXECUTION', style: TextStyle(color: Colors.white10, fontSize: 7, fontWeight: FontWeight.w900)),
                                Text(entryDate != null ? DateFormat('HH:mm').format(entryDate) : '--:--', style: const TextStyle(color: Colors.white24, fontSize: 9, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(width: 24),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('SETTLEMENT', style: TextStyle(color: Colors.white10, fontSize: 7, fontWeight: FontWeight.w900)),
                                Text(exitDate != null ? DateFormat('HH:mm').format(exitDate) : '--:--', style: const TextStyle(color: Colors.white24, fontSize: 9, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${isProfit ? '+' : ''}${o.pnlPercentage.toStringAsFixed(2)}%',
                        style: TextStyle(
                          color: (isProfit ? AppColors.success : AppColors.error).withOpacity(0.5),
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                      const Text('NET RETURN', style: TextStyle(color: Colors.white10, fontSize: 7, fontWeight: FontWeight.w900)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInstitutionalOffline(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Pulse(
            infinite: true,
            child: Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.error.withOpacity(0.2)),
          ),
          const SizedBox(height: 24),
          const Text(
            'MARKET STATUS: OFFLINE',
            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 3),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 64),
            child: Text(
              message.toUpperCase(),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white24, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1),
            ),
          ),
          const SizedBox(height: 32),
          GestureDetector(
            onTap: () => Provider.of<TradeProvider>(context, listen: false).fetchTodayOrders(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text('RE-SYNC TERMINAL', style: TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
            ),
          ),
        ],
      ),
    );
  }
}
