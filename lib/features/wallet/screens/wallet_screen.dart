import 'package:flutter/material.dart';
import 'package:nisacleanv1/features/wallet/widgets/balance_card.dart';
import 'package:nisacleanv1/features/wallet/widgets/transaction_card.dart';
import 'package:nisacleanv1/features/wallet/widgets/action_button_card.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen>
    with TickerProviderStateMixin {
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
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'My Wallet',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.notifications_none,
                      color: Colors.white,
                    ),
                    onPressed: () {},
                  ),
                ],
              ),
              const SizedBox(height: 12),

              /// Balance Card
              const BalanceCard(
                balance: 20918.52,
                phoneNumber: '0796247784',
                paymentMethod: 'Mpesa',
              ),
              const SizedBox(height: 16),

              /// Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ActionButtonCard(
                    icon: Icons.add,
                    title: 'Add',
                    onPressed: () {},
                    size: 28,
                    fontSize: 12,
                  ),
                  ActionButtonCard(
                    icon: Icons.upload,
                    title: 'Release',
                    onPressed: () {},
                    size: 28,
                    fontSize: 12,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              /// Tabs
              TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey,
                labelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                tabs: const [
                  Tab(text: 'Transactions'),
                  Tab(text: 'Pending'),
                  Tab(text: 'Statements'),
                ],
              ),
              const SizedBox(height: 16),

              /// TabBarView with shrink-wrapped height
              SizedBox(
                height:
                    MediaQuery.of(context).size.height *
                    0.6, // Adjust as needed
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
      ),
    );
  }

  Widget _buildTransactionsTab() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      itemCount: 10,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return TransactionCard(
          title: index % 2 == 0 ? 'Deposit' : 'Withdrawal',
          amount: index % 2 == 0 ? 490.0 : -300.0,
          date: '2025-06-${index + 1}',
          status: 'completed',
        );
      },
    );
  }

  Widget _buildPendingTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: SizedBox(
        height: 200,
        child: Center(
          child: Text(
            'You have no pending fund releases at the moment.',
            style: TextStyle(fontSize: 14, color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildStatementsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16),
      child: Column(
        children: [
          const Text(
            "Export your full transaction history.",
            style: TextStyle(fontSize: 14, color: Colors.white70),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[900],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            onPressed: () {},
            icon: const Icon(Icons.download),
            label: const Text('Export Statement'),
          ),
        ],
      ),
    );
  }
}
