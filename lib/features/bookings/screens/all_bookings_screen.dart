import 'package:flutter/material.dart';
import 'package:nisacleanv1/features/bookings/services/booking_service.dart';
import 'package:nisacleanv1/features/bookings/models/booking.dart';

class AllBookingsScreen extends StatefulWidget {
  const AllBookingsScreen({Key? key}) : super(key: key);

  @override
  State<AllBookingsScreen> createState() => _AllBookingsScreenState();
}

class _AllBookingsScreenState extends State<AllBookingsScreen> {
  final BookingService _bookingService = BookingService();
  final List<Booking> _bookings = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  final int _pageSize = 20;
  String? _error;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchBookings();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchBookings({bool refresh = false}) async {
    if (_isLoading || _isLoadingMore) return;
    if (refresh) {
      setState(() {
        _bookings.clear();
        _currentPage = 1;
        _hasMore = true;
        _error = null;
      });
    }
    setState(() {
      if (_currentPage == 1) {
        _isLoading = true;
      } else {
        _isLoadingMore = true;
      }
      _error = null;
    });
    try {
      final bookings = await _bookingService.getBookings(page: _currentPage, limit: _pageSize);
      setState(() {
        _bookings.addAll(bookings);
        _hasMore = bookings.length == _pageSize;
        _isLoading = false;
        _isLoadingMore = false;
        _currentPage++;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 && !_isLoadingMore && _hasMore) {
      _fetchBookings();
    }
  }

  Future<void> _onRefresh() async {
    await _fetchBookings(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Bookings'),
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: _isLoading && _bookings.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Error loading bookings', style: const TextStyle(fontSize: 16, color: Colors.red)),
                        const SizedBox(height: 8),
                        Text(_error!, style: const TextStyle(fontSize: 14, color: Colors.red)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => _fetchBookings(refresh: true),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : _bookings.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.history_outlined, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('No bookings found', style: TextStyle(fontSize: 18, color: Colors.grey)),
                          ],
                        ),
                      )
                    : ListView.separated(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _bookings.length + (_hasMore ? 1 : 0),
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          if (index >= _bookings.length) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }
                          final booking = _bookings[index];
                          return Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              leading: Icon(Icons.cleaning_services, color: Theme.of(context).colorScheme.primary),
                              title: Text(booking.service),
                              subtitle: Text('${booking.date} at ${booking.time}'),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('KES ${(booking.amount ?? 0.0).toStringAsFixed(2)}'),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(booking.status).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      _getStatusLabel(booking.status),
                                      style: TextStyle(
                                        color: _getStatusColor(booking.status),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () {
                                // Optionally show booking details
                              },
                            ),
                          );
                        },
                      ),
      ),
    );
  }

  Color _getStatusColor(dynamic status) {
    final s = status.toString().toLowerCase();
    switch (s) {
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

  String _getStatusLabel(dynamic status) {
    final s = status.toString().toLowerCase();
    switch (s) {
      case 'upcoming':
        return 'Upcoming';
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      case 'confirmed':
        return 'Confirmed';
      case 'pending':
        return 'Pending';
      default:
        return s;
    }
  }
} 