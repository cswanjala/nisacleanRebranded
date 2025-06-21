import 'package:flutter/material.dart';
import 'package:nisacleanv1/features/payments/screens/payment_screen.dart';
import 'package:intl/intl.dart';

class BookingDetailsSheet extends StatelessWidget {
  final Map<String, dynamic> booking;
  final ScrollController? scrollController;

  const BookingDetailsSheet({
    super.key,
    required this.booking,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final location = booking['location'] as Map<String, dynamic>?;
    final address = location?['address'] ?? 'Not specified';
    final coordinates = location?['coordinates'] as List?;
    final lat = coordinates != null && coordinates.length == 2 ? coordinates[1] : null;
    final lng = coordinates != null && coordinates.length == 2 ? coordinates[0] : null;
    final amount = booking['amount'] is num ? (booking['amount'] as num).toDouble() : 0.0;
    final formattedAmount = NumberFormat('#,##0.00', 'en_US').format(amount);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF181A20)
            : const Color(0xFFF7F7F7),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
            // Drag handle
          Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 48,
              height: 5,
            decoration: BoxDecoration(
                color: Theme.of(context).dividerColor,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            // Header
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                const Text(
                  'Booking Details',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
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
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status
                    _buildStatusCard(context),
                    const SizedBox(height: 18),
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      elevation: 4,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF23262F)
                          : Theme.of(context).cardColor,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                            Row(
                              children: [
                                const Icon(Icons.cleaning_services, color: Colors.blue, size: 22),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    booking['service'] ?? '-',
                                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 17, color: Theme.of(context).textTheme.bodyLarge?.color),
            ),
          ),
        ],
      ),
                            const SizedBox(height: 14),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.location_on, color: Colors.redAccent, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                                      Text(
                                        address,
                                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Theme.of(context).textTheme.bodyMedium?.color),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (lat != null && lng != null)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 2),
              child: Text(
                                            'Lat: ${lat.toStringAsFixed(5)}, Lng: ${lng.toStringAsFixed(5)}',
                                            style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      elevation: 4,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF23262F)
                          : Theme.of(context).cardColor,
      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
          children: [
                            const Icon(Icons.calendar_today, color: Colors.deepPurple, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              booking['date'] ?? '-',
                              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15, color: Theme.of(context).textTheme.bodyMedium?.color),
                            ),
                            const SizedBox(width: 16),
                            const Icon(Icons.access_time, color: Colors.deepPurple, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              booking['time'] ?? '-',
                              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15, color: Theme.of(context).textTheme.bodyMedium?.color),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      elevation: 4,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF23262F)
                          : Theme.of(context).cardColor,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            const Icon(Icons.payments, color: Colors.green, size: 22),
                            const SizedBox(width: 8),
                            Text(
                              'KES $formattedAmount',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.green),
                            ),
                            const Spacer(),
                            Text(
                              _getPaymentStatus(),
                              style: TextStyle(fontWeight: FontWeight.w500, color: Theme.of(context).textTheme.bodySmall?.color),
                            ),
          ],
        ),
      ),
                    ),
                    if (booking['notes'] != null && (booking['notes'] as String).trim().isNotEmpty) ...[
                      const SizedBox(height: 18),
                      Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        elevation: 4,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF23262F)
                            : Theme.of(context).cardColor,
      child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                              const Icon(Icons.sticky_note_2, color: Colors.orange, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  booking['notes'],
                                  style: TextStyle(fontSize: 15, color: Theme.of(context).textTheme.bodyMedium?.color),
                                ),
                              ),
          ],
        ),
      ),
                      ),
                    ],
                    const SizedBox(height: 28),
                    if (booking['status'] != 'completed')
                      _buildActionButtons(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context) {
    final status = booking['status'] ?? 'pending';
    final statusColor = _getStatusColor();
    final statusLabel = _getStatusLabel();
    final statusIcon = _getStatusIcon();
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      color: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF23262F)
          : Theme.of(context).cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(statusIcon, color: statusColor, size: 22),
            const SizedBox(width: 8),
            Text(
              statusLabel,
              style: TextStyle(fontWeight: FontWeight.bold, color: statusColor, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getStatusIcon() {
    final status = booking['status'] ?? 'pending';
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

  Color _getStatusColor() {
    final status = booking['status'] ?? 'pending';
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

  String _getStatusLabel() {
    final status = booking['status'] ?? 'pending';
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

  String _getPaymentStatus() {
    final status = booking['status'] ?? 'pending';
    if (status == 'completed') return 'Paid';
    if (status == 'pending' || status == 'confirmation') return 'Awaiting Payment';
    if (status == 'inprogress') return 'In Progress';
    return 'N/A';
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: () {
              // TODO: Implement payment or other action
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PaymentScreen(
                    amount: booking['amount'] is num ? (booking['amount'] as num).toDouble() : 0.0,
                    reference: booking['id']?.toString() ?? '',
                    description: 'Payment for ${booking['service'] ?? ''}',
                  ),
                ),
              );
            },
            child: const Text('Pay Now', style: TextStyle(fontSize: 16)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.blue,
              side: const BorderSide(color: Colors.blue),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(fontSize: 16)),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
} 