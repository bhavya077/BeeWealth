import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:animate_do/animate_do.dart';
import '../../providers/dashboard_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/app_widgets.dart';
import '../../models/app_models.dart';

class LedgerScreen extends StatefulWidget {
  const LedgerScreen({super.key});

  @override
  State<LedgerScreen> createState() => _LedgerScreenState();
}

class _LedgerScreenState extends State<LedgerScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            // Background Accent
            Positioned(
              top: -100,
              right: -50,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [AppColors.primary.withOpacity(0.08), Colors.transparent],
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 8),
                  _buildTabBar(),
                  const Expanded(
                    child: TabBarView(
                      children: [
                        LedgerHistoryTab(),
                        DepositTab(),
                        WithdrawTab(),
                      ],
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

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.account_balance_outlined, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 16),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'LEDGER',
                style: TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.w800),
              ),
              Text(
                'Accounts & Assets',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
      ),
      child: TabBar(
        indicator: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.black,
        unselectedLabelColor: Colors.white38,
        labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
        tabs: const [
          Tab(text: 'ACTIVITY'),
          Tab(text: 'DEPOSIT'),
          Tab(text: 'WITHDRAW'),
        ],
      ),
    );
  }
}

class LedgerHistoryTab extends StatefulWidget {
  const LedgerHistoryTab({super.key});

  @override
  State<LedgerHistoryTab> createState() => _LedgerHistoryTabState();
}

class _LedgerHistoryTabState extends State<LedgerHistoryTab> {
  final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DashboardProvider>(context, listen: false).fetchLedger();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardProvider>(
      builder: (context, dashboard, _) {
        if (dashboard.isLoading && dashboard.ledgerEntries.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2));
        }

        if (dashboard.ledgerEntries.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history_toggle_off, color: Colors.white.withOpacity(0.05), size: 64),
                const SizedBox(height: 16),
                const Text('No recent activity found', style: TextStyle(color: Colors.white24, fontSize: 12)),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => dashboard.fetchLedger(),
          backgroundColor: AppColors.primary,
          color: Colors.black,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            itemCount: dashboard.ledgerEntries.length + 1,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              if (index == dashboard.ledgerEntries.length) {
                return const BrandedFooter();
              }
              final entry = dashboard.ledgerEntries[index];
              final isCredit = entry.amount >= 0;
              
              return FadeInUp(
                duration: Duration(milliseconds: 300 + (index * 50)),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: GlassCard(
                    padding: const EdgeInsets.all(16),
                    borderRadius: BorderRadius.circular(20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: (isCredit ? AppColors.success : AppColors.error).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            isCredit ? Icons.add_circle_outline : Icons.remove_circle_outline,
                            color: isCredit ? AppColors.success : AppColors.error,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.description,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                entry.date,
                                style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 10, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${isCredit ? '+' : ''}${currencyFormat.format(isCredit ? entry.amount : -entry.amount)}',
                              style: TextStyle(
                                color: isCredit ? AppColors.success : AppColors.error,
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                              ),
                            ),
                            const Text(
                              'COMPLETED',
                              style: TextStyle(color: Colors.white12, fontSize: 8, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class DepositTab extends StatefulWidget {
  const DepositTab({super.key});

  @override
  State<DepositTab> createState() => _DepositTabState();
}

class _DepositTabState extends State<DepositTab> {
  final _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DashboardProvider>(context, listen: false).fetchInvestmentHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardProvider>(
      builder: (context, dashboard, _) {
        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('ORDER ENTRY', style: TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 16),
                    GlassCard(
                      padding: const EdgeInsets.all(24),
                      borderRadius: BorderRadius.circular(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Deposit Amount', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 12),
                          CustomTextField(
                            label: '',
                            hint: 'Enter Amount in ₹',
                            controller: _amountController,
                            keyboardType: TextInputType.number,
                            prefixIcon: Icons.account_balance_wallet_outlined,
                          ),
                          const SizedBox(height: 24),
                          CustomButton(
                            text: 'EXECUTE DEPOSIT',
                            isLoading: dashboard.isLoading && _amountController.text.isNotEmpty,
                            onPressed: () async {
                              final amount = double.tryParse(_amountController.text) ?? 0;
                              if (amount > 0) {
                                final success = await dashboard.requestInvestment(amount);
                                if (mounted) {
                                  _amountController.clear();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(success ? 'Deposit request submitted' : 'Failed to submit request')),
                                  );
                                }
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('REQUEST HISTORY', style: TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.w800)),
                        Icon(Icons.history_outlined, color: Colors.white12, size: 16),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: _buildRequestSliverList(dashboard.investmentHistory),
            ),
            const SliverToBoxAdapter(
              child: BrandedFooter(),
            ),
          ],
        );
      },
    );
  }
}

class WithdrawTab extends StatefulWidget {
  const WithdrawTab({super.key});

  @override
  State<WithdrawTab> createState() => _WithdrawTabState();
}

class _WithdrawTabState extends State<WithdrawTab> {
  final _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DashboardProvider>(context, listen: false).fetchWithdrawalHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardProvider>(
      builder: (context, dashboard, _) {
        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('ORDER ENTRY', style: TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 16),
                    GlassCard(
                      padding: const EdgeInsets.all(24),
                      borderRadius: BorderRadius.circular(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Withdrawal Amount', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 12),
                          CustomTextField(
                            label: '',
                            hint: 'Enter Amount in ₹',
                            controller: _amountController,
                            keyboardType: TextInputType.number,
                            prefixIcon: Icons.north_east_rounded,
                          ),
                          const SizedBox(height: 24),
                          CustomButton(
                            text: 'EXECUTE WITHDRAWAL',
                            isLoading: dashboard.isLoading && _amountController.text.isNotEmpty,
                            onPressed: () async {
                              final amount = double.tryParse(_amountController.text) ?? 0;
                              if (amount > 0) {
                                final success = await dashboard.requestWithdrawal(amount);
                                if (mounted) {
                                  _amountController.clear();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(success ? 'Withdrawal request submitted' : 'Failed to submit request')),
                                  );
                                }
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('REQUEST HISTORY', style: TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.w800)),
                        Icon(Icons.history_outlined, color: Colors.white12, size: 16),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: _buildRequestSliverList(dashboard.withdrawalHistory),
            ),
            const SliverToBoxAdapter(
              child: BrandedFooter(),
            ),
          ],
        );
      },
    );
  }
}

Widget _buildRequestSliverList(List<FundRequest> requests) {
  if (requests.isEmpty) {
    return SliverToBoxAdapter(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text('No history found', style: TextStyle(color: Colors.white.withOpacity(0.1), fontSize: 12)),
        ),
      ),
    );
  }

  return SliverList(
    delegate: SliverChildBuilderDelegate(
      (context, index) {
        final req = requests[index];
        Color statusColor = Colors.orange;
        IconData statusIcon = Icons.pending_actions;
        if (req.status == 'completed' || req.status == 'approved') {
          statusColor = AppColors.success;
          statusIcon = Icons.check_circle_outline;
        }
        if (req.status == 'rejected') {
          statusColor = AppColors.error;
          statusIcon = Icons.cancel_outlined;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: GlassCard(
            padding: const EdgeInsets.all(16),
            borderRadius: BorderRadius.circular(18),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '₹${NumberFormat('#,##,###.##').format(req.amount)}',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('dd MMM yyyy, hh:mm a').format(req.requestedAt),
                        style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 10, fontWeight: FontWeight.w600),
                      ),
                      if (req.adminNote.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.03),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.speaker_notes_outlined, color: Colors.white24, size: 10),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  req.adminNote,
                                  style: const TextStyle(color: Colors.white38, fontSize: 10, fontStyle: FontStyle.italic),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: statusColor.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, color: statusColor, size: 12),
                      const SizedBox(width: 6),
                      Text(
                        req.status.toUpperCase(),
                        style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
      childCount: requests.length,
    ),
  );
}
