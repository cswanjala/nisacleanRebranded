import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nisacleanv1/core/constants/api_constants.dart';
import '../../../../core/bloc/auth/auth_bloc.dart';
import '../../../../core/bloc/auth/auth_event.dart';
import '../../../../core/bloc/auth/auth_state.dart';
import 'book_service_screen.dart';
import 'manage_services_screen.dart';
import 'set_availability_screen.dart';
import 'edit_profile_screen.dart';
import 'settings_screen.dart';
import 'help_support_screen.dart';
import 'service_search_screen.dart';
import 'my_bookings_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final List<Map<String, dynamic>> _notifications = [
    {
      'title': 'New Booking',
      'message': 'You have a new booking request for House Cleaning',
      'time': '2 hours ago',
      'isRead': false,
    },
    {
      'title': 'Payment Received',
      'message': 'Payment of \$75.00 has been received',
      'time': '1 day ago',
      'isRead': true,
    },
  ];

  final List<Map<String, dynamic>> _bookings = [
    {
      'id': 'BK001',
      'service': 'House Cleaning',
      'date': 'Today, 2:00 PM',
      'status': 'Confirmed',
      'price': '\$75.00',
      'address': '123 Main St, City',
      'provider': 'CleanPro Services',
      'rating': 4.5,
    },
    {
      'id': 'BK002',
      'service': 'Laundry Service',
      'date': 'Tomorrow, 10:00 AM',
      'status': 'Pending',
      'price': '\$60.00',
      'address': '456 Oak Ave, City',
      'provider': 'Fresh Laundry Co',
      'rating': 4.8,
    },
  ];

  final List<Map<String, dynamic>> _history = [
    {
      'id': 'H001',
      'service': 'House Cleaning',
      'date': 'March 15, 2024',
      'rating': 4.5,
      'price': '\$75.00',
      'provider': 'CleanPro Services',
      'status': 'Completed',
    },
    {
      'id': 'H002',
      'service': 'Laundry Service',
      'date': 'March 10, 2024',
      'rating': 5.0,
      'price': '\$60.00',
      'provider': 'Fresh Laundry Co',
      'status': 'Completed',
    },
  ];

  // Local variables to hold profile info
  String? _localName;
  String? _localEmail;
  List<Map<String, dynamic>> _activities = [];
  bool _isActivitiesLoading = false;
  String? _activitiesError;

  @override
  void initState() {
    super.initState();
    _fetchActivities();
  }

  Future<void> _fetchActivities() async {
    setState(() {
      _isActivitiesLoading = true;
      _activitiesError = null;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/activity/get-activities'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        setState(() {
          _activities = List<Map<String, dynamic>>.from(data['data'] ?? []);
          _isActivitiesLoading = false;
        });
      } else {
        setState(() {
          _activitiesError = data['message'] ?? 'Failed to fetch activities';
          _isActivitiesLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _activitiesError = e.toString();
        _isActivitiesLoading = false;
      });
    }
  }

  void _showNotificationSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Notifications',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ..._notifications.map((notification) => _buildNotificationItem(notification)),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem(Map<String, dynamic> notification) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: notification['isRead'] ? Colors.grey[200] : Theme.of(context).colorScheme.primary.withOpacity(0.1),
        child: Icon(
          notification['isRead'] ? Icons.notifications_none : Icons.notifications,
          color: notification['isRead'] ? Colors.grey : Theme.of(context).colorScheme.primary,
        ),
      ),
      title: Text(
        notification['title'],
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        notification['message'],
        style: GoogleFonts.poppins(
          color: Colors.grey[600],
        ),
      ),
      trailing: Text(
        notification['time'],
        style: GoogleFonts.poppins(
          color: Colors.grey[600],
          fontSize: 12,
        ),
      ),
    );
  }

  void _showBookingDetails(Map<String, dynamic> booking) {
    bool isCompleted = booking['status'] == 'Completed';
    bool isPending = booking['status'] == 'Pending';
    bool isCancelled = booking['status'] == 'Cancelled';
    bool isConfirmed = booking['status'] == 'Confirmed';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Booking Details',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildDetailRow('Booking ID', booking['id']),
              _buildDetailRow('Service', booking['service']),
              _buildDetailRow('Date & Time', booking['date']),
              _buildDetailRow('Status', booking['status']),
              _buildDetailRow('Price', booking['price']),
              _buildDetailRow('Address', booking['address']),
              _buildDetailRow('Provider', booking['provider']),
              if (isCompleted && booking['rating'] != null)
                _buildDetailRow('Rating', booking['rating'].toString()),
              const SizedBox(height: 16),
              if (isPending)
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            booking['status'] = 'Confirmed';
                          });
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Booking accepted!'), backgroundColor: Colors.green),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Accept'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            booking['status'] = 'Cancelled';
                          });
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Booking rejected!'), backgroundColor: Colors.red),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Reject'),
                      ),
                    ),
                  ],
                ),
              if (isConfirmed && !isCancelled)
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      booking['status'] = 'Cancelled';
                    });
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Booking cancelled!'), backgroundColor: Colors.red),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Cancel Booking'),
                ),
              if (isCompleted && booking['rating'] == null)
                ElevatedButton(
                  onPressed: () async {
                    double? rating = await _showRatingDialog(context);
                    if (rating != null) {
                      setState(() {
                        booking['rating'] = rating;
                      });
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Thank you for your rating!'), backgroundColor: Colors.blue),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber[700],
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Rate Service'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<double?> _showRatingDialog(BuildContext context) async {
    double rating = 5.0;
    return showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rate this service'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Slider(
                value: rating,
                min: 1,
                max: 5,
                divisions: 4,
                label: rating.toStringAsFixed(1),
                onChanged: (value) {
                  setState(() {
                    rating = value;
                  });
                },
              ),
              Text('${rating.toStringAsFixed(1)} Stars'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, rating),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        // Initialize local variables from state if not set
        _localName ??= state.name;
        _localEmail ??= state.email;
        return Scaffold(
          appBar: AppBar(
            title: Text(
              _getAppBarTitle(),
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {
                  // TODO: Show notifications
                },
              ),
              IconButton(
                icon: const Icon(Icons.person_outline),
                onPressed: () {
                  setState(() {
                    _selectedIndex = 3; // Switch to profile tab
                  });
                },
              ),
            ],
          ),
          body: _buildBody(state),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
              BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined), label: 'Bookings'),
              BottomNavigationBarItem(icon: Icon(Icons.history_outlined), label: 'History'),
              BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
            ],
          ),
        );
      },
    );
  }

  String _getAppBarTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Home';
      case 1:
        return 'Bookings';
      case 2:
        return 'History';
      case 3:
        return 'Profile';
      default:
        return 'Home';
    }
  }

  Widget _buildBody(AuthState state) {
    switch (_selectedIndex) {
      case 0:
        return _buildHomeContent(state);
      case 1:
        return _buildBookingsContent(state);
      case 2:
        return _buildHistoryContent(state);
      case 3:
        return _buildProfileContent(state);
      default:
        return _buildHomeContent(state);
    }
  }

  Widget _buildHomeContent(AuthState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(state),
          const SizedBox(height: 24),
          if (state.userType == UserType.client) ...[
            _buildClientDashboard(state),
          ] else ...[
            _buildProviderDashboard(state),
          ],
        ],
      ),
    );
  }

  Widget _buildBookingsContent(AuthState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Bookings',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          ..._bookings.map((booking) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildBookingCard(
                  context,
                  booking['service'],
                  booking['date'],
                  booking['status'],
                  booking['status'] == 'Confirmed' ? Colors.green : Colors.orange,
                  onTap: () => _showBookingDetails(booking),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildHistoryContent(AuthState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Service History',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          ..._history.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildHistoryCard(
                  context,
                  item['service'],
                  item['date'],
                  item['rating'].toString(),
                  item['price'],
                  onTap: () => _showBookingDetails(item),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildProfileContent(AuthState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  child: Icon(
                    state.userType == UserType.client ? Icons.person : Icons.cleaning_services,
                    size: 50,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _localName ?? 'User',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _localEmail ?? '',
                  style: GoogleFonts.poppins(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _buildProfileMenuItem(
            icon: Icons.person_outline,
            title: 'Edit Profile',
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditProfileScreen(
                    initialName: _localName ?? '',
                    initialEmail: _localEmail ?? '',
                    initialPhone: '0700000000', // mock phone
                    initialPhotoUrl: null, // mock photo
                  ),
                ),
              );
              if (result != null && result is Map<String, dynamic>) {
                setState(() {
                  _localName = result['name'];
                  _localEmail = result['email'];
                });
              }
            },
          ),
          _buildProfileMenuItem(
            icon: Icons.settings_outlined,
            title: 'Settings',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
          _buildProfileMenuItem(
            icon: Icons.help_outline,
            title: 'Help & Support',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HelpSupportScreen(),
                ),
              );
            },
          ),
          _buildProfileMenuItem(
            icon: Icons.logout,
            title: 'Logout',
            onTap: () {
              context.read<AuthBloc>().add(LogoutRequested());
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProfileMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(
        title,
        style: GoogleFonts.poppins(),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _buildHistoryCard(
    BuildContext context,
    String serviceName,
    String date,
    String rating,
    String amount, {
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    serviceName,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    amount,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    date,
                    style: GoogleFonts.poppins(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.star,
                    size: 16,
                    color: Colors.amber[700],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    rating,
                    style: GoogleFonts.poppins(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AuthState state) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: Icon(
              state.userType == UserType.client ? Icons.person : Icons.cleaning_services,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.userType == UserType.client ? 'Client Dashboard' : 'Service Provider Dashboard',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  state.userType == UserType.client
                      ? 'Book and manage your cleaning services'
                      : 'Manage your services and bookings',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientDashboard(AuthState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Quick Actions'),
        const SizedBox(height: 16),
        _buildQuickActions(state),
        const SizedBox(height: 24),
        _buildSectionTitle('My Services'),
        const SizedBox(height: 16),
        _buildServiceList(state),
      ],
    );
  }

  Widget _buildProviderDashboard(AuthState state) {
    // Mock data for earnings
    final Map<String, dynamic> earnings = {
      'today': 150.00,
      'week': 850.00,
      'month': 3200.00,
      'pending': 450.00,
    };

    // Filter today's bookings
    final todayBookings = _bookings.where((booking) {
      return booking['date'].toLowerCase().contains('today');
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Today\'s Overview'),
        const SizedBox(height: 16),
        _buildOverviewCards(earnings),
        const SizedBox(height: 24),
        _buildSectionTitle('Today\'s Bookings'),
        const SizedBox(height: 16),
        if (todayBookings.isEmpty)
          _buildEmptyState(
            'No bookings for today',
            Icons.calendar_today_outlined,
          )
        else
          ...todayBookings.map((booking) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildBookingCard(
                  context,
                  booking['service'],
                  booking['date'],
                  booking['status'],
                  _getStatusColor(booking['status']),
                  onTap: () => _showBookingDetails(booking),
                ),
              )),
        const SizedBox(height: 24),
        _buildSectionTitle('Recent Activity'),
        const SizedBox(height: 16),
        _buildRecentActivitySection(),
        const SizedBox(height: 24),
        _buildSectionTitle('Quick Actions'),
        const SizedBox(height: 16),
        _buildProviderQuickActions(state),
        const SizedBox(height: 24),
        _buildSectionTitle('Recent Bookings'),
        const SizedBox(height: 16),
        _buildRecentBookings(state),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildQuickActions(AuthState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.cleaning_services,
                title: 'Book Service',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ServiceSearchScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionCard(
                icon: Icons.calendar_today,
                title: 'My Bookings',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MyBookingsScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProviderQuickActions(AuthState state) {
    return Row(
      children: [
        Expanded(
          child: _buildActionCard(
            icon: Icons.cleaning_services,
            title: 'Manage Services',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ManageServicesScreen(),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildActionCard(
            icon: Icons.calendar_today,
            title: 'Set Availability',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SetAvailabilityScreen(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 32,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewCards(Map<String, dynamic> earnings) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildEarningsCard(
                'Today\'s Earnings',
                '\$${earnings['today'].toStringAsFixed(2)}',
                Icons.attach_money,
                Colors.green,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildEarningsCard(
                'Pending',
                '\$${earnings['pending'].toStringAsFixed(2)}',
                Icons.pending_actions,
                Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildEarningsCard(
                'This Week',
                '\$${earnings['week'].toStringAsFixed(2)}',
                Icons.calendar_view_week,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildEarningsCard(
                'This Month',
                '\$${earnings['month'].toStringAsFixed(2)}',
                Icons.calendar_month,
                Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEarningsCard(
    String title,
    String amount,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              amount,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceList(AuthState state) {
    return Column(
      children: [
        _buildServiceCard(
          'House Cleaning',
          'Regular cleaning service',
          Icons.cleaning_services,
          '\$50',
        ),
        const SizedBox(height: 12),
        _buildServiceCard(
          'Laundry Service',
          'Wash, dry, and fold',
          Icons.local_laundry_service,
          '\$30',
        ),
      ],
    );
  }

  Widget _buildServiceCard(
    String title,
    String subtitle,
    IconData icon,
    String price,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.poppins(
            color: Colors.grey[600],
          ),
        ),
        trailing: Text(
          price,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildRecentBookings(AuthState state) {
    // Filter recent bookings (last 5)
    final recentBookings = _bookings.take(5).toList();

    if (recentBookings.isEmpty) {
      return _buildEmptyState(
        'No recent bookings',
        Icons.history_outlined,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Bookings',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FullBookingsScreen(bookings: _bookings),
                  ),
                );
              },
              child: const Text('See All'),
            ),
          ],
        ),
        ...recentBookings.map((booking) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildBookingCard(
            context,
            booking['service'],
            booking['date'],
            booking['status'],
            _getStatusColor(booking['status']),
            onTap: () => _showBookingDetails(booking),
          ),
        )).toList(),
      ],
    );
  }

  Widget _buildEmptyState(
    String message,
    IconData icon,
  ) {
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
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(
    BuildContext context,
    String service,
    String time,
    String status,
    Color statusColor, {
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    service,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      status,
                      style: GoogleFonts.poppins(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    time,
                    style: GoogleFonts.poppins(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivitySection() {
    if (_isActivitiesLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_activitiesError != null) {
      return Center(
        child: Text(
          _activitiesError!,
          style: GoogleFonts.poppins(color: Colors.red),
        ),
      );
    }
    if (_activities.isEmpty) {
      return _buildEmptyState('No recent activity', Icons.history_outlined);
    }
    return Column(
      children: _activities.take(5).map((activity) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _ActivityCard(activity: activity),
      )).toList(),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final Map<String, dynamic> activity;
  const _ActivityCard({required this.activity});
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final timestamp = activity['timestamp'] != null
        ? DateTime.tryParse(activity['timestamp'])
        : null;
    final formattedTime = timestamp != null
        ? TimeOfDay.fromDateTime(timestamp).format(context)
        : '';
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: colorScheme.primary.withOpacity(0.1),
          child: Icon(Icons.flash_on, color: colorScheme.primary),
        ),
        title: Text(
          activity['type'] ?? 'Activity',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          activity['description'] ?? '',
          style: GoogleFonts.poppins(),
        ),
        trailing: Text(
          formattedTime,
          style: GoogleFonts.poppins(fontSize: 12, color: colorScheme.primary),
        ),
      ),
    );
  }
}

// Move _getStatusColor here as a top-level function
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
    case 'confirmed':
      return Colors.green;
    case 'pending':
      return Colors.orange;
    default:
      return Colors.grey;
  }
}

// --- Full Bookings Screen for large lists ---
class FullBookingsScreen extends StatefulWidget {
  final List<Map<String, dynamic>> bookings;
  const FullBookingsScreen({Key? key, required this.bookings}) : super(key: key);

  @override
  State<FullBookingsScreen> createState() => _FullBookingsScreenState();
}

class _FullBookingsScreenState extends State<FullBookingsScreen> {
  static const int _pageSize = 10;
  late List<Map<String, dynamic>> _allBookings;
  List<Map<String, dynamic>> _displayedBookings = [];
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 0;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _allBookings = widget.bookings;
    _loadMore();
  }

  Future<void> _refresh() async {
    setState(() {
      _displayedBookings.clear();
      _currentPage = 0;
      _hasMore = true;
      _isRefreshing = true;
    });
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate refresh
    _loadMore();
    setState(() {
      _isRefreshing = false;
    });
  }

  void _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate network delay
    final nextPage = _currentPage + 1;
    final start = _currentPage * _pageSize;
    final end = (start + _pageSize).clamp(0, _allBookings.length);
    if (start >= _allBookings.length) {
      setState(() {
        _hasMore = false;
        _isLoadingMore = false;
      });
      return;
    }
    setState(() {
      _displayedBookings.addAll(_allBookings.sublist(start, end));
      _currentPage = nextPage;
      _hasMore = end < _allBookings.length;
      _isLoadingMore = false;
    });
  }

  bool _onScrollNotification(ScrollNotification notification) {
    if (notification.metrics.pixels >= notification.metrics.maxScrollExtent - 100 && !_isLoadingMore && _hasMore) {
      _loadMore();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Bookings'),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: NotificationListener<ScrollNotification>(
          onNotification: _onScrollNotification,
          child: _displayedBookings.isEmpty && !_hasMore && !_isLoadingMore
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history_outlined, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text('No bookings found', style: GoogleFonts.poppins(fontSize: 18, color: Colors.grey[600])),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _displayedBookings.length + (_hasMore ? 1 : 0),
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    if (index >= _displayedBookings.length) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary),
                        ),
                      );
                    }
                    final booking = _displayedBookings[index];
                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: Icon(Icons.cleaning_services, color: Theme.of(context).colorScheme.primary, size: 32),
                        title: Text(booking['service'], style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                        subtitle: Text(booking['date'], style: GoogleFonts.poppins(color: Colors.grey[600])),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColor(booking['status']).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            booking['status'],
                            style: GoogleFonts.poppins(
                              color: _getStatusColor(booking['status']),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        onTap: () {
                          // Optionally show details
                        },
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
} 