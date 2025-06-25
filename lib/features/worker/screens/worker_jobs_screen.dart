import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nisacleanv1/features/bookings/services/booking_service.dart';
import 'package:nisacleanv1/features/bookings/models/booking.dart';
import 'package:nisacleanv1/features/bookings/screens/booking_details_screen.dart';
import 'package:intl/intl.dart';

class WorkerJobsScreen extends StatefulWidget {
  const WorkerJobsScreen({super.key});

  @override
  State<WorkerJobsScreen> createState() => _WorkerJobsScreenState();
}

class _WorkerJobsScreenState extends State<WorkerJobsScreen> {
  final BookingService _bookingService = BookingService();
  bool _isLoading = false;
  String? _error;
  List<Map<String, dynamic>> _jobs = [];

  @override
  void initState() {
    super.initState();
    _fetchJobs();
  }

  Future<void> _fetchJobs() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final jobs = await _bookingService.getProviderBookings();
      setState(() {
        _jobs = jobs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _updateJobStatus(String bookingId, String newStatus) async {
    setState(() {
      _isLoading = true;
    });
    try {
      if (newStatus == 'inprogress') {
        await _bookingService.startBooking(bookingId);
      } else if (newStatus == 'completed') {
        await _bookingService.markBookingAsComplete(bookingId);
      }
      await _fetchJobs();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(
            'My Jobs',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              fontSize: 22,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          bottom: const TabBar(
            indicatorWeight: 3,
            tabs: [
              Tab(text: 'Pending'),
              Tab(text: 'In Progress'),
              Tab(text: 'Completed'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildErrorState()
                : RefreshIndicator(
                    onRefresh: _fetchJobs,
                    child: TabBarView(
                      children: [
                        _buildJobList(context, BookingStatus.pending),
                        _buildJobList(context, BookingStatus.inprogress),
                        _buildJobList(context, BookingStatus.completed),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red[400], size: 64),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? '',
              style: GoogleFonts.poppins(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchJobs,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJobList(BuildContext context, BookingStatus status) {
    final jobs = status == BookingStatus.pending
        ? _jobs.where((job) => job['status'] == 'pending' || job['status'] == 'confirmation').toList()
        : _jobs.where((job) => job['status'] == status.name).toList();
    if (jobs.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 120),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.work_outline,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No ${status.name.replaceAll("inprogress", "in progress")} jobs',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'You have no ${status.name.replaceAll("inprogress", "in progress")} jobs at the moment.',
                  style: GoogleFonts.poppins(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: jobs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final job = jobs[index];
        return _buildJobCard(context, job, status);
      },
    );
  }

  Widget _buildJobCard(BuildContext context, Map<String, dynamic> job, BookingStatus status) {
    final user = job['user'] ?? {};
    final location = job['location'] ?? {};
    final service = job['service'] ?? '';
    final date = job['date'] ?? '';
    final time = job['time'] ?? '';
    final amount = status == BookingStatus.inprogress && job['invoiceAmount'] != null
        ? NumberFormat('#,##0.00').format((job['invoiceAmount'] as num).toDouble())
        : NumberFormat('#,##0.00').format(((job['amount'] ?? 0) as num).toDouble());
    final statusColor = _getStatusColor(status);
    final statusText = status.name.replaceAll('inprogress', 'In Progress').toUpperCase();

    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(18),
      color: Theme.of(context).colorScheme.surface,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          final booking = Booking.fromJson(job);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BookingDetailsScreen(booking: booking),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  (user['avatarUrl'] != null && (user['avatarUrl'] as String).isNotEmpty)
                      ? CircleAvatar(
                          radius: 24,
                          backgroundImage: NetworkImage(user['avatarUrl'] as String),
                        )
                      : CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.blue.withOpacity(0.12),
                          child: Icon(Icons.person, color: Colors.blue, size: 28),
                        ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          service,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user['name'] ?? '',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          location['address'] ?? '',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(left: 8, top: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      statusText,
                      style: GoogleFonts.poppins(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[400]),
                  const SizedBox(width: 4),
                  Text(
                    date,
                    style: GoogleFonts.poppins(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.access_time, size: 16, color: Colors.grey[400]),
                  const SizedBox(width: 4),
                  Text(
                    time,
                    style: GoogleFonts.poppins(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Divider(height: 1, color: Colors.grey[200]),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'KES $amount',
                    style: GoogleFonts.poppins(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  Row(
                    children: [
                      if (status == BookingStatus.inprogress)
                        OutlinedButton.icon(
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Complete Job'),
                                content: const Text('Are you sure you want to mark this job as completed?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text('Complete'),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              setState(() => _isLoading = true);
                              try {
                                await _bookingService.markBookingAsComplete(job['_id']);
                                await _fetchJobs();
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Booking marked as completed!'), backgroundColor: Colors.green),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Failed to complete booking: $e'), backgroundColor: Colors.red),
                                  );
                                }
                              } finally {
                                if (mounted) setState(() => _isLoading = false);
                              }
                            }
                          },
                          icon: const Icon(Icons.check, size: 18),
                          label: const Text('Complete'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.blue[700],
                            side: BorderSide(color: Colors.blue[700]!),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                          ),
                        ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () {
                          final booking = Booking.fromJson(job);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BookingDetailsScreen(booking: booking),
                            ),
                          );
                        },
                        icon: const Icon(Icons.info_outline),
                        tooltip: 'View Details',
                        color: Colors.blue,
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

  Color _getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return Colors.orange;
      case BookingStatus.inprogress:
        return Colors.blue;
      case BookingStatus.completed:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  void _showStatusUpdateDialog(
    BuildContext context,
    String jobId,
    String actionTitle,
    String message,
    String newStatus,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          actionTitle,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          message,
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _updateJobStatus(jobId, newStatus);
            },
            child: Text(actionTitle),
          ),
        ],
      ),
    );
  }
} 