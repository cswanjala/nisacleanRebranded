import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nisacleanv1/features/bookings/services/booking_service.dart';
import 'package:nisacleanv1/features/bookings/models/booking.dart';

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
        appBar: AppBar(
          title: Text(
            'My Jobs',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          bottom: const TabBar(
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
                ? Center(child: Text('Error: \\$_error', style: GoogleFonts.poppins(color: Colors.red)))
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

  Widget _buildJobList(BuildContext context, BookingStatus status) {
    final jobs = status == BookingStatus.pending
        ? _jobs.where((job) => job['status'] == 'pending' || job['status'] == 'confirmation').toList()
        : _jobs.where((job) => job['status'] == status.name).toList();
    if (jobs.isEmpty) {
      return ListView(
        children: [
          SizedBox(height: 120),
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
                  'No \${status.name} jobs',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: jobs.length,
      itemBuilder: (context, index) {
        final job = jobs[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      job['service'] ?? '',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        status.name.toUpperCase(),
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildInfoRow(Icons.person, job['user']?['name'] ?? ''),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.location_on, job['location']?['address'] ?? ''),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.calendar_today, job['date'] ?? ''),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.access_time, job['time'] ?? ''),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'KES ' + (
                        status == BookingStatus.inprogress && job['invoiceAmount'] != null
                          ? (job['invoiceAmount'] as num).toStringAsFixed(2)
                          : ((job['amount'] ?? 0) as num).toStringAsFixed(2)
                      ),
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    Row(
                      children: [
                        if (status == BookingStatus.pending)
                          OutlinedButton.icon(
                            onPressed: () {
                              _showStatusUpdateDialog(
                                context,
                                job['id'],
                                'Start Job',
                                'Are you sure you want to start this job?',
                                'inprogress',
                              );
                            },
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Start'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.green,
                              side: const BorderSide(color: Colors.green),
                            ),
                          )
                        else if (status == BookingStatus.inprogress)
                          OutlinedButton.icon(
                            onPressed: () {
                              _showStatusUpdateDialog(
                                context,
                                job['id'],
                                'Complete Job',
                                'Are you sure you want to mark this job as completed?',
                                'completed',
                              );
                            },
                            icon: const Icon(Icons.check),
                            label: const Text('Complete'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.blue,
                              side: const BorderSide(color: Colors.blue),
                            ),
                          ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () {
                            // TODO: Navigate to job details
                          },
                          icon: const Icon(Icons.info_outline),
                          tooltip: 'View Details',
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          text,
          style: GoogleFonts.poppins(
            color: Colors.grey[600],
          ),
        ),
      ],
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