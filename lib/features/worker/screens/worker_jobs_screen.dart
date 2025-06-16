import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WorkerJobsScreen extends StatelessWidget {
  const WorkerJobsScreen({super.key});

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
          bottom: TabBar(
            tabs: [
              Tab(text: 'Pending'),
              Tab(text: 'In Progress'),
              Tab(text: 'Completed'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildJobList(context, 'pending'),
            _buildJobList(context, 'in_progress'),
            _buildJobList(context, 'completed'),
          ],
        ),
      ),
    );
  }

  Widget _buildJobList(BuildContext context, String status) {
    // TODO: Replace with actual data from API
    final jobs = [
      {
        'id': 'JOB001',
        'title': 'House Cleaning',
        'customer': 'John Doe',
        'address': '123 Main St, Nairobi',
        'date': '2024-03-20',
        'time': '10:00 AM - 12:00 PM',
        'amount': 2500.0,
      },
      {
        'id': 'JOB002',
        'title': 'Office Cleaning',
        'customer': 'Jane Smith',
        'address': '456 Business Ave, Nairobi',
        'date': '2024-03-20',
        'time': '2:00 PM - 4:00 PM',
        'amount': 3500.0,
      },
    ];

    if (jobs.isEmpty) {
      return Center(
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
              'No $status jobs',
              style: GoogleFonts.poppins(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
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
                      job['title'] as String,
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
                        status.toUpperCase(),
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
                _buildInfoRow(Icons.person, job['customer'] as String),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.location_on, job['address'] as String),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.calendar_today, job['date'] as String),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.access_time, job['time'] as String),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'KES ${(job['amount'] as double).toStringAsFixed(2)}',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    Row(
                      children: [
                        if (status == 'pending')
                          OutlinedButton.icon(
                            onPressed: () {
                              _showStatusUpdateDialog(
                                context,
                                job['id'] as String,
                                'Start Job',
                                'Are you sure you want to start this job?',
                                'in_progress',
                              );
                            },
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Start'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.green,
                              side: const BorderSide(color: Colors.green),
                            ),
                          )
                        else if (status == 'in_progress')
                          OutlinedButton.icon(
                            onPressed: () {
                              _showStatusUpdateDialog(
                                context,
                                job['id'] as String,
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'in_progress':
        return Colors.blue;
      case 'completed':
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
            onPressed: () {
              // TODO: Update job status in API
              // TODO: Send notification to client
              Navigator.pop(context);
            },
            child: Text(actionTitle),
          ),
        ],
      ),
    );
  }
} 