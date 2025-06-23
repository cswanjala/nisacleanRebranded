import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:nisacleanv1/features/bookings/services/booking_service.dart';
import 'package:nisacleanv1/features/bookings/models/booking.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nisacleanv1/core/bloc/auth/auth_bloc.dart';
import 'package:nisacleanv1/core/bloc/auth/auth_state.dart';
import 'package:nisacleanv1/core/bloc/auth/auth_event.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nisacleanv1/core/constants/api_constants.dart';
import 'package:flutter/animation.dart';

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
  int _currentBookingPage = 0;
  static const int _bookingsPerPage = 3;
  String? _selectedStatusFilter; // null = all

  int _currentActivityPage = 0;
  static const int _activitiesPerPage = 5;

  Map<String, dynamic>? _metrics;
  bool _isMetricsLoading = true;
  String? _metricsError;

  List<dynamic> get _pagedActivities {
    final start = _currentActivityPage * _activitiesPerPage;
    return _activities.skip(start).take(_activitiesPerPage).toList();
  }

  @override
  void initState() {
    super.initState();
    context.read<AuthBloc>().add(FetchProfileRequested());
    _selectedDay = DateTime.now();
    _fetchJobsForDay(_selectedDay!);
    _fetchRecentActivities();
    _fetchTodayJobsCount();
    _fetchCompletedJobsCount();
    _fetchProviderMetrics();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _fetchJobsForDay(DateTime day, {bool reset = false}) async {
    setState(() {
      _isLoading = true;
      _error = null;
      if (reset) {
        _jobs = [];
      }
    });
    try {
      final jobs = await _bookingService.getProviderBookings();
      print('Selected day: $day');
      // jobs is List<Map<String, dynamic>>, convert to List<Booking> and filter
      final filteredJobs = jobs.map((json) => Booking.fromJson(json)).where((booking) {
        DateTime bookingDate;
        if (booking.date is DateTime) {
          bookingDate = (booking.date as DateTime).toLocal();
        } else {
          bookingDate = DateTime.parse(booking.date.toString()).toLocal();
        }
        print('Booking: \\${booking.id}, date: \\${bookingDate.toIso8601String()}');
        return bookingDate.year == day.year &&
               bookingDate.month == day.month &&
               bookingDate.day == day.day;
      }).toList();
      setState(() {
        _jobs = filteredJobs;
        _isLoading = false;
        _currentBookingPage = 0;
      });
    } catch (e) {
      setState(() {
        _jobs = [];
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  void _loadMoreJobs() {
    // _scrollController.addListener(_loadMoreJobs);
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
          final transformedActivities = activities.map<Map<String, dynamic>>((activity) {
            return {
              'id': activity['_id'] ?? '',
              'title': activity['action'] ?? 'Activity',
              'description': activity['description'] ?? '',
              'timestamp': activity['createdAt'] ?? '',
              'type': _getActivityTypeFromAction(activity['action'] ?? ''),
              'read': false,
            };
          }).toList();

          setState(() {
            _activities = transformedActivities;
            _isActivitiesLoading = false;
            _currentActivityPage = 0;
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

  Future<void> _fetchProviderMetrics() async {
    setState(() {
      _isMetricsLoading = true;
      _metricsError = null;
    });
    try {
      final metrics = await _bookingService.getProviderMetrics();
      setState(() {
        _metrics = metrics;
        _isMetricsLoading = false;
      });
    } catch (e) {
      setState(() {
        _metricsError = e.toString();
        _isMetricsLoading = false;
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
      _fetchJobsForDay(_selectedDay!, reset: true),
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

  List<Booking> get _filteredBookings {
    if (_selectedStatusFilter == null) return _jobs;
    return _jobs.where((b) => b.status.toString().split('.').last == _selectedStatusFilter).toList();
  }
  List<Booking> get _pagedBookings {
    final filtered = _filteredBookings;
    final start = _currentBookingPage * _bookingsPerPage;
    return filtered.skip(start).take(_bookingsPerPage).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: RefreshIndicator(
        onRefresh: _refreshAllData,
        color: Colors.white,
        backgroundColor: const Color(0xFF2A2A2A),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 180,
              floating: false,
              pinned: true,
              backgroundColor: const Color(0xFF1A1A1A),
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
                title: BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    final name = state.name ?? 'User';
                    return Text(
                      'Welcome, $name!',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        fontSize: 20,
                      ),
                    );
                  },
                ),
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF4A90E2), Color(0xFF3A7BD5)],
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.cleaning_services,
                      size: 80,
                      color: Colors.white.withOpacity(0.2),
                    ),
                  ),
                ),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _StickyHeaderDelegate(
                minHeight: 80,
                maxHeight: 100,
                child: Container(
                  color: const Color(0xFF1A1A1A),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Schedule for ${_formatDate(_selectedDay ?? DateTime.now())}',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          Row(
                            children: [
                              if (_selectedDay != null && !isSameDay(_selectedDay, DateTime.now()))
                                TextButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _selectedDay = DateTime.now();
                                      _focusedDay = DateTime.now();
                                    });
                                    _fetchJobsForDay(_selectedDay!);
                                  },
                                  icon: const Icon(Icons.today, size: 18),
                                  label: const Text('Today'),
                                  style: TextButton.styleFrom(foregroundColor: Colors.white70),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(child: _buildCalendar()),
            _buildScheduleList(),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
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
    return Card(
      elevation: 2,
      color: const Color(0xFF2A2A2A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: TableCalendar(
          firstDay: DateTime.now().subtract(const Duration(days: 365)),
          lastDay: DateTime.now().add(const Duration(days: 365)),
          focusedDay: _focusedDay,
          calendarFormat: _calendarFormat,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
            _fetchJobsForDay(selectedDay, reset: true);
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
            selectedDecoration: const BoxDecoration(
              color: Color(0xFF4A90E2),
              shape: BoxShape.circle,
            ),
            todayDecoration: BoxDecoration(
              color: const Color(0xFF4A90E2).withOpacity(0.3),
              shape: BoxShape.circle,
            ),
          ),
          headerStyle: HeaderStyle(
            formatButtonVisible: true,
            titleCentered: true,
            formatButtonShowsNext: false,
            formatButtonDecoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            formatButtonTextStyle: const TextStyle(color: Colors.white70),
            titleTextStyle: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            leftChevronIcon: const Icon(Icons.chevron_left, color: Colors.white70),
            rightChevronIcon: const Icon(Icons.chevron_right, color: Colors.white70),
          ),
        ),
      ),
    );
  }

  Widget _buildScheduleList() {
    if (_isLoading && _jobs.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator(color: Colors.white70)),
        ),
      );
    }
    if (_error != null) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red.withOpacity(0.7)),
              const SizedBox(height: 16),
              Text(
                'Error: $_error',
                style: GoogleFonts.poppins(color: Colors.red, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _fetchJobsForDay(_selectedDay!, reset: true),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A90E2),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      );
    }
    final dayJobs = _pagedBookings;
    if (_filteredBookings.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(Icons.event_busy, size: 48, color: Colors.white.withOpacity(0.3)),
              const SizedBox(height: 16),
              Text(
                'No bookings for ${_formatDate(_selectedDay ?? DateTime.now())}',
                style: GoogleFonts.poppins(fontSize: 16, color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'New bookings will appear here',
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.white54),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    return SliverToBoxAdapter(
      child: Column(
        children: [
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: dayJobs.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
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
              return AnimatedOpacity(
                opacity: 1.0,
                duration: const Duration(milliseconds: 300),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Card(
                    elevation: 2,
                    color: const Color(0xFF2A2A2A),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: _buildScheduleItem(
                      context,
                      job.service,
                      job.time,
                      job.location.address,
                      _getStatusColor(statusStr),
                      clientName: job.user.name,
                      statusLabel: statusLabel,
                      booking: job,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _currentBookingPage > 0
                    ? () {
                        setState(() {
                          _currentBookingPage--;
                        });
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A90E2),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  minimumSize: const Size(40, 40),
                ),
                child: const Icon(Icons.arrow_upward),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: ((_currentBookingPage + 1) * _bookingsPerPage) < _filteredBookings.length
                    ? () {
                        setState(() {
                          _currentBookingPage++;
                        });
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A90E2),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  minimumSize: const Size(40, 40),
                ),
                child: const Icon(Icons.arrow_downward),
              ),
            ],
          ),
        ],
      ),
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
          CircleAvatar(
            backgroundColor: color.withOpacity(0.2),
            child: Icon(Icons.cleaning_services, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: Colors.white70),
                    const SizedBox(width: 4),
                    Text(
                      time,
                      style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 14, color: Colors.white70),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        location,
                        style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (clientName != null && clientName.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.person, size: 14, color: Colors.white70),
                      const SizedBox(width: 4),
                      Text(
                        'Client: $clientName',
                        style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
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
                            backgroundColor: const Color(0xFF2A2A2A),
                            title: Text('Send Invoice', style: GoogleFonts.poppins(color: Colors.white)),
                            content: TextField(
                              controller: controller,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Amount',
                                labelStyle: const TextStyle(color: Colors.white70),
                                filled: true,
                                fillColor: const Color(0xFF3A3A3A),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  final value = double.tryParse(controller.text);
                                  if (value != null && value > 0) {
                                    Navigator.pop(ctx, value);
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4A90E2),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
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
                            SnackBar(
                              content: Text('Invoice sent!', style: GoogleFonts.poppins(color: Colors.white)),
                              backgroundColor: Colors.green,
                            ),
                          );
                          _fetchJobsForDay(_selectedDay!, reset: true);
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to send invoice: $e', style: GoogleFonts.poppins()),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.receipt_long, size: 18),
                    label: const Text('Send Invoice'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4A90E2),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              statusLabel ?? '',
              style: GoogleFonts.poppins(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context) {
    final m = _metrics ?? {};
    Widget stat(String label, dynamic value, IconData icon, Color color, {String? prefix, String? suffix}) {
      final isNum = value is num;
      return Card(
        elevation: 4,
        color: const Color(0xFF232323),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              isNum
                  ? TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: (value as num).toDouble()),
                      duration: const Duration(milliseconds: 800),
                      builder: (context, val, child) {
                        String display = val.toStringAsFixed(value is int ? 0 : 1);
                        if (prefix != null) display = '$prefix$display';
                        if (suffix != null) display = '$display$suffix';
                        return Text(display, style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w600, color: color));
                      },
                    )
                  : Text(value.toString(), style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w600, color: color)),
              const SizedBox(height: 4),
              Text(label, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14)),
            ],
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.bar_chart, color: Colors.white, size: 22),
            const SizedBox(width: 8),
            Text('Quick Stats', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
          ],
        ),
        const SizedBox(height: 8),
        Divider(color: Colors.white24, thickness: 1),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: stat('Rating', m['rating'] ?? 0, Icons.star, Colors.amber)),
            const SizedBox(width: 12),
            Expanded(child: stat('Avg Revenue/Job', m['averageRevenuePerJob'] ?? 0, Icons.trending_up, Colors.cyan, prefix: 'KES ')),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentActivity(BuildContext context) {
    if (_isActivitiesLoading) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator(color: Colors.white70)),
      );
    }
    if (_activitiesError != null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.withOpacity(0.7)),
            const SizedBox(height: 16),
            Text(
              'Error loading activities',
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _activitiesError!,
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.red.withOpacity(0.7)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _fetchRecentActivities,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A90E2),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
            Row(
              children: [
                Icon(Icons.history, color: Colors.white, size: 22),
                const SizedBox(width: 8),
                Text(
                  'Recent Activity',
                  style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ],
            ),
            if (_activities.isNotEmpty)
              TextButton.icon(
                onPressed: _fetchRecentActivities,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Refresh'),
                style: TextButton.styleFrom(foregroundColor: Colors.white70),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Divider(color: Colors.white24, thickness: 1),
        const SizedBox(height: 12),
        if (_activities.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Icon(Icons.history, size: 48, color: Colors.white.withOpacity(0.3)),
                const SizedBox(height: 16),
                Text(
                  'No recent activities',
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Your recent notifications will appear here',
                  style: GoogleFonts.poppins(fontSize: 14, color: Colors.white54),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          Card(
            elevation: 2,
            color: const Color(0xFF2A2A2A),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _pagedActivities.length,
                  separatorBuilder: (context, index) => Divider(color: Colors.white.withOpacity(0.1)),
                  itemBuilder: (context, index) {
                    final activity = _pagedActivities[index];
                    final timestamp = activity['timestamp'] != null ? DateTime.tryParse(activity['timestamp'].toString()) : null;
                    final isRead = activity['read'] == true;

                    return AnimatedOpacity(
                      opacity: 1.0,
                      duration: const Duration(milliseconds: 300),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        leading: CircleAvatar(
                          backgroundColor: isRead ? Colors.grey.withOpacity(0.3) : const Color(0xFF4A90E2),
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
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (activity['description']?.toString().isNotEmpty == true) ...[
                              Text(
                                activity['description'].toString(),
                                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                            ],
                            if (timestamp != null)
                              Text(
                                _formatActivityTime(timestamp),
                                style: GoogleFonts.poppins(color: Colors.white54, fontSize: 11),
                              ),
                          ],
                        ),
                        trailing: isRead
                            ? null
                            : Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF4A90E2),
                                  shape: BoxShape.circle,
                                ),
                              ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: _currentActivityPage > 0
                          ? () {
                              setState(() {
                                _currentActivityPage--;
                              });
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4A90E2),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        minimumSize: const Size(40, 40),
                      ),
                      child: const Icon(Icons.arrow_upward),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: ((_currentActivityPage + 1) * _activitiesPerPage) < _activities.length
                          ? () {
                              setState(() {
                                _currentActivityPage++;
                              });
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4A90E2),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        minimumSize: const Size(40, 40),
                      ),
                      child: const Icon(Icons.arrow_downward),
                    ),
                  ],
                ),
              ],
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

class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final Widget child;

  _StickyHeaderDelegate({required this.minHeight, required this.maxHeight, required this.child});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => child;

  @override
  double get maxExtent => maxHeight;

  @override
  double get minExtent => minHeight;

  @override
  bool shouldRebuild(_StickyHeaderDelegate oldDelegate) => true;
}

class AllBookingsScreen extends StatefulWidget {
  final List<Map<String, dynamic>> schedules;

  const AllBookingsScreen({super.key, required this.schedules});

  @override
  State<AllBookingsScreen> createState() => _AllBookingsScreenState();
}

class _AllBookingsScreenState extends State<AllBookingsScreen> {
  String _searchQuery = '';
  String _selectedStatus = 'all';
  DateTime? _startDate;
  DateTime? _endDate;
  String _tempSearchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        title: Text(
          'All Bookings',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 20),
        ),
        iconTheme: const IconThemeData(color: Colors.white70),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.white70),
            onPressed: _showFilterBottomSheet,
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search bookings...',
                  hintStyle: const TextStyle(color: Colors.white54),
                  prefixIcon: const Icon(Icons.search, color: Colors.white70),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.white70),
                          onPressed: () {
                            setState(() {
                              _searchQuery = '';
                              _tempSearchQuery = '';
                            });
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: const Color(0xFF2A2A2A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) {
                  _tempSearchQuery = value;
                  Future.delayed(const Duration(milliseconds: 500), () {
                    if (_tempSearchQuery == value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    }
                  });
                },
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                children: [
                  if (_startDate != null || _endDate != null)
                    Chip(
                      label: Text(
                        'Date: ${_startDate != null ? _formatDate(_startDate!) : 'Any'} - ${_endDate != null ? _formatDate(_endDate!) : 'Any'}',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                      backgroundColor: Colors.white.withOpacity(0.1),
                      deleteIcon: const Icon(Icons.close, size: 16, color: Colors.white70),
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
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                      backgroundColor: Colors.white.withOpacity(0.1),
                      deleteIcon: const Icon(Icons.close, size: 16, color: Colors.white70),
                      onDeleted: () {
                        setState(() {
                          _selectedStatus = 'all';
                        });
                      },
                    ),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final schedule = _filteredSchedules[index];
                return AnimatedOpacity(
                  opacity: 1.0,
                  duration: const Duration(milliseconds: 300),
                  child: Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    elevation: 2,
                    color: const Color(0xFF2A2A2A),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: CircleAvatar(
                        backgroundColor: _getStatusColor(schedule['status'] as String).withOpacity(0.2),
                        child: Icon(
                          Icons.cleaning_services,
                          color: _getStatusColor(schedule['status'] as String),
                          size: 24,
                        ),
                      ),
                      title: Text(
                        schedule['title'] as String,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 6),
                          Text(
                            schedule['client'] as String,
                            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.calendar_today, size: 14, color: Colors.white70),
                              const SizedBox(width: 4),
                              Text(
                                _formatDate(schedule['date'] as DateTime),
                                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.access_time, size: 14, color: Colors.white70),
                              const SizedBox(width: 4),
                              Text(
                                schedule['time'] as String,
                                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.location_on, size: 14, color: Colors.white70),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  schedule['address'] as String,
                                  style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(schedule['status'] as String).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
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
                        // Navigate to booking details (unchanged)
                      },
                    ),
                  ),
                );
              },
              childCount: _filteredSchedules.length,
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2A2A2A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filter Bookings',
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('All'),
                  selected: _selectedStatus == 'all',
                  onSelected: (selected) {
                    setState(() {
                      _selectedStatus = 'all';
                    });
                    Navigator.pop(context);
                  },
                  selectedColor: Colors.white.withOpacity(0.2),
                  backgroundColor: const Color(0xFF3A3A3A),
                  labelStyle: TextStyle(color: _selectedStatus == 'all' ? Colors.white : Colors.white70),
                ),
                ...['upcoming', 'in_progress', 'completed', 'cancelled'].map((status) => ChoiceChip(
                      label: Text(status.toUpperCase()),
                      selected: _selectedStatus == status,
                      onSelected: (selected) {
                        setState(() {
                          _selectedStatus = status;
                        });
                        Navigator.pop(context);
                      },
                      selectedColor: Colors.white.withOpacity(0.2),
                      backgroundColor: const Color(0xFF3A3A3A),
                      labelStyle: TextStyle(color: _selectedStatus == status ? Colors.white : Colors.white70),
                    )),
              ],
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
                    icon: const Icon(Icons.calendar_today, color: Colors.white70),
                    label: Text(
                      _startDate == null ? 'Start Date' : _formatDate(_startDate!),
                      style: const TextStyle(color: Colors.white70),
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
                    icon: const Icon(Icons.calendar_today, color: Colors.white70),
                    label: Text(
                      _endDate == null ? 'End Date' : _formatDate(_endDate!),
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedStatus = 'all';
                        _startDate = null;
                        _endDate = null;
                      });
                      Navigator.pop(context);
                    },
                    child: const Text('Clear All', style: TextStyle(color: Colors.white70)),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A90E2),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Apply'),
                ),
              ],
            ),
          ],
        ),
      ),
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
}