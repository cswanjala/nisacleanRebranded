import 'package:flutter/material.dart';
import 'package:nisacleanv1/features/payments/screens/payment_screen.dart';
import 'package:nisacleanv1/features/location/screens/location_picker_screen.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:nisacleanv1/features/bookings/models/booking.dart';
import 'package:nisacleanv1/features/bookings/services/booking_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class BookingDetailsScreen extends StatefulWidget {
  final Booking booking;

  const BookingDetailsScreen({
    super.key,
    required this.booking,
  });

  @override
  State<BookingDetailsScreen> createState() => _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends State<BookingDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    final location = widget.booking.location.coordinates;
    final address = widget.booking.location.address;
    final lat = location.length == 2 ? location[1] : null;
    final lng = location.length == 2 ? location[0] : null;
    final amount = widget.booking.amount ?? 0.0;
    final formattedAmount = NumberFormat('#,##0.00', 'en_US').format(amount);
    final status = widget.booking.status.toString().split('.').last;

    return Scaffold(
      appBar: AppBar(
        title: Text('Booking Details', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.onBackground),
        actions: [
          if (widget.booking.status == BookingStatus.pending)
            IconButton(
              icon: const Icon(Icons.cancel_outlined),
              onPressed: () {
                // TODO: Implement cancel booking
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Cancel Booking'),
                    content: const Text('Are you sure you want to cancel this booking?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('No'),
                      ),
                      TextButton(
                        onPressed: () {
                          // TODO: Implement cancellation
                          Navigator.pop(context);
                          Navigator.pop(context);
                        },
                        child: const Text('Yes, Cancel'),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            _buildStatusBanner(context, status),
            const SizedBox(height: 18),
            _buildServiceCard(context),
            const SizedBox(height: 18),
            _buildProviderCard(context),
            const SizedBox(height: 18),
            _buildLocationCard(context, address, lat, lng),
            const SizedBox(height: 18),
            _buildScheduleCard(context),
            const SizedBox(height: 18),
            _buildPaymentCard(context, formattedAmount),
            if (widget.booking.notes.isNotEmpty) ...[
              const SizedBox(height: 18),
              _buildNotesCard(context),
            ],
            const SizedBox(height: 80), // For sticky action area
          ],
        ),
      ),
      bottomNavigationBar: _buildActionBar(context, status),
    );
  }

  Widget _buildStatusBanner(BuildContext context, String status) {
    final color = _getStatusColor(status);
    final label = _getStatusLabel(status);
    final icon = _getStatusIcon(status);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 3,
      color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF23262F) : Theme.of(context).cardColor,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const Icon(Icons.cleaning_services, color: Colors.blue, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.booking.service,
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 17),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProviderCard(BuildContext context) {
    final provider = widget.booking.worker;
    final providerName = provider?.name ?? 'N/A';
    final providerAvatar = null; // No avatar in BookingUser model
    final providerRating = null; // No rating in BookingUser model
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 3,
      color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF23262F) : Theme.of(context).cardColor,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.blueGrey[100],
              backgroundImage: providerAvatar != null ? NetworkImage(providerAvatar) : null,
              child: providerAvatar == null ? const Icon(Icons.person, color: Colors.grey) : null,
              radius: 22,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(providerName, style: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 15)),
                  if (providerRating != null)
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber[700], size: 16),
                        const SizedBox(width: 4),
                        Text(providerRating.toString(), style: GoogleFonts.poppins(fontSize: 13)),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationCard(BuildContext context, String address, dynamic lat, dynamic lng) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 3,
      color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF23262F) : Theme.of(context).cardColor,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.location_on, color: Colors.redAccent, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(address, style: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 15)),
                  if (lat != null && lng != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        'Lat: ${lat.toStringAsFixed(5)}, Lng: ${lng.toStringAsFixed(5)}',
                        style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleCard(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 3,
      color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF23262F) : Theme.of(context).cardColor,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: Colors.deepPurple, size: 20),
            const SizedBox(width: 8),
            Text(
              widget.booking.date,
              style: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 15),
            ),
            const SizedBox(width: 16),
            const Icon(Icons.access_time, color: Colors.deepPurple, size: 20),
            const SizedBox(width: 8),
            Text(
              widget.booking.time,
              style: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentCard(BuildContext context, String formattedAmount) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 3,
      color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF23262F) : Theme.of(context).cardColor,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const Icon(Icons.payments, color: Colors.green, size: 22),
            const SizedBox(width: 8),
            Text(
              'KES $formattedAmount',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.green),
            ),
            const Spacer(),
            Text(
              _getPaymentStatus(),
              style: GoogleFonts.poppins(fontWeight: FontWeight.w500, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesCard(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 3,
      color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF23262F) : Theme.of(context).cardColor,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.sticky_note_2, color: Colors.orange, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.booking.notes,
                style: GoogleFonts.poppins(fontSize: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionBar(BuildContext context, String status) {
    if (status == 'pending') {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PaymentScreen(
                  amount: widget.booking.amount ?? 0.0,
                  reference: widget.booking.id,
                  description: 'Payment for ${widget.booking.service}',
                ),
              ),
            );

            if (result == true) {
              // Payment successful, update booking status
              // TODO: Update booking status in backend
              if (mounted) {
                Navigator.pop(context, true);
              }
            }
          },
          child: Text('Pay Now', style: GoogleFonts.poppins(fontSize: 16)),
        ),
      );
    } else if (status == 'completed') {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber[700],
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          onPressed: () {
            // TODO: Implement rating logic
          },
          child: Text('Rate Service', style: GoogleFonts.poppins(fontSize: 16)),
        ),
      );
    }
    // Add more actions as needed
    return const SizedBox.shrink();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'confirmation':
        return Colors.amber;
      case 'inprogress':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'disputed':
        return Colors.deepOrange;
      case 'resolved':
        return Colors.teal;
      case 'closed':
        return Colors.grey;
      default:
        return Colors.orange;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'confirmation':
        return 'Awaiting Confirmation';
      case 'inprogress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      case 'disputed':
        return 'Disputed';
      case 'resolved':
        return 'Resolved';
      case 'closed':
        return 'Closed';
      default:
        return 'Pending';
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.hourglass_empty;
      case 'confirmation':
        return Icons.hourglass_top;
      case 'inprogress':
        return Icons.work_outline;
      case 'completed':
        return Icons.check_circle_outline;
      case 'cancelled':
        return Icons.cancel_outlined;
      case 'disputed':
        return Icons.report_problem_outlined;
      case 'resolved':
        return Icons.verified_user_outlined;
      case 'closed':
        return Icons.lock_outline;
      default:
        return Icons.hourglass_empty;
    }
  }

  String _getPaymentStatus() {
    final status = widget.booking.status.toString().split('.').last;
    if (status == 'completed') return 'Paid';
    if (status == 'pending' || status == 'confirmation') return 'Awaiting Payment';
    if (status == 'inprogress') return 'In Progress';
    return 'N/A';
  }
} 