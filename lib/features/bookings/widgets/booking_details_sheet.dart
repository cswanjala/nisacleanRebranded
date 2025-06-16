import 'package:flutter/material.dart';
import 'package:nisacleanv1/features/payments/screens/payment_screen.dart';

class BookingDetailsSheet extends StatelessWidget {
  final Map<String, dynamic> booking;

  const BookingDetailsSheet({
    super.key,
    required this.booking,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text(
                  'Booking Details',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusCard(),
                  const SizedBox(height: 16),
                  _buildServiceDetailsCard(),
                  const SizedBox(height: 16),
                  _buildScheduleCard(),
                  const SizedBox(height: 16),
                  _buildPaymentCard(),
                  if (booking['notes'] != null) ...[
                    const SizedBox(height: 16),
                    _buildNotesCard(),
                  ],
                  const SizedBox(height: 16),
                  if (booking['status'] != 'completed')
                    _buildActionButtons(context),
                ],
              ),
            ),
          ),
        ],
      ),
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
            _buildInfoRow('Service', booking['service']),
            const SizedBox(height: 8),
            _buildInfoRow('Location', booking['location'] ?? 'Not specified'),
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
            _buildInfoRow('Date', booking['date']),
            const SizedBox(height: 8),
            _buildInfoRow('Time', booking['time']),
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
            _buildInfoRow('Amount', 'KES ${booking['amount'].toStringAsFixed(2)}'),
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
            Text(booking['notes']),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        if (booking['status'] == 'pending') ...[
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
              if (booking['status'] == 'pending') {
                Navigator.pop(context); // Close the bottom sheet
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PaymentScreen(
                      amount: booking['amount'],
                      reference: booking['id'],
                      description: 'Payment for ${booking['service']}',
                    ),
                  ),
                );

                if (result == true) {
                  // Payment successful, update booking status
                  // TODO: Update booking status in backend
                  if (context.mounted) {
                    // Show success message or refresh the list
                  }
                }
              } else if (booking['status'] == 'confirmed') {
                // Mark as completed
                // TODO: Update booking status in backend
                if (context.mounted) {
                  Navigator.pop(context);
                }
              }
            },
            child: Text(booking['status'] == 'pending' ? 'Pay Now' : 'Mark as Completed'),
          ),
        ),
      ],
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

  Color _getStatusColor() {
    switch (booking['status']) {
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
    switch (booking['status']) {
      case 'pending':
        return 'Pending';
      case 'confirmed':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      default:
        return booking['status'];
    }
  }

  String _getPaymentStatus() {
    // TODO: Implement actual payment status logic
    return booking['status'] == 'completed' ? 'Paid' : 'Pending';
  }
} 