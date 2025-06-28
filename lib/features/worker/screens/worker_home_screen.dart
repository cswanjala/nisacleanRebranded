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
import 'package:nisacleanv1/services/auth_service.dart';

// Reusable Modern App Bar Widget
Widget buildModernAppBar({
  required BuildContext context,
  required String userName,
  String? avatarUrl,
  int unreadNotifications = 0,
  String? title,
  List<Widget>? actions,
  VoidCallback? onNotificationsPressed,
  bool showBackButton = false,
}) {
  final colorScheme = Theme.of(context).colorScheme;
  final greeting = _getGreeting();

  return Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
    child: Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [colorScheme.primary, colorScheme.primary.withOpacity(0.85)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withOpacity(0.18),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (showBackButton)
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.white.withOpacity(0.2),
              child: avatarUrl != null
                  ? ClipOval(
                      child: Image.network(
                        avatarUrl,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Text(
                          userName.substring(0, 1),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    )
                  : Text(
                      userName.substring(0, 1),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    greeting,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    userName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  if (title != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Row(
              children: [
                if (actions != null) ...actions,
                Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_none, color: Colors.white, size: 28),
                      onPressed: onNotificationsPressed,
                    ),
                    if (unreadNotifications > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            unreadNotifications.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

String _getGreeting() {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'Good morning';
  if (hour < 17) return 'Good afternoon';
  return 'Good evening';
}

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

  int get _unreadNotifications => _activities.where((activity) => activity['read'] == false).length;

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
      final filteredJobs = jobs.map((json) => Booking.fromJson(json)).where((booking) {
        DateTime bookingDate;
        if (booking.date is DateTime) {
          bookingDate = (booking.date as DateTime).toLocal();
        } else {
          bookingDate = DateTime.parse(booking.date.toString()).toLocal();
        }
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
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshAllData,
          color: Colors.white,
          backgroundColor: const Color(0xFF2A2A2A),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    return FutureBuilder<Map<String, dynamic>>(
                      future: AuthService().fetchCurrentProviderProfile(),
                      builder: (context, snapshot) {
                        String userName = 'Worker';
                        String? avatarUrl;
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return buildModernAppBar(
                            context: context,
                            userName: 'Loading...',
                            avatarUrl: null,
                            unreadNotifications: _unreadNotifications,
                            title: 'Worker Dashboard',
                            onNotificationsPressed: () {},
                          );
                        }
                        if (snapshot.hasError) {
                          return buildModernAppBar(
                            context: context,
                            userName: state.name ?? 'Worker',
                            avatarUrl: null,
                            unreadNotifications: _unreadNotifications,
                            title: 'Worker Dashboard',
                            onNotificationsPressed: () {},
                          );
                        }
                        final provider = snapshot.data ?? {};
                        userName = provider['name'] ?? state.name ?? 'Worker';
                        avatarUrl = provider['avatarUrl'] ?? null;
                        return buildModernAppBar(
                          context: context,
                          userName: userName,
                          avatarUrl: avatarUrl,
                          unreadNotifications: _unreadNotifications,
                          title: 'Worker Dashboard',
                          onNotificationsPressed: () {},
                        );
                      },
                    );
                  },
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