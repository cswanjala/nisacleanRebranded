import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nisacleanv1/core/constants/api_constants.dart';

class WorkerEarningsScreen extends StatefulWidget {
  const WorkerEarningsScreen({super.key});

  @override
  State<WorkerEarningsScreen> createState() => _WorkerEarningsScreenState();
}

class _WorkerEarningsScreenState extends State<WorkerEarningsScreen> {
  Map<String, dynamic>? _earningsData;
  bool _isLoading = true;
  String? _error;
  DateTime? _selectedDate;
  List<Map<String, dynamic>> _transactions = [];
  bool _isTransactionsLoading = true;
  String? _transactionsError;

  @override
  void initState() {
    super.initState();
    _fetchEarnings();
    _fetchTransactions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          'My Earnings',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today, color: Colors.white70),
            onPressed: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _selectedDate ?? DateTime.now(),
                firstDate: DateTime(2024),
                lastDate: DateTime.now(),
              );
              if (date != null) {
                _fetchEarnings(date: date);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: () {
              _fetchEarnings();
              _fetchTransactions();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red.withOpacity(0.7),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading earnings',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.red.withOpacity(0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => _fetchEarnings(),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    await _fetchEarnings();
                    await _fetchTransactions();
                  },
                  color: Theme.of(context).colorScheme.primary,
                  backgroundColor: const Color(0xFF2A2A2A),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildEarningsHeader(context),
                        const SizedBox(height: 24),
                        _buildEarningsSummary(context),
                        const SizedBox(height: 24),
                        _buildEarningsHistory(context),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildEarningsHeader(BuildContext context) {
    final totalEarnings = _earningsData?['total']?['earnings'] ?? 0;
    final todayEarnings = _earningsData?['today']?['earnings'] ?? 0;
    final todayPercentage = _earningsData?['today']?['percentageChange'] ?? 0.0;
    final thisWeekEarnings = _earningsData?['thisWeek']?['earnings'] ?? 0;
    final thisWeekPercentage = _earningsData?['thisWeek']?['percentageChange'] ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withOpacity(0.8),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_selectedDate != null) ...[
            Row(
              children: [
                IconButton(
                  onPressed: () => _fetchEarnings(),
                  icon: const Icon(Icons.close, color: Colors.white70),
                  iconSize: 20,
                ),
                Expanded(
                  child: Text(
                    'Earnings for ${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Earnings',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'KES ${totalEarnings.toStringAsFixed(0)}',
                      style: GoogleFonts.poppins(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.trending_up,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: _buildEarningsCard(
                  'Today',
                  'KES ${todayEarnings.toStringAsFixed(0)}',
                  Icons.today,
                  Colors.white,
                  '${todayPercentage >= 0 ? '+' : ''}${todayPercentage.toStringAsFixed(1)}%',
                  todayPercentage >= 0 ? Colors.green : Colors.red,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildEarningsCard(
                  'This Week',
                  'KES ${thisWeekEarnings.toStringAsFixed(0)}',
                  Icons.calendar_today,
                  Colors.white,
                  '${thisWeekPercentage >= 0 ? '+' : ''}${thisWeekPercentage.toStringAsFixed(1)}%',
                  thisWeekPercentage >= 0 ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsSummary(BuildContext context) {
    final thisMonthEarnings = _earningsData?['thisMonth']?['earnings'] ?? 0;
    final thisMonthPercentage = _earningsData?['thisMonth']?['percentageChange'] ?? 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Performance',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  // TODO: Show performance details
                },
                icon: const Icon(Icons.analytics_outlined),
                label: const Text('Details'),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildEarningsCard(
                  'This Month',
                  'KES ${thisMonthEarnings.toStringAsFixed(0)}',
                  Icons.calendar_month,
                  Theme.of(context).colorScheme.primary,
                  '${thisMonthPercentage >= 0 ? '+' : ''}${thisMonthPercentage.toStringAsFixed(1)}%',
                  thisMonthPercentage >= 0 ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsCard(
    String title,
    String amount,
    IconData icon,
    Color iconColor,
    String trend,
    Color trendColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: trendColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  trend,
                  style: GoogleFonts.poppins(
                    color: trendColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            amount,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsHistory(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Transactions',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              TextButton(
                onPressed: () {
                  // TODO: Navigate to all transactions
                },
                child: Text(
                  'View All',
                  style: GoogleFonts.poppins(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isTransactionsLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
              ),
            )
          else if (_transactionsError != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red.withOpacity(0.7),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading transactions',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _transactionsError!,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.red.withOpacity(0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _fetchTransactions,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (_transactions.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(
                      Icons.receipt_long,
                      size: 48,
                      color: Colors.white.withOpacity(0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No transactions found',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your recent transactions will appear here',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.white54,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _transactions.length > 5 ? 5 : _transactions.length,
              itemBuilder: (context, index) {
                final transaction = _transactions[index];
                final amount = (transaction['amount'] as num?)?.toDouble() ?? 0.0;
                final type = transaction['type']?.toString() ?? '';
                final direction = transaction['direction']?.toString() ?? '';
                final status = transaction['status']?.toString() ?? '';
                final createdAt = transaction['createdAt']?.toString() ?? '';
                final notes = transaction['notes']?.toString() ?? '';
                final booking = transaction['booking']?.toString() ?? '';
                
                // Parse date
                String formattedDate = '';
                if (createdAt.isNotEmpty) {
                  try {
                    final date = DateTime.parse(createdAt);
                    formattedDate = '${date.day}/${date.month}/${date.year}';
                  } catch (e) {
                    formattedDate = createdAt.split('T').first;
                  }
                }

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 0,
                  color: const Color(0xFF2A2A2A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _getWorkerTransactionIconColor(type, direction).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _getWorkerTransactionIcon(type, direction),
                            color: _getWorkerTransactionIconColor(type, direction),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getWorkerTransactionTitle(type, direction),
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 15,
                                  color: Colors.white,
                                ),
                              ),
                              if (notes.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  notes,
                                  style: GoogleFonts.poppins(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                              if (booking.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  'Booking: $booking',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white54,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 2),
                              Text(
                                formattedDate,
                                style: GoogleFonts.poppins(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'KES ${amount.toStringAsFixed(2)}',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                color: _getWorkerTransactionAmountColor(type, direction),
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(status).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                status.toUpperCase(),
                                style: GoogleFonts.poppins(
                                  color: _getStatusColor(status),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  IconData _getWorkerTransactionIcon(String type, String direction) {
    switch (type.toLowerCase()) {
      case 'escrow':
        return direction.toLowerCase() == 'credit' ? Icons.account_balance_wallet : Icons.payment;
      case 'deposit':
        return Icons.add_circle;
      case 'withdrawal':
        return Icons.remove_circle;
      case 'payment':
        return Icons.payment;
      case 'refund':
        return Icons.refresh;
      case 'transfer':
        return Icons.swap_horiz;
      default:
        return Icons.account_balance_wallet;
    }
  }

  Color _getWorkerTransactionIconColor(String type, String direction) {
    switch (type.toLowerCase()) {
      case 'escrow':
        return direction.toLowerCase() == 'credit' ? Colors.green : Colors.blue;
      case 'deposit':
        return Colors.green;
      case 'withdrawal':
        return Colors.red;
      case 'payment':
        return Colors.blue;
      case 'refund':
        return Colors.orange;
      case 'transfer':
        return Colors.purple;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  String _getWorkerTransactionTitle(String type, String direction) {
    switch (type.toLowerCase()) {
      case 'escrow':
        return direction.toLowerCase() == 'credit' ? 'Payment Received' : 'Payment Sent';
      case 'deposit':
        return 'Deposit';
      case 'withdrawal':
        return 'Withdrawal';
      case 'payment':
        return 'Payment';
      case 'refund':
        return 'Refund';
      case 'transfer':
        return 'Transfer';
      default:
        return 'Transaction';
    }
  }

  Color _getWorkerTransactionAmountColor(String type, String direction) {
    switch (type.toLowerCase()) {
      case 'escrow':
        return direction.toLowerCase() == 'credit' ? Colors.green : Colors.red;
      case 'deposit':
      case 'refund':
        return Colors.green;
      case 'withdrawal':
      case 'payment':
        return Colors.red;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'success':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _fetchEarnings({DateTime? date}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      if (token == null) {
        setState(() {
          _error = 'Authentication token not found';
          _isLoading = false;
        });
        return;
      }

      String url = '${ApiConstants.baseUrl}/booking/worker-earnings';
      if (date != null) {
        final dateString = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        url += '?date=$dateString';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['message'] == 'Worker earnings fetched successfully') {
          setState(() {
            _earningsData = data['data'];
            _selectedDate = date;
            _isLoading = false;
          });
        } else {
          setState(() {
            _error = data['message'] ?? 'Failed to fetch earnings';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _error = 'Failed to fetch earnings: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Network error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchTransactions() async {
    setState(() {
      _isTransactionsLoading = true;
      _transactionsError = null;
    });
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      if (token == null) {
        setState(() {
          _transactionsError = 'Authentication token not found';
          _isTransactionsLoading = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/transaction/worker-transactions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['message'] == 'Worker transactions fetched successfully') {
          final List<dynamic> txs = data['data'] ?? [];
          setState(() {
            _transactions = txs.cast<Map<String, dynamic>>();
            _isTransactionsLoading = false;
          });
        } else {
          setState(() {
            _transactionsError = data['message'] ?? 'Failed to fetch transactions';
            _isTransactionsLoading = false;
          });
        }
      } else {
        setState(() {
          _transactionsError = 'Failed to fetch transactions: ${response.statusCode}';
          _isTransactionsLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _transactionsError = 'Network error: ${e.toString()}';
        _isTransactionsLoading = false;
      });
    }
  }
} 