import 'package:flutter/material.dart';
import 'package:nisacleanv1/features/payments/screens/payment_screen.dart';
import 'package:nisacleanv1/features/location/screens/location_picker_screen.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class BookingDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> booking;

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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.booking['id']),
        actions: [
          if (widget.booking['status'] == 'pending')
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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildStatusCard(),
          const SizedBox(height: 16),
          _buildServiceDetailsCard(),
          const SizedBox(height: 16),
          _buildScheduleCard(),
          const SizedBox(height: 16),
          _buildPaymentCard(),
          if (widget.booking['notes'] != null) ...[
            const SizedBox(height: 16),
            _buildNotesCard(),
          ],
        ],
      ),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Status',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getStatusColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _getStatusLabel(),
                style: TextStyle(
                  color: _getStatusColor(),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceDetailsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Service Details',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Service', widget.booking['service']),
            const SizedBox(height: 8),
            InkWell(
              onTap: () async {
                final location = await Navigator.push<LatLng>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LocationPickerScreen(
                      initialLocation: widget.booking['location'] != null
                          ? LatLng(
                              widget.booking['location']['latitude'],
                              widget.booking['location']['longitude'],
                            )
                          : null,
                    ),
                  ),
                );

                if (location != null) {
                  // TODO: Update location in backend
                  setState(() {
                    widget.booking['location'] = {
                      'latitude': location.latitude,
                      'longitude': location.longitude,
                    };
                  });
                }
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Location',
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        widget.booking['location'] != null
                            ? '${widget.booking['location']['latitude'].toStringAsFixed(4)}, ${widget.booking['location']['longitude'].toStringAsFixed(4)}'
                            : 'Not specified',
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.edit_location_alt,
                        size: 20,
                        color: Colors.blue,
                      ),
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

  Widget _buildScheduleCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Schedule',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Date', widget.booking['date']),
            const SizedBox(height: 8),
            _buildInfoRow('Time', widget.booking['time']),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Amount', 'KES ${widget.booking['amount'].toStringAsFixed(2)}'),
            const SizedBox(height: 8),
            _buildInfoRow('Payment Status', _getPaymentStatus()),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notes',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            Text(widget.booking['notes']),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    if (widget.booking['status'] == 'completed') return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (widget.booking['status'] == 'pending') ...[
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  // TODO: Implement reschedule
                },
                child: const Text('Reschedule'),
              ),
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: ElevatedButton(
              onPressed: () async {
                if (widget.booking['status'] == 'pending') {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PaymentScreen(
                        amount: widget.booking['amount'],
                        reference: widget.booking['id'],
                        description: 'Payment for ${widget.booking['service']}',
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
                } else if (widget.booking['status'] == 'confirmed') {
                  // Mark as completed
                  // TODO: Update booking status in backend
                  if (mounted) {
                    Navigator.pop(context, true);
                  }
                }
              },
              child: Text(widget.booking['status'] == 'pending' ? 'Pay Now' : 'Mark as Completed'),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    switch (widget.booking['status']) {
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

  String _getStatusLabel() {
    switch (widget.booking['status']) {
      case 'pending':
        return 'Pending';
      case 'confirmed':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      default:
        return widget.booking['status'];
    }
  }

  String _getPaymentStatus() {
    // TODO: Implement actual payment status logic
    return widget.booking['status'] == 'completed' ? 'Paid' : 'Pending';
  }
} 