import 'package:flutter/material.dart';
import 'package:nisacleanv1/features/wallet/widgets/balance_card.dart';
import 'package:nisacleanv1/features/wallet/widgets/transaction_card.dart';
import 'package:nisacleanv1/features/wallet/widgets/action_button_card.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/wallet_service.dart';
import 'package:nisacleanv1/services/auth_service.dart';
import '../models/transaction.dart';
import 'package:intl/intl.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  double? _balance;
  bool _isBalanceLoading = true;
  String? _balanceError;

  List<Map<String, dynamic>> _transactions = [];
  bool _isTxLoading = true;
  String? _txError;

  String? _phoneNumber;
  bool _isProfileLoading = true;
  String? _profileError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchProfile();
    _fetchBalance();
    _fetchTransactions();
  }

  Future<void> _fetchProfile() async {
    setState(() {
      _isProfileLoading = true;
      _profileError = null;
    });
    try {
      final user = await AuthService().fetchUserProfile();
      if (!mounted) return;
      setState(() {
        _phoneNumber = user['phone'] ?? '';
        _isProfileLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _profileError = e.toString();
        _isProfileLoading = false;
      });
    }
  }

  Future<void> _fetchBalance() async {
    setState(() {
      _isBalanceLoading = true;
      _balanceError = null;
    });
    try {
      final token = await AuthService().getToken();
      if (token == null) throw 'Not authenticated';
      final balance = await WalletService().getBalance(token);
      if (!mounted) return;
      setState(() {
        _balance = balance;
        _isBalanceLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _balanceError = e.toString();
        _isBalanceLoading = false;
      });
    }
  }

  Future<void> _fetchTransactions() async {
    setState(() {
      _isTxLoading = true;
      _txError = null;
    });
    try {
      final token = await AuthService().getToken();
      if (token == null) throw 'Not authenticated';
      final txs = await WalletService().getTransactions(token);
      if (!mounted) return;
      setState(() {
        _transactions = txs;
        _isTxLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _txError = e.toString();
        _isTxLoading = false;
      });
    }
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
              if (_isBalanceLoading || _isProfileLoading)
                const Center(child: CircularProgressIndicator())
              else if (_balanceError != null || _profileError != null)
                Center(
                  child: Text(
                    _balanceError ?? _profileError!,
                    style: const TextStyle(color: Colors.red),
                  ),
                )
              else
                BalanceCard(
                  balance: _balance ?? 0.0,
                  phoneNumber: _phoneNumber ?? '-',
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
    if (_isTxLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (_txError != null) {
      return Center(child: Text(_txError!, style: TextStyle(color: Colors.red)));
    } else if (_transactions.isEmpty) {
      return Center(child: Text('No transactions found.', style: TextStyle(color: Colors.white70)));
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      itemCount: _transactions.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final tx = _transactions[index];
        return TransactionCard(
          title: tx['type'] == 'deposit' ? 'Deposit' : 'Withdrawal',
          amount: (tx['amount'] as num).toDouble(),
          date: tx['createdAt'] != null ? tx['createdAt'].toString().split('T').first : '',
          status: tx['status']?.toString().split('.').last ?? '-',
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