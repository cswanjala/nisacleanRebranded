import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WorkerHomeScreen extends StatelessWidget {
  const WorkerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Welcome Back, John!',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
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
    );
  }

  Widget _buildTodaySchedule(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Today\'s Schedule',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildScheduleItem(
                  context,
                  'House Cleaning',
                  '10:00 AM - 12:00 PM',
                  '123 Main St, Nairobi',
                  Colors.blue,
                ),
                const Divider(),
                _buildScheduleItem(
                  context,
                  'Office Cleaning',
                  '2:00 PM - 4:00 PM',
                  '456 Business Ave, Nairobi',
                  Colors.green,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleItem(
    BuildContext context,
    String title,
    String time,
    String location,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      time,
                      style: GoogleFonts.poppins(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        location,
                        style: GoogleFonts.poppins(
                          color: Colors.grey[600],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios),
            onPressed: () {
              // TODO: Navigate to job details
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Stats',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                'Today\'s Jobs',
                '3',
                Icons.work,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                context,
                'Earnings',
                'KES 7,500',
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
                '4.8',
                Icons.star,
                Colors.amber,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                context,
                'Completed',
                '156',
                Icons.check_circle,
                Colors.purple,
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
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
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
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 3,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final activities = [
                {
                  'title': 'Job Completed',
                  'description': 'House Cleaning at 123 Main St',
                  'time': '2 hours ago',
                  'icon': Icons.check_circle,
                  'color': Colors.green,
                },
                {
                  'title': 'New Booking',
                  'description': 'Office Cleaning at 456 Business Ave',
                  'time': '4 hours ago',
                  'icon': Icons.work,
                  'color': Colors.blue,
                },
                {
                  'title': 'Payment Received',
                  'description': 'KES 2,500 for House Cleaning',
                  'time': '5 hours ago',
                  'icon': Icons.payment,
                  'color': Colors.purple,
                },
              ];

              final activity = activities[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: activity['color'] as Color,
                  child: Icon(
                    activity['icon'] as IconData,
                    color: Colors.white,
                  ),
                ),
                title: Text(
                  activity['title'] as String,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  activity['description'] as String,
                  style: GoogleFonts.poppins(),
                ),
                trailing: Text(
                  activity['time'] as String,
                  style: GoogleFonts.poppins(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
} 