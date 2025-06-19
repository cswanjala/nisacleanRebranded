import 'package:flutter/material.dart';
import 'package:nisacleanv1/features/bookings/screens/new_booking_screen.dart';
import 'package:nisacleanv1/features/bookings/screens/booking_details_screen.dart';
import 'package:nisacleanv1/features/bookings/services/booking_service.dart';
import 'package:nisacleanv1/features/bookings/models/booking.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _bookingService = BookingService();
  List<Booking> _bookings = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadBookings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBookings() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final bookings = await _bookingService.getBookings();
      
      setState(() {
        _bookings = bookings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      
      // Show a specific message for admin privileges error
      if (e.toString().contains('admin privileges')) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Booking history feature is currently being updated. Please try again later.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 5),
            ),
          );
        }
      }
    }
  }

  List<Booking> _getFilteredBookings(String status) {
    return _bookings.where((booking) => booking.status.toString().split('.').last == status).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBookings,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'In Progress'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Error loading bookings',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadBookings,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : TabBarView(
        controller: _tabController,
        children: [
          _buildBookingList('pending'),
                    _buildBookingList('inprogress'),
          _buildBookingList('completed'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const NewBookingScreen(),
            ),
          );
          // Refresh bookings if a new booking was created
          if (result == true) {
            _loadBookings();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBookingList(String status) {
    final filteredBookings = _getFilteredBookings(status);

    if (filteredBookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No ${status.toLowerCase()} bookings',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the + button to create a new booking',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredBookings.length,
      itemBuilder: (context, index) {
        final booking = filteredBookings[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BookingDetailsScreen(
                    booking: {
                      'id': booking.id,
                      'service': booking.service,
                      'date': booking.date,
                      'time': booking.time,
                      'status': booking.status.toString().split('.').last,
                      'amount': booking.amount,
                      'notes': booking.notes,
                      'location': {
                        'address': booking.location.address,
                        'coordinates': booking.location.coordinates,
                      },
                      'user': {
                        'name': booking.user.name,
                        'email': booking.user.email,
                      },
                      'worker': booking.worker != null ? {
                        'name': booking.worker!.name,
                        'email': booking.worker!.email,
                      } : null,
                    },
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        booking.id.substring(0, 8), // Show first 8 chars of ID
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      _buildStatusChip(booking.status.toString().split('.').last),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    booking.service,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 16),
                      const SizedBox(width: 8),
                      Text(booking.date),
                      const SizedBox(width: 16),
                      const Icon(Icons.access_time, size: 16),
                      const SizedBox(width: 8),
                      Text(booking.time),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        booking.amount != null 
                            ? 'KES ${booking.amount!.toStringAsFixed(2)}'
                            : 'Price TBD',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 16),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;

    switch (status) {
      case 'pending':
        color = Colors.orange;
        label = 'Pending';
        break;
      case 'confirmation':
        color = Colors.blue;
        label = 'Confirmation';
        break;
      case 'inprogress':
        color = Colors.purple;
        label = 'In Progress';
        break;
      case 'completed':
        color = Colors.green;
        label = 'Completed';
        break;
      case 'cancelled':
        color = Colors.red;
        label = 'Cancelled';
        break;
      case 'disputed':
        color = Colors.red;
        label = 'Disputed';
        break;
      case 'resolved':
        color = Colors.blue;
        label = 'Resolved';
        break;
      case 'closed':
        color = Colors.grey;
        label = 'Closed';
        break;
      default:
        color = Colors.grey;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
} 