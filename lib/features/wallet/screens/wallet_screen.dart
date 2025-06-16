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
              /// Title and notification icon
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
              const SizedBox(height: 20),

              /// Balance Card
              const BalanceCard(
                balance: 20918.52,
                phoneNumber: '0796247784',
                paymentMethod: 'Mpesa',
              ),
              const SizedBox(height: 20),

              /// Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ActionButtonCard(
                    icon: Icons.add,
                    title: 'Add',
                    onPressed: () {},
                    size: 36,
                  ),
                  ActionButtonCard(
                    icon: Icons.upload,
                    title: 'Release',
                    onPressed: () {},
                    size: 36,
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
                tabs: const [
                  Tab(text: 'Transactions'),
                  Tab(text: 'Pending'),
                  Tab(text: 'Statements'),
                ],
              ),

              /// Tab Content (make sure it has fixed height or wrap with SizedBox)
              SizedBox(
                height: 500, // or MediaQuery.of(context).size.height * 0.6
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
      padding: const EdgeInsets.all(16),
      itemCount: 5,
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
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Text(
          'You have no pending fund releases at the moment.',
          style: TextStyle(fontSize: 14, color: Colors.white70),
        ),
      ),
    );
  }

  Widget _buildStatementsTab() {
    return Padding(
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
