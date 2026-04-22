import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
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
        appBar: AppBar(
          title: const Text('Accounts & Ledger', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          bottom: TabBar(
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.white54,
            tabs: const [
              Tab(text: 'History'),
              Tab(text: 'Deposit'),
              Tab(text: 'Withdraw'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            LedgerHistoryTab(),
            DepositTab(),
            WithdrawTab(),
          ],
        ),
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
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        if (dashboard.ledgerEntries.isEmpty) {
          return const Center(child: Text('No transactions found', style: TextStyle(color: Colors.white24)));
        }

        return RefreshIndicator(
          onRefresh: () => dashboard.fetchLedger(),
          child: ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: dashboard.ledgerEntries.length,
            itemBuilder: (context, index) {
              final entry = dashboard.ledgerEntries[index];
              final isProfit = entry.amount >= 0;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: (isProfit ? AppColors.success : AppColors.error).withAlpha(20),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isProfit ? Icons.trending_up : Icons.trending_down,
                          color: isProfit ? AppColors.success : AppColors.error,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(entry.description, style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(
                              entry.date,
                              style: const TextStyle(color: Colors.white38, fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${isProfit ? '+' : ''}${currencyFormat.format(entry.amount)}',
                        style: TextStyle(
                          color: isProfit ? AppColors.success : AppColors.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
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
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Request New Deposit', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Amount',
                hint: '0.00',
                controller: _amountController,
                keyboardType: TextInputType.number,
                prefixIcon: Icons.add_moderator_outlined,
              ),
              const SizedBox(height: 16),
              CustomButton(
                text: 'APPLY DEPOSIT',
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
              const SizedBox(height: 32),
              const Text('Deposit History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white54)),
              const SizedBox(height: 12),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => dashboard.fetchInvestmentHistory(),
                  child: _buildRequestList(dashboard.investmentHistory),
                ),
              ),
            ],
          ),
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
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Request New Withdrawal', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Amount',
                hint: '0.00',
                controller: _amountController,
                keyboardType: TextInputType.number,
                prefixIcon: Icons.outbox_outlined,
              ),
              const SizedBox(height: 16),
              CustomButton(
                text: 'APPLY WITHDRAWAL',
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
              const SizedBox(height: 32),
              const Text('Withdrawal History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white54)),
              const SizedBox(height: 12),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => dashboard.fetchWithdrawalHistory(),
                  child: _buildRequestList(dashboard.withdrawalHistory),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

Widget _buildRequestList(List<FundRequest> requests) {
  if (requests.isEmpty) {
    return const Center(child: Text('No history found', style: TextStyle(color: Colors.white24)));
  }

  return ListView.builder(
    itemCount: requests.length,
    itemBuilder: (context, index) {
      final req = requests[index];
      Color statusColor = Colors.orange;
      if (req.status == 'completed' || req.status == 'approved') statusColor = AppColors.success;
      if (req.status == 'rejected') statusColor = AppColors.error;

      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        child: GlassCard(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('₹${req.amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      DateFormat('dd MMM, hh:mm a').format(req.requestedAt),
                      style: const TextStyle(color: Colors.white38, fontSize: 10),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withAlpha(50)),
                ),
                child: Text(
                  req.status.toUpperCase(),
                  style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
