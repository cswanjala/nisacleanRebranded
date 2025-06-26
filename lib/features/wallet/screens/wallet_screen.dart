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
import 'package:badges/badges.dart' as badges;
import 'package:shimmer/shimmer.dart';
import 'package:lottie/lottie.dart';
import 'dart:ui';

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
  String? _userName;
  bool _isProfileLoading = true;
  String? _profileError;
  bool _showBalance = false;
  int _pendingCount = 0;
  int _txCount = 0;

  String _selectedType = 'All';
  final List<String> _types = ['All', 'Deposit', 'Escrow'];

  bool _isDepositing = false;

  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchAll();
  }

  Future<void> _fetchAll() async {
    await Future.wait([
      _fetchProfile(),
      _fetchBalance(),
      _fetchTransactions(),
    ]);
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
        _userName = user['name'] ?? '';
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
        _txCount = txs.length;
        _pendingCount = txs.where((tx) => tx['status'] == 'pending').length;
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
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: colorScheme.background,
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: colorScheme.primary,
        child: ListView(
          children: [
            _buildModernAppBar(context),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAnimatedBalanceCard(colorScheme),
                  const SizedBox(height: 18),
                  _buildActionRow(colorScheme),
                  const SizedBox(height: 22),
                  _buildTabs(colorScheme),
                  const SizedBox(height: 18),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildTransactionsTab(colorScheme),
                        _buildPendingTab(colorScheme),
                        _buildStatementsTab(colorScheme),
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

  Widget _buildModernAppBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final greeting = _userName != null ? _getGreeting() : 'Welcome!';
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 18),
      child: Stack(
        children: [
          // Glassmorphism background
          ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                height: 110,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.white.withOpacity(0.12), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withOpacity(0.10),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Decorative icon background
          Positioned(
            right: -10,
            bottom: -10,
            child: Icon(
              Icons.account_balance_wallet,
              size: 100,
              color: colorScheme.primary.withOpacity(0.08),
            ),
          ),
          // Main content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar with border and shadow
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withOpacity(0.18),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: _userName != null
                        ? Text(
                            _userName!.substring(0, 1),
                            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                          )
                        : const Icon(Icons.account_circle, color: Colors.white, size: 28),
                  ),
                ),
                const SizedBox(width: 18),
                // Animated greeting and name
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedOpacity(
                        opacity: 1.0,
                        duration: const Duration(milliseconds: 700),
                        child: Text(
                          greeting,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.92),
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      AnimatedOpacity(
                        opacity: 1.0,
                        duration: const Duration(milliseconds: 900),
                        child: Text(
                          _userName ?? 'User',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Notification bell with animated badge
                Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_none, color: Colors.white, size: 28),
                      onPressed: () {},
                    ),
                    if (_pendingCount > 0)
                      AnimatedOpacity(
                        opacity: _pendingCount > 0 ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 500),
                        child: Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              _pendingCount.toString(),
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  Widget _buildAnimatedBalanceCard(ColorScheme colorScheme) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showBalance = !_showBalance;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        child: _isBalanceLoading || _isProfileLoading
            ? Shimmer.fromColors(
                baseColor: colorScheme.surface,
                highlightColor: colorScheme.primary.withOpacity(0.1),
                child: Container(
                  height: 100,
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  margin: const EdgeInsets.symmetric(vertical: 4),
                ),
              )
            : _balanceError != null || _profileError != null
                ? Container(
                    height: 100,
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: _buildLottieError(_balanceError ?? _profileError!),
                    ),
                  )
                : Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.primary,
                          colorScheme.primary.withOpacity(0.9),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 28),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              Icons.account_balance_wallet,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Available Balance',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white.withOpacity(0.9),
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 400),
                                  child: _showBalance
                                      ? Text(
                                          'KES ${NumberFormat('#,##0.00').format(_balance ?? 0.0)}',
                                          key: const ValueKey('balance'),
                                          style: const TextStyle(
                                            fontSize: 26,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            letterSpacing: -0.5,
                                          ),
                                        )
                                      : Container(
                                          key: const ValueKey('hidden'),
                                          height: 32,
                                          width: 140,
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _showBalance ? Icons.visibility : Icons.visibility_off,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }

  Widget _buildActionRow(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.mobile_friendly, size: 18),
              label: const Text('Deposit'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
                shadowColor: colorScheme.primary.withOpacity(0.3),
              ),
              onPressed: _isDepositing ? null : _showDepositBottomSheet,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(
                Icons.history,
                color: colorScheme.primary,
                size: 20,
              ),
              onPressed: () {
                // TODO: Navigate to transaction history
              },
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(
                Icons.help_outline,
                color: colorScheme.primary,
                size: 20,
              ),
              onPressed: () {
                // TODO: Show help/support
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showDepositBottomSheet() async {
    final colorScheme = Theme.of(context).colorScheme;
    final controller = TextEditingController();
    bool isLoading = false;
    String? errorMsg;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.only(
                  left: 24, right: 24,
                  top: 24,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40, height: 4,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.mobile_friendly,
                            color: colorScheme.primary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Deposit to Mpesa',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              Text(
                                'Add funds to your wallet',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: colorScheme.onSurface.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Amount (KES)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: controller,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        hintText: 'Enter amount (e.g., 1000)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.3)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.3)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: colorScheme.primary, width: 2),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: colorScheme.error),
                        ),
                        filled: true,
                        fillColor: colorScheme.surface,
                        prefixIcon: Icon(
                          Icons.attach_money,
                          color: colorScheme.primary,
                        ),
                        errorText: errorMsg,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: isLoading
                            ? null
                            : () async {
                                final value = double.tryParse(controller.text);
                                if (value == null || value <= 0) {
                                  setModalState(() => errorMsg = 'Enter a valid amount');
                                  return;
                                }
                                setModalState(() {
                                  isLoading = true;
                                  errorMsg = null;
                                });
                                final result = await _depositToMpesaModal(value, ctx, setModalState);
                                if (result) Navigator.pop(ctx);
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: Colors.white,
                          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                          shadowColor: colorScheme.primary.withOpacity(0.3),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text('Deposit Now'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<bool> _depositToMpesaModal(double amount, BuildContext ctx, void Function(void Function()) setModalState) async {
    setModalState(() => _isDepositing = true);
    final colorScheme = Theme.of(context).colorScheme;
    try {
      final token = await AuthService().getToken();
      if (token == null) throw 'Not authenticated';
      final phone = _phoneNumber;
      if (phone == null || phone.isEmpty) throw 'Phone number not found.';
      final response = await http.post(
        Uri.parse('${WalletService().baseUrl}/transaction/deposit/request'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'phone': phone,
          'amount': amount,
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        final customerMsg = data['data']?['stkResponse']?['CustomerMessage'] ?? data['message'] ?? 'Deposit initiated.';
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Lottie.network('https://assets2.lottiefiles.com/packages/lf20_jtbfg2nb.json', width: 80, height: 80, repeat: false),
                const SizedBox(height: 12),
                Text(customerMsg, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        _fetchBalance();
        _fetchTransactions();
        return true;
      } else {
        final msg = data['message'] ?? 'Failed to deposit.';
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
                  children: [
                Lottie.network('https://assets2.lottiefiles.com/packages/lf20_jtbfg2nb.json', width: 80, height: 80, repeat: false),
                const SizedBox(height: 12),
                Text(msg, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.red)),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        setModalState(() => _isDepositing = false);
        return false;
      }
    } catch (e) {
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Lottie.network('https://assets2.lottiefiles.com/packages/lf20_jtbfg2nb.json', width: 80, height: 80, repeat: false),
              const SizedBox(height: 12),
              Text('Error: $e', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.red)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      setModalState(() => _isDepositing = false);
      return false;
    }
  }

  Widget _buildTabs(ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicatorColor: colorScheme.primary,
        indicatorWeight: 3,
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: colorScheme.primary,
        unselectedLabelColor: colorScheme.onSurface.withOpacity(0.6),
        labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        dividerColor: Colors.transparent,
        tabs: [
          badges.Badge(
            showBadge: _txCount > 0,
            badgeContent: Text(
              _txCount.toString(),
              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
            ),
            badgeStyle: badges.BadgeStyle(
              badgeColor: colorScheme.primary,
              padding: const EdgeInsets.all(4),
            ),
            child: const Tab(text: 'Transactions'),
          ),
          badges.Badge(
            showBadge: _pendingCount > 0,
            badgeContent: Text(
              _pendingCount.toString(),
              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
            ),
            badgeStyle: badges.BadgeStyle(
              badgeColor: Colors.orange,
              padding: const EdgeInsets.all(4),
            ),
            child: const Tab(text: 'Pending'),
          ),
          const Tab(text: 'Statements'),
        ],
      ),
    );
  }

  Widget _buildTransactionsTab(ColorScheme colorScheme) {
    if (_isTxLoading) {
      // Shimmer loading for transaction list
      return ListView.builder(
        itemCount: 4,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        itemBuilder: (context, index) => Shimmer.fromColors(
          baseColor: colorScheme.surface,
          highlightColor: colorScheme.primary.withOpacity(0.1),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            height: 72,
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      );
    } else if (_txError != null) {
      return _buildLottieError(_txError!);
    } else if (_transactions.isEmpty) {
      return _buildLottieEmpty('No transactions found.');
    }

    // --- Filter UI ---
    final filteredTxs = _transactions.where((tx) {
      final matchesType = _selectedType == 'All' ||
          (_selectedType == 'Deposit' && tx['type'] == 'deposit') ||
          (_selectedType == 'Escrow' && tx['type'] == 'escrow');
      final matchesDate = _selectedDate == null ||
        (() {
          final createdAt = tx['createdAt']?.toString();
          if (createdAt == null) return false;
          final txDate = DateTime.tryParse(createdAt);
          if (txDate == null) return false;
          return txDate.year == _selectedDate!.year && txDate.month == _selectedDate!.month && txDate.day == _selectedDate!.day;
        })();
      // Only show outgoing transactions (debit), exclude incoming transactions (credit)
      final isOutgoing = tx['direction'] == 'debit';
      return matchesType && matchesDate && isOutgoing;
    }).toList();

    // Group filtered transactions by date
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final tx in filteredTxs) {
      final date = tx['createdAt']?.toString().split('T').first ?? '-';
      grouped.putIfAbsent(date, () => []).add(tx);
    }

    return Column(
      children: [
        // Filter Chips Row (Type chips + Date chip at the end)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _types.length + 1, // +1 for date chip at the end
              separatorBuilder: (context, i) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                if (i < _types.length) {
                  final type = _types[i];
                  final isSelected = _selectedType == type;
                  return ChoiceChip(
                    label: Text(type),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() {
                        _selectedType = type;
                      });
                    },
                    selectedColor: colorScheme.primary,
                    backgroundColor: colorScheme.surface,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  );
                } else {
                  // Date chip at the end
                  if (_selectedDate == null) {
                    return ActionChip(
                      avatar: const Icon(Icons.calendar_today, size: 18),
                      label: const Text('Date'),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setState(() {
                            _selectedDate = picked;
                          });
                        }
                      },
                      backgroundColor: colorScheme.surface,
                      labelStyle: TextStyle(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  } else {
                    return ChoiceChip(
                      avatar: const Icon(Icons.calendar_today, size: 18),
                      label: Text(DateFormat('d MMM yyyy').format(_selectedDate!)),
                      selected: true,
                      onSelected: (_) {
                        setState(() {
                          _selectedDate = null;
                        });
                      },
                      selectedColor: colorScheme.primary,
                      backgroundColor: colorScheme.primary.withOpacity(0.1),
                      labelStyle: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  }
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Transaction List
        Expanded(
          child: filteredTxs.isEmpty
              ? _buildLottieEmpty('No transactions found for your filter.')
              : ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
                  children: grouped.entries.map((entry) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                          child: Text(
                            _formatDate(entry.key),
                            style: TextStyle(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        ...entry.value.map((tx) => _buildTransactionCard(tx, colorScheme)).toList(),
                      ],
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> tx, ColorScheme colorScheme) {
    final direction = tx['direction']?.toString();
    final isCredit = direction == 'credit';
    final isDebit = direction == 'debit';
    final amount = (tx['amount'] as num).toDouble();
    final status = tx['status']?.toString().split('.').last ?? '-';
    final paidTo = tx['paidTo']?['name'];
    final paidBy = tx['paidBy']?['name'];
    String? partyLabel;
    if (isDebit && paidTo != null) {
      partyLabel = 'To: $paidTo';
    } else if (isCredit && paidBy != null) {
      partyLabel = 'From: $paidBy';
    }
    final type = tx['type']?.toString();
    String title = type != null ? type[0].toUpperCase() + type.substring(1) : 'Transaction';
    
    // Status color mapping
    Color statusColor;
    switch (status.toLowerCase()) {
      case 'completed':
        statusColor = Colors.green;
        break;
      case 'pending':
        statusColor = Colors.orange;
        break;
      case 'failed':
        statusColor = Colors.red;
        break;
      default:
        statusColor = colorScheme.primary;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isCredit 
                  ? Colors.green.withOpacity(0.15) 
                  : Colors.red.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                color: isCredit ? Colors.green : Colors.red,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                      fontSize: 15,
                    ),
                  ),
                  if (partyLabel != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      partyLabel,
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurface.withOpacity(0.7),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(tx['createdAt']),
                    style: TextStyle(
                      color: colorScheme.onSurface.withOpacity(0.6),
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  (isCredit ? '+' : '-') + 'KES ' + NumberFormat('#,##0.00').format(amount),
                  style: TextStyle(
                    color: isCredit ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: statusColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingTab(ColorScheme colorScheme) {
    final pendingTxs = _transactions.where((tx) => tx['status'] == 'pending').toList();
    if (_isTxLoading) {
      return ListView.builder(
        itemCount: 2,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        itemBuilder: (context, index) => Shimmer.fromColors(
          baseColor: colorScheme.surface,
          highlightColor: colorScheme.primary.withOpacity(0.1),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            height: 72,
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      );
    } else if (_txError != null) {
      return _buildLottieError(_txError!);
    } else if (pendingTxs.isEmpty) {
      return _buildLottieEmpty('You have no pending fund releases at the moment.');
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      itemCount: pendingTxs.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final tx = pendingTxs[index];
        return _buildTransactionCard(tx, colorScheme);
      },
    );
  }

  Widget _buildStatementsTab(ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 16),
      child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
        children: [
            Lottie.network(
              'https://assets2.lottiefiles.com/packages/lf20_0yfsb3a1.json',
              width: 80,
              height: 80,
              repeat: true,
            ),
            const SizedBox(height: 16),
            Text(
            "Export your full transaction history.",
              style: TextStyle(fontSize: 15, color: colorScheme.onSurface.withOpacity(0.7)),
          ),
            const SizedBox(height: 18),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
              foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  Widget _buildLottieEmpty(String message) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.network(
              'https://assets2.lottiefiles.com/packages/lf20_0yfsb3a1.json',
              width: 120,
              height: 120,
              repeat: true,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(fontSize: 15, color: colorScheme.onSurface.withOpacity(0.7)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLottieError(String error) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.network(
              'https://assets2.lottiefiles.com/packages/lf20_jtbfg2nb.json',
              width: 100,
              height: 100,
              repeat: false,
            ),
            const SizedBox(height: 16),
            Text(
              'Error',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(fontSize: 14, color: Colors.red.withOpacity(0.7)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String date) {
    final now = DateTime.now();
    final txDate = DateTime.tryParse(date);
    if (txDate == null) return date;
    if (txDate.year == now.year && txDate.month == now.month && txDate.day == now.day) {
      return 'Today';
    } else if (txDate.year == now.year && txDate.month == now.month && txDate.day == now.day - 1) {
      return 'Yesterday';
    } else {
      return DateFormat('d MMM yyyy').format(txDate);
    }
  }

  String _formatTime(dynamic dateTime) {
    if (dateTime == null) return '';
    final dt = DateTime.tryParse(dateTime.toString());
    if (dt == null) return '';
    return DateFormat('h:mm a').format(dt);
  }

  Future<void> _onRefresh() async {
    await _fetchAll();
  }
}

class _AnimatedSection extends StatelessWidget {
  final Widget child;
  const _AnimatedSection({required this.child});
  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}