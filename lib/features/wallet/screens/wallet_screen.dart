import 'package:flutter/material.dart';
import 'package:nisacleanv1/features/wallet/widgets/transaction_card.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFF181A20),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Wallet', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
          child: Column(
            children: [
            // Balance
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 8),
              child: Column(
                children: [
                  const Text(
                    'Balance',
                    style: TextStyle(color: Colors.white54, fontSize: 15, fontWeight: FontWeight.w400),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'KES 20,918.52',
                    style: theme.textTheme.displaySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '0796247784',
                    style: const TextStyle(color: Colors.white38, fontSize: 14),
                    ),
                  TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.primary,
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(40, 24),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Edit', style: TextStyle(fontSize: 13)),
                  ),
                ],
              ),
            ),
            // Action Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _MinimalActionButton(
                    icon: Icons.add,
                    label: 'Deposit',
                    onTap: () {},
                  ),
                  _MinimalActionButton(
                    icon: Icons.arrow_upward,
                    label: 'Withdraw',
                    onTap: () {},
                  ),
                  _MinimalActionButton(
                    icon: Icons.compare_arrows,
                    label: 'Transfer',
                    onTap: () {},
                  ),
                ],
              ),
            ),
            // Tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(12),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white54,
                labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                tabs: const [
                  Tab(text: 'Transactions'),
                  Tab(text: 'Pending'),
                  Tab(text: 'Statements'),
                ],
              ),
            ),
            // TabBarView
            Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTransactionsTab(),
                    _buildPendingTab(),
                    _buildStatementsTab(),
                  ],
                ),
              ),
            ],
        ),
      ),
    );
  }

  Widget _buildTransactionsTab() {
    final transactions = List.generate(8, (i) => i);
    if (transactions.isEmpty) {
      return _MinimalEmptyState(
        icon: Icons.receipt_long_rounded,
        message: 'No transactions yet',
        subMessage: 'Your recent wallet activity will appear here.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: transactions.length,
      separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.white12),
      itemBuilder: (context, index) {
        return _MinimalTransactionCard(
          title: index % 2 == 0 ? 'Deposit' : 'Withdrawal',
          amount: index % 2 == 0 ? 490.0 : -300.0,
          date: '2025-06-${index + 1}',
          status: 'completed',
        );
      },
    );
  }

  Widget _buildPendingTab() {
    return _MinimalEmptyState(
      icon: Icons.hourglass_empty_rounded,
      message: 'No pending releases',
      subMessage: 'You have no pending fund releases at the moment.',
    );
  }

  Widget _buildStatementsTab() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
          mainAxisSize: MainAxisSize.min,
        children: [
            Icon(Icons.download_rounded, color: Colors.blue[300], size: 48),
            const SizedBox(height: 16),
          const Text(
              'Export your full transaction history.',
              style: TextStyle(fontSize: 15, color: Colors.white70),
              textAlign: TextAlign.center,
          ),
            const SizedBox(height: 18),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white10,
              foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
            ),
            onPressed: () {},
            icon: const Icon(Icons.download),
            label: const Text('Export Statement'),
          ),
        ],
        ),
      ),
    );
  }
}

class _MinimalActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _MinimalActionButton({required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: Colors.white10,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
      ],
    );
  }
}

class _MinimalTransactionCard extends StatelessWidget {
  final String title;
  final double amount;
  final String date;
  final String status;
  const _MinimalTransactionCard({required this.title, required this.amount, required this.date, required this.status});
  @override
  Widget build(BuildContext context) {
    final isPositive = amount >= 0;
    final color = isPositive ? Colors.greenAccent.shade400 : Colors.redAccent.shade200;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 2, horizontal: 0),
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.13),
        child: Icon(isPositive ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded, color: color, size: 22),
      ),
      title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      subtitle: Text(date, style: const TextStyle(color: Colors.white54, fontSize: 13)),
      trailing: Text(
        (isPositive ? '+' : '-') + 'KES ${amount.abs().toStringAsFixed(2)}',
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15),
      ),
    );
  }
}

class _MinimalEmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String subMessage;
  const _MinimalEmptyState({required this.icon, required this.message, required this.subMessage});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 56, color: Colors.white24),
            const SizedBox(height: 18),
            Text(
              message,
              style: const TextStyle(fontSize: 17, color: Colors.white, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subMessage,
              style: const TextStyle(fontSize: 14, color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
