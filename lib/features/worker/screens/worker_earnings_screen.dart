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
                        _buildBookingsPerMonth(context),
            const SizedBox(height: 24),
            _buildEarningsHistory(context),
          ],
                    ),
        ),
      ),
    );
  }

  Widget _buildEarningsHeader(BuildContext context) {
    final rating = _earningsData?['rating'] ?? 0;
    final daysActive = _earningsData?['daysActive'] ?? 0;
    final totalRevenue = _earningsData?['totalRevenue'] ?? 0;
    final totalBookings = _earningsData?['totalBookings'] ?? 0;
    final completedBookings = _earningsData?['totalCompleted'] ?? 0;
    final averageRevenuePerJob = _earningsData?['averageRevenuePerJob'] ?? 0;
    final averageBookingDuration = _earningsData?['averageBookingDuration'] ?? 0;

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
          Row(
            children: [
              Icon(Icons.star, color: Colors.amber, size: 28),
              const SizedBox(width: 8),
                  Text(
                'Rating: $rating',
                    style: GoogleFonts.poppins(
                  fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
              const Spacer(),
              Text(
                'Active: $daysActive days',
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildMetricCard('Total Revenue', 'KES $totalRevenue', Icons.account_balance_wallet, Colors.green),
              const SizedBox(width: 16),
              _buildMetricCard('Total Bookings', '$totalBookings', Icons.work, Colors.blue),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildMetricCard('Completed', '$completedBookings', Icons.check_circle, Colors.purple),
              const SizedBox(width: 16),
              _buildMetricCard('Avg. Revenue/Job', 'KES $averageRevenuePerJob', Icons.trending_up, Colors.orange),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildMetricCard('Avg. Duration', '$averageBookingDuration min', Icons.timer, Colors.teal),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEarningsSummary(BuildContext context) {
    final todayTrend = _earningsData?['todayTrend'] ?? {};
    final weeklyTrend = _earningsData?['weeklyTrend'] ?? {};
    final monthTrend = _earningsData?['monthTrend'] ?? {};
    // Today
    final todayBookings = todayTrend['bookings']?['today'] ?? 0;
    final todayBookingsYesterday = todayTrend['bookings']?['yesterday'] ?? 0;
    final todayBookingsChange = todayTrend['bookings']?['change'] ?? 0;
    final todayRevenue = todayTrend['revenue']?['today'] ?? 0;
    final todayRevenueYesterday = todayTrend['revenue']?['yesterday'] ?? 0;
    final todayRevenueChange = todayTrend['revenue']?['change'] ?? 0;
    // Week
    final weekBookings = weeklyTrend['thisWeek']?['bookings'] ?? 0;
    final weekBookingsLast = weeklyTrend['lastWeek']?['bookings'] ?? 0;
    final weekBookingsChange = weeklyTrend['change']?['bookings'] ?? 0;
    final weekRevenue = weeklyTrend['thisWeek']?['revenue'] ?? 0;
    final weekRevenueLast = weeklyTrend['lastWeek']?['revenue'] ?? 0;
    final weekRevenueChange = weeklyTrend['change']?['revenue'] ?? 0;
    // Month
    final monthBookings = monthTrend['thisMonth']?['bookings'] ?? 0;
    final monthBookingsLast = monthTrend['lastMonth']?['bookings'] ?? 0;
    final monthBookingsChange = monthTrend['change']?['bookings'] ?? 0;
    final monthRevenue = monthTrend['thisMonth']?['revenue'] ?? 0;
    final monthRevenueLast = monthTrend['lastMonth']?['revenue'] ?? 0;
    final monthRevenueChange = monthTrend['change']?['revenue'] ?? 0;
    final monthAvgDuration = monthTrend['thisMonth']?['avgDuration'] ?? 0;
    final monthAvgDurationLast = monthTrend['lastMonth']?['avgDuration'] ?? 0;
    final monthAvgDurationChange = monthTrend['change']?['avgDuration'] ?? 0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
            'Revenue & Bookings Trends',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
          ),
          const SizedBox(height: 16),
          _buildTrendRow('Today', todayRevenue, todayRevenueYesterday, todayRevenueChange, todayBookings, todayBookingsYesterday, todayBookingsChange),
          const SizedBox(height: 12),
          _buildTrendRow('This Week', weekRevenue, weekRevenueLast, weekRevenueChange, weekBookings, weekBookingsLast, weekBookingsChange),
          const SizedBox(height: 12),
          _buildTrendRow('This Month', monthRevenue, monthRevenueLast, monthRevenueChange, monthBookings, monthBookingsLast, monthBookingsChange, avgDuration: monthAvgDuration, avgDurationLast: monthAvgDurationLast, avgDurationChange: monthAvgDurationChange),
        ],
      ),
    );
  }

  Widget _buildTrendRow(String period, int revenue, int revenueLast, num revenueChange, int bookings, int bookingsLast, num bookingsChange, {int? avgDuration, int? avgDurationLast, num? avgDurationChange}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(period, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.payments, color: Colors.green, size: 18),
              const SizedBox(width: 4),
              Text('Revenue: KES $revenue', style: GoogleFonts.poppins(color: Colors.white70)),
              const SizedBox(width: 8),
              Text('(Prev: KES $revenueLast)', style: GoogleFonts.poppins(color: Colors.white38, fontSize: 12)),
              const SizedBox(width: 8),
              Icon(revenueChange >= 0 ? Icons.trending_up : Icons.trending_down, color: revenueChange >= 0 ? Colors.green : Colors.red, size: 18),
              Text('${revenueChange >= 0 ? '+' : ''}${revenueChange.toString()}%', style: GoogleFonts.poppins(color: revenueChange >= 0 ? Colors.green : Colors.red)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.event, color: Colors.blue, size: 18),
              const SizedBox(width: 4),
              Text('Bookings: $bookings', style: GoogleFonts.poppins(color: Colors.white70)),
              const SizedBox(width: 8),
              Text('(Prev: $bookingsLast)', style: GoogleFonts.poppins(color: Colors.white38, fontSize: 12)),
              const SizedBox(width: 8),
              Icon(bookingsChange >= 0 ? Icons.trending_up : Icons.trending_down, color: bookingsChange >= 0 ? Colors.green : Colors.red, size: 18),
              Text('${bookingsChange >= 0 ? '+' : ''}${bookingsChange.toString()}%', style: GoogleFonts.poppins(color: bookingsChange >= 0 ? Colors.green : Colors.red)),
            ],
          ),
          if (avgDuration != null && avgDurationLast != null && avgDurationChange != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.timer, color: Colors.teal, size: 18),
                const SizedBox(width: 4),
                Text('Avg. Duration: $avgDuration min', style: GoogleFonts.poppins(color: Colors.white70)),
                const SizedBox(width: 8),
                Text('(Prev: $avgDurationLast min)', style: GoogleFonts.poppins(color: Colors.white38, fontSize: 12)),
                const SizedBox(width: 8),
                Icon(avgDurationChange >= 0 ? Icons.trending_up : Icons.trending_down, color: avgDurationChange >= 0 ? Colors.green : Colors.red, size: 18),
                Text('${avgDurationChange >= 0 ? '+' : ''}${avgDurationChange.toString()}%', style: GoogleFonts.poppins(color: avgDurationChange >= 0 ? Colors.green : Colors.red)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBookingsPerMonth(BuildContext context) {
    final bookingsPerMonth = _earningsData?['bookingsPerMonth'] as List<dynamic>? ?? [];
    if (bookingsPerMonth.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Text('No monthly bookings data.', style: GoogleFonts.poppins(color: Colors.white70)),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Bookings Per Month', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 8),
          ...bookingsPerMonth.map((entry) {
            final id = entry['_id'] ?? {};
            final month = id['month'] ?? '-';
            final year = id['year'] ?? '-';
            final count = entry['count'] ?? 0;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, color: Colors.blue, size: 18),
                  const SizedBox(width: 8),
                  Text('Month: $month/$year', style: GoogleFonts.poppins(color: Colors.white70)),
                  const Spacer(),
                  Text('Bookings: $count', style: GoogleFonts.poppins(color: Colors.white)),
                ],
              ),
            );
          }).toList(),
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
                  elevation: 2,
                  color: const Color(0xFF232323),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                ),
                child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                            color: _getWorkerTransactionIconColor(type, direction).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                            _getWorkerTransactionIcon(type, direction),
                            color: _getWorkerTransactionIconColor(type, direction),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      _getWorkerTransactionTitle(type, direction),
                              style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                color: Colors.white,
                              ),
                                    ),
                                  ),
                                  if (booking.isNotEmpty) ...[
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        'Booking: $booking',
                              style: GoogleFonts.poppins(
                                          color: Colors.white54,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                                formattedDate,
                              style: GoogleFonts.poppins(
                                color: Colors.white70,
                                  fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                        const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                              'KES ${amount.toStringAsFixed(2)}',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                                color: _getWorkerTransactionAmountColor(type, direction),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                            ),
                            decoration: BoxDecoration(
                                color: _getStatusColor(status).withOpacity(0.13),
                                borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                                status.toUpperCase(),
                              style: GoogleFonts.poppins(
                                  color: _getStatusColor(status),
                                fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
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
      // Use new consolidated endpoint
      String url = '${ApiConstants.baseUrl}/providers/metrics';
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
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