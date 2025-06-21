import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:nisacleanv1/features/bookings/services/booking_service.dart';
import 'package:nisacleanv1/features/bookings/models/booking.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nisacleanv1/core/bloc/auth/auth_bloc.dart';
import 'package:nisacleanv1/core/bloc/auth/auth_state.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nisacleanv1/core/constants/api_constants.dart';

class WorkerHomeScreen extends StatefulWidget {
  const WorkerHomeScreen({super.key});

  @override
  State<WorkerHomeScreen> createState() => _WorkerHomeScreenState();
}

class _WorkerHomeScreenState extends State<WorkerHomeScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.week;

  final BookingService _bookingService = BookingService();
  List<Booking> _jobs = [];
  bool _isLoading = true;
  String? _error;
  List<dynamic> _activities = [];
  bool _isActivitiesLoading = false;
  String? _activitiesError;
  int _todayJobsCount = 0;
  bool _isTodayJobsLoading = false;
  String? _todayJobsError;
  int _completedJobsCount = 0;
  bool _isCompletedJobsLoading = false;
  String? _completedJobsError;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _fetchJobsForDay(_selectedDay!);
    _fetchRecentActivities();
    _fetchTodayJobsCount();
    _fetchCompletedJobsCount();
  }

  Future<void> _fetchJobsForDay(DateTime day) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final jobs = await _bookingService.getProviderBookings();
      setState(() {
        _jobs = jobs.map((json) => Booking.fromJson(json)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _jobs = [];
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _fetchRecentActivities() async {
    setState(() {
      _isActivitiesLoading = true;
      _activitiesError = null;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      if (token == null) {
        setState(() {
          _activitiesError = 'Authentication token not found';
          _isActivitiesLoading = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/activity/get-activities'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['message'] == 'User activities fetched successfully') {
          final activities = data['data'] ?? [];
          
          // Transform activities to match our UI format
          final transformedActivities = activities.map<Map<String, dynamic>>((activity) {
            return {
              'id': activity['_id'] ?? '',
              'title': activity['action'] ?? 'Activity',
              'description': activity['description'] ?? '',
              'timestamp': activity['createdAt'] ?? '',
              'type': _getActivityTypeFromAction(activity['action'] ?? ''),
              'read': false, // Activities are always unread by default
            };
          }).toList();

          setState(() {
            _activities = transformedActivities;
            _isActivitiesLoading = false;
          });
        } else {
          setState(() {
            _activitiesError = data['message'] ?? 'Failed to fetch activities';
            _isActivitiesLoading = false;
          });
        }
      } else {
        setState(() {
          _activitiesError = 'Failed to fetch activities: ${response.statusCode}';
          _isActivitiesLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _activitiesError = 'Network error: ${e.toString()}';
        _isActivitiesLoading = false;
      });
    }
  }

  Future<void> _fetchTodayJobsCount() async {
    setState(() {
      _isTodayJobsLoading = true;
      _todayJobsError = null;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      if (token == null) {
        setState(() {
          _todayJobsError = 'Authentication token not found';
          _isTodayJobsLoading = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/booking/today-jobs-count'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['message'] == 'Today\'s jobs count fetched successfully') {
          setState(() {
            _todayJobsCount = data['data']['count'] ?? 0;
            _isTodayJobsLoading = false;
          });
        } else {
          setState(() {
            _todayJobsError = data['message'] ?? 'Failed to fetch today\'s jobs count';
            _isTodayJobsLoading = false;
          });
        }
      } else {
        setState(() {
          _todayJobsError = 'Failed to fetch today\'s jobs count: ${response.statusCode}';
          _isTodayJobsLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _todayJobsError = 'Network error: ${e.toString()}';
        _isTodayJobsLoading = false;
      });
    }
  }

  Future<void> _fetchCompletedJobsCount() async {
    setState(() {
      _isCompletedJobsLoading = true;
      _completedJobsError = null;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      if (token == null) {
        setState(() {
          _completedJobsError = 'Authentication token not found';
          _isCompletedJobsLoading = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/booking/completed-jobs-count'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['message'] == 'Completed jobs count fetched successfully') {
          setState(() {
            _completedJobsCount = data['data']['count'] ?? 0;
            _isCompletedJobsLoading = false;
          });
        } else {
          setState(() {
            _completedJobsError = data['message'] ?? 'Failed to fetch completed jobs count';
            _isCompletedJobsLoading = false;
          });
        }
      } else {
        setState(() {
          _completedJobsError = 'Failed to fetch completed jobs count: ${response.statusCode}';
          _isCompletedJobsLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _completedJobsError = 'Network error: ${e.toString()}';
        _isCompletedJobsLoading = false;
      });
    }
  }

  String _getActivityTypeFromAction(String action) {
    switch (action.toUpperCase()) {
      case 'BOOKING CREATED':
        return 'booking';
      case 'INVOICE RECEIVED':
        return 'payment';
      case 'LOGIN':
        return 'system';
      case 'BOOKING COMPLETED':
        return 'booking';
      case 'PAYMENT RECEIVED':
        return 'payment';
      case 'BOOKING CANCELLED':
        return 'booking';
      case 'REVIEW RECEIVED':
        return 'review';
      case 'DISPUTE CREATED':
        return 'dispute';
      case 'DISPUTE RESOLVED':
        return 'dispute';
      default:
        return 'notification';
    }
  }

  Future<void> _refreshAllData() async {
    await Future.wait([
      _fetchJobsForDay(_selectedDay!),
      _fetchRecentActivities(),
      _fetchTodayJobsCount(),
      _fetchCompletedJobsCount(),
    ]);
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'upcoming':
        return Colors.blue;
      case 'in_progress':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: RefreshIndicator(
        onRefresh: _refreshAllData,
        color: Theme.of(context).colorScheme.primary,
        backgroundColor: const Color(0xFF2A2A2A),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 200,
              floating: false,
              pinned: true,
              backgroundColor: const Color(0xFF1A1A1A),
              flexibleSpace: FlexibleSpaceBar(
                title: BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    final name = state.name ?? 'User';
                    return Text(
                      'Welcome Back, $name!',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                    );
                  },
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.primary.withOpacity(0.8),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.cleaning_services,
                      size: 64,
                      color: Colors.white.withOpacity(0.3),
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTodaySchedule(context),
                    const SizedBox(height: 24),
                    _buildQuickStats(context),
                    const SizedBox(height: 24),
                    _buildRecentActivity(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodaySchedule(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Schedule for ${_formatDate(_selectedDay ?? DateTime.now())}',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            if (_selectedDay != null && !isSameDay(_selectedDay, DateTime.now()))
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedDay = DateTime.now();
                    _focusedDay = DateTime.now();
                  });
                },
                icon: const Icon(Icons.today),
                label: const Text('Today'),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.primary,
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 0,
          color: const Color(0xFF2A2A2A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              _buildCalendar(),
              const Divider(color: Colors.white24),
              _buildScheduleList(),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final yesterday = DateTime(now.year, now.month, now.day - 1);

    if (isSameDay(date, now)) {
      return 'Today';
    } else if (isSameDay(date, tomorrow)) {
      return 'Tomorrow';
    } else if (isSameDay(date, yesterday)) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Widget _buildCalendar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TableCalendar(
        firstDay: DateTime.now().subtract(const Duration(days: 365)),
        lastDay: DateTime.now().add(const Duration(days: 365)),
        focusedDay: _focusedDay,
        calendarFormat: _calendarFormat,
        selectedDayPredicate: (day) {
          return isSameDay(_selectedDay, day);
        },
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
          _fetchJobsForDay(selectedDay);
        },
        onFormatChanged: (format) {
          setState(() {
            _calendarFormat = format;
          });
        },
        calendarStyle: CalendarStyle(
          outsideDaysVisible: false,
          weekendTextStyle: const TextStyle(color: Colors.white70),
          defaultTextStyle: const TextStyle(color: Colors.white),
          selectedDecoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            shape: BoxShape.circle,
          ),
          todayDecoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
        ),
        headerStyle: HeaderStyle(
          formatButtonVisible: true,
          titleCentered: true,
          formatButtonShowsNext: false,
          formatButtonDecoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          formatButtonTextStyle: TextStyle(
            color: Theme.of(context).colorScheme.primary,
          ),
          titleTextStyle: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          leftChevronIcon: Icon(
            Icons.chevron_left,
            color: Theme.of(context).colorScheme.primary,
          ),
          rightChevronIcon: Icon(
            Icons.chevron_right,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildScheduleList() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Error loading jobs: $_error!',
          style: GoogleFonts.poppins(color: Colors.red, fontSize: 16),
        ),
      );
    }
    final dayJobs = _jobs;
    if (dayJobs.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.event_busy,
              size: 48,
              color: Colors.white.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No bookings for ${_formatDate(_selectedDay ?? DateTime.now())}',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'New bookings will appear here',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.white54,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: dayJobs.length,
      separatorBuilder: (context, index) => const Divider(color: Colors.white24),
      itemBuilder: (context, index) {
        final job = dayJobs[index];
        final statusStr = job.status.toString().split('.').last;
        String statusLabel = '';
        switch (statusStr) {
          case 'pending':
            statusLabel = 'Pending';
            break;
          case 'confirmation':
            statusLabel = 'Awaiting Confirmation';
            break;
          case 'inprogress':
            statusLabel = 'In Progress';
            break;
          case 'completed':
            statusLabel = 'Completed';
            break;
          case 'cancelled':
            statusLabel = 'Cancelled';
            break;
          default:
            statusLabel = statusStr;
        }
        return _buildScheduleItem(
                context,
          job.service,
          job.time,
          job.location.address,
          _getStatusColor(statusStr),
          clientName: job.user.name,
          statusLabel: statusLabel,
          booking: job,
                  );
                },
    );
  }

  Widget _buildScheduleItem(
    BuildContext context,
    String title,
    String time,
    String location,
    Color color, {
    String? clientName,
    String? statusLabel,
    Booking? booking,
  }) {
    final isPending = statusLabel?.toLowerCase() == 'pending';
    final canSendInvoice = isPending && (booking?.invoiceSent != true);
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.cleaning_services, color: color, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: Colors.white70),
                    const SizedBox(width: 4),
                    Text(time, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 14, color: Colors.white70),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(location, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                  ],
                ),
                if (clientName != null && clientName.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.person, size: 14, color: Colors.white70),
                      const SizedBox(width: 4),
                      Text('Client: $clientName', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ],
                if (canSendInvoice) ...[
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final amount = await showDialog<double>(
                        context: context,
                        builder: (ctx) {
                          final controller = TextEditingController();
                          return AlertDialog(
                            title: const Text('Send Invoice'),
                            content: TextField(
                              controller: controller,
                              keyboardType: TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(labelText: 'Amount'),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
            onPressed: () {
                                  final value = double.tryParse(controller.text);
                                  if (value != null && value > 0) {
                                    Navigator.pop(ctx, value);
                                  }
                                },
                                child: const Text('Send'),
                              ),
                            ],
                          );
                        },
                      );
                      if (amount != null) {
                        try {
                          await _bookingService.sendInvoice(bookingId: booking!.id, amount: amount);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Invoice sent to client!')),
                          );
                          _fetchJobsForDay(_selectedDay!); // Refresh
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to send invoice: $e')),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.receipt_long),
                    label: const Text('Send Invoice'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                statusLabel ?? '',
                style: GoogleFonts.poppins(color: color, fontSize: 12, fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context) {
    // Calculate earnings from completed jobs (assuming each job has a price)
    double totalEarnings = 0;
    for (final job in _jobs) {
      if (job.status.toString().toLowerCase() == 'completed') {
        // Use amount field from Booking model
        totalEarnings += job.amount ?? 0;
      }
    }
    
    // Calculate average rating from completed jobs
    double averageRating = 0;
    int ratedJobs = 0;
    for (final job in _jobs) {
      if (job.status.toString().toLowerCase() == 'completed' && job.review != null) {
        // Since there's no rating field, we'll use a placeholder
        // In a real app, you'd fetch ratings from a separate API
        averageRating += 4.5; // Placeholder rating
        ratedJobs++;
      }
    }
    averageRating = ratedJobs > 0 ? averageRating / ratedJobs : 0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Stats',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                'Today\'s Jobs',
                _isTodayJobsLoading ? '...' : _todayJobsCount.toString(),
                Icons.work,
                Colors.blue,
                isLoading: _isTodayJobsLoading,
                error: _todayJobsError,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                context,
                'Earnings',
                'KES ${totalEarnings.toStringAsFixed(0)}',
                Icons.account_balance_wallet,
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                'Rating',
                averageRating > 0 ? averageRating.toStringAsFixed(1) : 'N/A',
                Icons.star,
                Colors.amber,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                context,
                'Completed',
                _isCompletedJobsLoading ? '...' : _completedJobsCount.toString(),
                Icons.check_circle,
                Colors.purple,
                isLoading: _isCompletedJobsLoading,
                error: _completedJobsError,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color, {
    bool isLoading = false,
    String? error,
  }) {
    return Card(
      elevation: 0,
      color: const Color(0xFF2A2A2A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            if (isLoading)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                ),
              )
            else if (error != null)
              Text(
                'Error',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              )
            else
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            const SizedBox(height: 4),
            Text(
              title,
              style: GoogleFonts.poppins(
                color: Colors.white70,
              ),
            ),
            if (error != null) ...[
              const SizedBox(height: 4),
              Text(
                error,
                style: GoogleFonts.poppins(
                  color: Colors.red.withOpacity(0.7),
                  fontSize: 10,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity(BuildContext context) {
    if (_isActivitiesLoading) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_activitiesError != null) {
      return Padding(
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
              'Error loading activities',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.red,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _activitiesError!,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.red.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _fetchRecentActivities,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Activity',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            if (_activities.isNotEmpty)
              TextButton.icon(
                onPressed: _fetchRecentActivities,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Refresh'),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.primary,
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (_activities.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Icon(
                  Icons.history,
                  size: 48,
                  color: Colors.white.withOpacity(0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'No recent activities',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Your recent notifications and activities will appear here',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white54,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          Card(
            elevation: 0,
            color: const Color(0xFF2A2A2A),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _activities.length > 5 ? 5 : _activities.length,
              separatorBuilder: (context, index) => const Divider(color: Colors.white24),
              itemBuilder: (context, index) {
                final activity = _activities[index];
                final timestamp = activity['timestamp'] != null 
                    ? DateTime.tryParse(activity['timestamp'].toString())
                    : null;
                final isRead = activity['read'] == true;
                
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isRead 
                        ? Colors.grey.withOpacity(0.3)
                        : Theme.of(context).colorScheme.primary,
                    child: Icon(
                      _getActivityIcon(activity['type'] ?? 'notification'),
                      color: isRead ? Colors.grey : Colors.white,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    activity['title']?.toString() ?? 'Activity',
                    style: GoogleFonts.poppins(
                      fontWeight: isRead ? FontWeight.w400 : FontWeight.w600,
                      color: isRead ? Colors.white70 : Colors.white,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (activity['description']?.toString().isNotEmpty == true) ...[
                        Text(
                          activity['description'].toString(),
                          style: GoogleFonts.poppins(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                      ],
                      if (timestamp != null)
                        Text(
                          _formatActivityTime(timestamp),
                          style: GoogleFonts.poppins(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                  trailing: isRead 
                      ? null 
                      : Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                );
              },
            ),
          ),
      ],
    );
  }

  IconData _getActivityIcon(String type) {
    switch (type.toLowerCase()) {
      case 'booking':
        return Icons.calendar_today;
      case 'payment':
        return Icons.payment;
      case 'notification':
        return Icons.notifications;
      case 'message':
        return Icons.message;
      case 'system':
        return Icons.system_update;
      case 'review':
        return Icons.star;
      case 'dispute':
        return Icons.warning;
      case 'invoice':
        return Icons.receipt;
      case 'login':
        return Icons.login;
      default:
        return Icons.info;
    }
  }

  String _formatActivityTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }
}

class AllBookingsScreen extends StatefulWidget {
  final List<Map<String, dynamic>> schedules;

  const AllBookingsScreen({
    super.key,
    required this.schedules,
  });

  @override
  State<AllBookingsScreen> createState() => _AllBookingsScreenState();
}

class _AllBookingsScreenState extends State<AllBookingsScreen> {
  String _searchQuery = '';
  String _selectedStatus = 'all';
  DateTime? _startDate;
  DateTime? _endDate;

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final yesterday = DateTime(now.year, now.month, now.day - 1);

    if (isSameDay(date, now)) {
      return 'Today';
    } else if (isSameDay(date, tomorrow)) {
      return 'Tomorrow';
    } else if (isSameDay(date, yesterday)) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'upcoming':
        return Colors.blue;
      case 'in_progress':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  List<Map<String, dynamic>> get _filteredSchedules {
    return widget.schedules.where((schedule) {
      final matchesSearch = schedule['title'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          schedule['client'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      
      final matchesStatus = _selectedStatus == 'all' || schedule['status'] == _selectedStatus;
      
      final date = schedule['date'] as DateTime;
      final matchesDateRange = (_startDate == null || date.isAfter(_startDate!)) &&
          (_endDate == null || date.isBefore(_endDate!));

      return matchesSearch && matchesStatus && matchesDateRange;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'All Bookings',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.white70),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search bookings...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                filled: true,
                fillColor: const Color(0xFF2A2A2A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          if (_startDate != null || _endDate != null || _selectedStatus != 'all')
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                children: [
                  if (_startDate != null || _endDate != null)
                    Chip(
                      label: Text(
                        'Date: ${_startDate != null ? _formatDate(_startDate!) : 'Any'} - ${_endDate != null ? _formatDate(_endDate!) : 'Any'}',
                        style: const TextStyle(color: Colors.white),
                      ),
                      backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      deleteIcon: const Icon(Icons.close, color: Colors.white70),
                      onDeleted: () {
                        setState(() {
                          _startDate = null;
                          _endDate = null;
                        });
                      },
                    ),
                  if (_selectedStatus != 'all')
                    Chip(
                      label: Text(
                        'Status: ${_selectedStatus.toUpperCase()}',
                        style: const TextStyle(color: Colors.white),
                      ),
                      backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      deleteIcon: const Icon(Icons.close, color: Colors.white70),
                      onDeleted: () {
                        setState(() {
                          _selectedStatus = 'all';
                        });
                      },
                    ),
                ],
              ),
            ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredSchedules.length,
              itemBuilder: (context, index) {
                final schedule = _filteredSchedules[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 0,
                  color: const Color(0xFF2A2A2A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _getStatusColor(schedule['status'] as String).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.cleaning_services,
                        color: _getStatusColor(schedule['status'] as String),
                      ),
                    ),
                    title: Text(
                      schedule['title'] as String,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          schedule['client'] as String,
                          style: GoogleFonts.poppins(
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 14,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatDate(schedule['date'] as DateTime),
                              style: GoogleFonts.poppins(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 14,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              schedule['time'] as String,
                              style: GoogleFonts.poppins(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 14,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                schedule['address'] as String,
                                style: GoogleFonts.poppins(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(schedule['status'] as String).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        (schedule['status'] as String).toUpperCase(),
                        style: GoogleFonts.poppins(
                          color: _getStatusColor(schedule['status'] as String),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    onTap: () {
                      // TODO: Navigate to booking details
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: Text(
          'Filter Bookings',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedStatus,
              decoration: InputDecoration(
                labelText: 'Status',
                labelStyle: const TextStyle(color: Colors.white70),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              dropdownColor: const Color(0xFF2A2A2A),
              style: const TextStyle(color: Colors.white),
              items: [
                DropdownMenuItem(
                  value: 'all',
                  child: Text('All Statuses'),
                ),
                DropdownMenuItem(
                  value: 'upcoming',
                  child: Text('Upcoming'),
                ),
                DropdownMenuItem(
                  value: 'in_progress',
                  child: Text('In Progress'),
                ),
                DropdownMenuItem(
                  value: 'completed',
                  child: Text('Completed'),
                ),
                DropdownMenuItem(
                  value: 'cancelled',
                  child: Text('Cancelled'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedStatus = value!;
                });
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _startDate ?? DateTime.now(),
                        firstDate: DateTime(2024),
                        lastDate: DateTime(2025),
                      );
                      if (date != null) {
                        setState(() {
                          _startDate = date;
                        });
                      }
                    },
                    icon: const Icon(Icons.calendar_today),
                    label: Text(_startDate == null ? 'Start Date' : _formatDate(_startDate!)),
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextButton.icon(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _endDate ?? DateTime.now(),
                        firstDate: DateTime(2024),
                        lastDate: DateTime(2025),
                      );
                      if (date != null) {
                        setState(() {
                          _endDate = date;
                        });
                      }
                    },
                    icon: const Icon(Icons.calendar_today),
                    label: Text(_endDate == null ? 'End Date' : _formatDate(_endDate!)),
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectedStatus = 'all';
                _startDate = null;
                _endDate = null;
              });
              Navigator.pop(context);
            },
            child: const Text('Clear All'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
} 