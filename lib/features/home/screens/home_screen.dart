import 'package:flutter/material.dart';
import 'package:nisacleanv1/features/bookings/widgets/bookings_list.dart';
import 'package:nisacleanv1/features/home/widgets/service_card.dart';
import 'package:nisacleanv1/features/auth/screens/login_screen.dart';
import 'package:nisacleanv1/features/bookings/services/booking_service.dart';
import 'package:nisacleanv1/features/bookings/models/booking.dart';
import 'package:nisacleanv1/features/bookings/screens/all_bookings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final BookingService _bookingService = BookingService();
  List<Booking> _recentBookings = [];
  bool _isLoading = true;
  int _recentBookingsPage = 0; // Track which set of 3 is being shown

  @override
  void initState() {
    super.initState();
    _fetchRecentBookings();
  }

  Future<void> _fetchRecentBookings() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final bookings = await _bookingService.getBookings(limit: 3);
      if (!mounted) return;
      setState(() {
        _recentBookings = bookings;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _recentBookings = [];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'NisaClean',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Implement notifications
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // Show confirmation dialog
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        // Close the dialog
                        Navigator.pop(context);
                        // Navigate to login screen and clear the stack
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                          (route) => false,
                        );
                      },
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildServicesSection(),
                const SizedBox(height: 24),
                _buildPromoBanner(),
                const SizedBox(height: 24),
                _buildRecentBookings(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildServicesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Our Services',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () {
                // TODO: View all services
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.2,
          children: const [
            ServiceCard(
              icon: Icons.cleaning_services,
              title: 'House Cleaning',
              description: 'Professional home cleaning services',
              color: Color(0xFF1E88E5),
            ),
            ServiceCard(
              icon: Icons.business,
              title: 'Office Cleaning',
              description: 'Commercial space cleaning',
              color: Color(0xFF42A5F5),
            ),
            ServiceCard(
              icon: Icons.cleaning_services_outlined,
              title: 'Carpet Cleaning',
              description: 'Deep carpet cleaning and maintenance',
              color: Color(0xFF64B5F6),
            ),
            ServiceCard(
              icon: Icons.window,
              title: 'Window Cleaning',
              description: 'Crystal clear window cleaning',
              color: Color(0xFF90CAF9),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPromoBanner() {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF1E88E5), Color(0xFF42A5F5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(
              Icons.local_offer,
              size: 120,
              color: Colors.white.withOpacity(0.2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Special Offer',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Get 20% off on your first cleaning service',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Use code: WELCOME20',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: Implement offer redemption
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF1E88E5),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: const Text('Book Now'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentBookings() {
    final int pageSize = 3;
    final int start = _recentBookingsPage * pageSize;
    final int end = (start + pageSize).clamp(0, _recentBookings.length);
    final List<Booking> pagedBookings = _recentBookings.sublist(
      start,
      end,
    );
    final bool hasNextPage = end < _recentBookings.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Recent Bookings',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AllBookingsScreen(),
                  ),
                );
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else if (_recentBookings.isEmpty)
          _buildEmptyState('No recent bookings', Icons.history_outlined)
        else ...[
          BookingsList(
            bookings: pagedBookings
                .map((b) => {
                      'id': b.id,
                      'service': b.service,
                      'date': b.date,
                      'time': b.time,
                      'amount': b.amount,
                      'status': b.status.toString().split('.').last,
                    })
                .toList(),
          ),
          if (_recentBookings.length > pageSize)
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_upward, size: 32),
                    onPressed: _recentBookingsPage > 0
                        ? () {
                            setState(() {
                              _recentBookingsPage--;
                            });
                          }
                        : null,
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.arrow_downward, size: 32),
                    onPressed: hasNextPage
                        ? () {
                            setState(() {
                              _recentBookingsPage++;
                            });
                          }
                        : null,
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
} 