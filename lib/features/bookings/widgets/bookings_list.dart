import 'package:flutter/material.dart';
import 'package:nisacleanv1/features/bookings/widgets/booking_details_sheet.dart';
import 'package:nisacleanv1/features/bookings/screens/booking_details_screen.dart';
import 'package:nisacleanv1/features/bookings/models/booking.dart';

class BookingsList extends StatelessWidget {
  final List<Map<String, dynamic>> bookings;

  const BookingsList({
    super.key,
    required this.bookings,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final booking = bookings[index];
        final providerName = booking['providerName'] ?? booking['worker']?['name'] ?? '';
        return ListTile(
          onTap: () {
            // Navigate to BookingDetailsScreen (full screen)
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BookingDetailsScreen(
                  booking: Booking.fromJson(booking),
                ),
              ),
            );
          },
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _getStatusColor(booking['status']).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getStatusIcon(booking['status']),
              color: _getStatusColor(booking['status']),
            ),
          ),
          title: Text(
            booking['service'],
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${booking['date']} at ${booking['time']}',
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              ),
              if (providerName.isNotEmpty)
                Text(
                  'Provider: $providerName',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 12,
                  ),
                ),
            ],
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'KES ${(booking['amount'] ?? 0.0).toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(booking['status']).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getStatusLabel(booking['status']),
                  style: TextStyle(
                    color: _getStatusColor(booking['status']),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showBookingDetails(BuildContext context, Map<String, dynamic> booking) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.5,
        maxChildSize: 0.5,
        builder: (context, scrollController) => BookingDetailsSheet(
          booking: booking,
          scrollController: scrollController,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.pending_actions;
      case 'confirmed':
        return Icons.check_circle_outline;
      case 'completed':
        return Icons.done_all;
      default:
        return Icons.help_outline;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'confirmed':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      default:
        return status;
    }
  }
} 