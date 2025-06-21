import 'package:flutter/material.dart';
import 'package:nisacleanv1/features/payments/screens/payment_screen.dart';
import 'package:nisacleanv1/features/location/screens/location_picker_screen.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:nisacleanv1/features/bookings/models/booking.dart';
import 'package:nisacleanv1/features/bookings/services/booking_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
    final colorScheme = Theme.of(context).colorScheme;
    final location = widget.booking.location.coordinates;
    final address = widget.booking.location.address;
    final lat = location.length == 2 ? location[1] : null;
    final lng = location.length == 2 ? location[0] : null;
    final amount = widget.booking.amount ?? 0.0;
    final formattedAmount = NumberFormat('#,##0.00', 'en_US').format(amount);
    final status = widget.booking.status.toString().split('.').last;

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: Text('Booking Details', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
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
            _AnimatedSection(child: _StatusBanner(status: status)),
            const SizedBox(height: 18),
            _AnimatedSection(child: _ServiceCard(service: widget.booking.service)),
            const SizedBox(height: 18),
            _AnimatedSection(child: _ProviderCard(provider: widget.booking.worker)),
            const SizedBox(height: 18),
            _AnimatedSection(child: _LocationCard(address: address, lat: lat, lng: lng)),
            const SizedBox(height: 18),
            _AnimatedSection(child: _ScheduleCard(date: widget.booking.date, time: widget.booking.time)),
            const SizedBox(height: 18),
            _AnimatedSection(child: _PaymentCard(amount: formattedAmount, paymentStatus: _getPaymentStatus(status), status: status)),
            if (widget.booking.notes.isNotEmpty) ...[
              const SizedBox(height: 18),
              _AnimatedSection(child: _NotesCard(notes: widget.booking.notes)),
            ],
            const SizedBox(height: 80), // For sticky action area
          ],
        ),
      ),
      bottomNavigationBar: _ActionBar(status: status, booking: widget.booking),
      backgroundColor: colorScheme.background,
    );
  }

  Widget _StatusBanner({required String status}) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = colorScheme.primaryContainer;
    final textColor = colorScheme.onPrimaryContainer;
    final label = _getStatusLabel(status);
    final icon = _getStatusIcon(status);
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
          children: [
          Container(
            height: 56,
            decoration: BoxDecoration(
              color: color,
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: textColor, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              ),
            ),
          ],
      ),
    );
  }

  Widget _ServiceCard({required String service}) {
    final colorScheme = Theme.of(context).colorScheme;
    return _GlassCard(
      child: Row(
          children: [
          Icon(Icons.cleaning_services, color: colorScheme.primary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              service,
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 19, color: colorScheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ProviderCard({required dynamic provider}) {
    final colorScheme = Theme.of(context).colorScheme;
    final providerName = provider?.name ?? 'N/A';
    final initials = providerName.isNotEmpty ? providerName.trim().split(' ').map((e) => e[0]).take(2).join() : 'N';
    return _GlassCard(
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: colorScheme.primary,
            child: Text(initials, style: GoogleFonts.poppins(color: colorScheme.onPrimary, fontWeight: FontWeight.bold)),
            radius: 22,
          ),
          const SizedBox(width: 14),
          Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                Text(providerName, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16, color: colorScheme.onSurface)),
                Text('Service Provider', style: GoogleFonts.poppins(fontSize: 13, color: colorScheme.onSurface.withOpacity(0.6))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _LocationCard({required String address, dynamic lat, dynamic lng}) {
    final colorScheme = Theme.of(context).colorScheme;
    return _GlassCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.location_on, color: colorScheme.secondary, size: 22),
          const SizedBox(width: 12),
          Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                Text(address, style: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 15, color: colorScheme.onSurface)),
                if (lat != null && lng != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      'Lat: ${lat.toStringAsFixed(5)}, Lng: ${lng.toStringAsFixed(5)}',
                      style: GoogleFonts.poppins(color: colorScheme.onSurface.withOpacity(0.6), fontSize: 12),
                    ),
                  ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    'https://maps.googleapis.com/maps/api/staticmap?center=${lat ?? 0},${lng ?? 0}&zoom=15&size=400x120&markers=color:red%7C${lat ?? 0},${lng ?? 0}&key=YOUR_GOOGLE_MAPS_API_KEY',
                    height: 80,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 80,
                      color: colorScheme.surface,
                      alignment: Alignment.center,
                      child: Icon(Icons.map, color: colorScheme.onSurface.withOpacity(0.3)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _ScheduleCard({required String date, required String time}) {
    final colorScheme = Theme.of(context).colorScheme;
    return _GlassCard(
      child: Row(
      children: [
          Icon(Icons.calendar_today, color: colorScheme.secondary, size: 20),
          const SizedBox(width: 8),
        Text(
            date,
            style: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 15, color: colorScheme.onSurface),
          ),
          const SizedBox(width: 16),
          Icon(Icons.access_time, color: colorScheme.secondary, size: 20),
          const SizedBox(width: 8),
        Text(
            time,
            style: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 15, color: colorScheme.onSurface),
          ),
        ],
      ),
    );
  }

  Widget _PaymentCard({required String amount, required String paymentStatus, required String status}) {
    final colorScheme = Theme.of(context).colorScheme;
    final badgeColor = colorScheme.secondaryContainer;
    final badgeTextColor = colorScheme.onSecondaryContainer;
    return _GlassCard(
      child: Row(
        children: [
          Icon(Icons.payments, color: colorScheme.primary, size: 22),
          const SizedBox(width: 8),
          Text(
            'KES $amount',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 22, color: colorScheme.primary),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              paymentStatus,
              style: GoogleFonts.poppins(fontWeight: FontWeight.w500, color: badgeTextColor, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _NotesCard({required String notes}) {
    final colorScheme = Theme.of(context).colorScheme;
    return _GlassCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: colorScheme.secondary,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              notes,
              style: GoogleFonts.poppins(fontSize: 15, fontStyle: FontStyle.italic, color: colorScheme.onSurface.withOpacity(0.8)),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surface.withOpacity(0.85),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withOpacity(0.07),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: colorScheme.outline.withOpacity(0.08),
              width: 1.2,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _AnimatedSection extends StatelessWidget {
  final Widget child;
  const _AnimatedSection({required this.child});
  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
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

String _getPaymentStatus(String status) {
  if (status == 'completed') return 'Paid';
  if (status == 'pending' || status == 'confirmation') return 'Awaiting Payment';
  if (status == 'inprogress') return 'In Progress';
  return 'N/A';
}

class _ActionBar extends StatefulWidget {
  final String status;
  final Booking booking;
  const _ActionBar({required this.status, required this.booking});
  @override
  State<_ActionBar> createState() => _ActionBarState();
}

class _ActionBarState extends State<_ActionBar> {
  bool _isClosing = false;
  bool _isClosed = false;
  bool _isDisputing = false;
  bool _isDisputed = false;

  @override
  void initState() {
    super.initState();
    _isClosed = widget.status == 'closed';
    _isDisputed = widget.status == 'disputed';
  }

  @override
  void didUpdateWidget(covariant _ActionBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    _isClosed = widget.status == 'closed';
    _isDisputed = widget.status == 'disputed';
  }

  Future<void> _handleCloseBooking() async {
    setState(() => _isClosing = true);
    String bookingId = widget.booking.id;
    try {
      await BookingService().markBookingAsClosed(bookingId);
      setState(() {
        _isClosed = true;
        _isClosing = false;
      });
      await _showRatingDialog();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking closed successfully.')),
      );
    } catch (e) {
      setState(() => _isClosing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to close booking: $e')),
      );
    }
  }

  Future<void> _handleDisputeBooking() async {
    setState(() => _isDisputing = true);
    String bookingId = widget.booking.id;
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) {
        final reasonController = TextEditingController();
        final detailsController = TextEditingController();
        return AlertDialog(
          title: const Text('Dispute Booking'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(labelText: 'Reason'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: detailsController,
                decoration: const InputDecoration(labelText: 'Details'),
                minLines: 2,
                maxLines: 4,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (reasonController.text.trim().isEmpty || detailsController.text.trim().isEmpty) return;
                Navigator.pop(ctx, {
                  'reason': reasonController.text.trim(),
                  'details': detailsController.text.trim(),
                });
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
    if (result != null) {
      try {
        await BookingService().createBookingDispute(
          bookingId: bookingId,
          reason: result['reason']!,
          description: result['details']!,
        );
        setState(() {
          _isDisputed = true;
          // Also update the status to 'disputed' so the action bar hides
          // (if you want to update the parent Booking object, you may need a callback)
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent),
                SizedBox(width: 12),
                Expanded(child: Text('Dispute submitted. Our team will review your case.')),
              ],
            ),
            backgroundColor: Colors.grey[900],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 4),
          ),
        );
      } catch (e) {
        setState(() => _isDisputing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit dispute: $e')),
        );
      }
    } else {
      setState(() => _isDisputing = false);
    }
  }

  Future<void> _showRatingDialog() async {
    double? rating;
    String? feedback;
    bool submitted = false;
    bool isLoading = false;
    await showDialog(
      context: context,
      barrierDismissible: !isLoading,
      builder: (ctx) {
        double tempRating = 0;
        final feedbackController = TextEditingController();
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Rate Service', style: TextStyle(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (i) => IconButton(
                        icon: Icon(
                          tempRating > i - 0.5 ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 32,
                        ),
                        onPressed: isLoading ? null : () {
                          setState(() {
                            tempRating = i + 1.0;
                          });
                          rating = tempRating;
                        },
                      )),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: feedbackController,
                      enabled: !isLoading,
                      decoration: InputDecoration(
                        labelText: 'Feedback (optional)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      minLines: 2,
                      maxLines: 4,
                    ),
                  ],
                ),
              ),
              actionsPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(ctx),
                  child: const Text('Skip'),
                ),
                ElevatedButton(
                  onPressed: (rating == null || isLoading)
                      ? null
                      : () async {
                          setState(() { isLoading = true; });
                          feedback = feedbackController.text.trim();
                          try {
                            await BookingService().submitReview(
                              bookingId: widget.booking.id,
                              rating: rating!,
                              review: feedback ?? '',
                            );
                            if (context.mounted) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: const [
                                      Icon(Icons.star, color: Colors.amber),
                                      SizedBox(width: 12),
                                      Expanded(child: Text('Thank you for your review!')),
                                    ],
                                  ),
                                  backgroundColor: Colors.grey[900],
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  margin: const EdgeInsets.all(16),
                                  duration: const Duration(seconds: 4),
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: const [
                                      Icon(Icons.error_outline, color: Colors.redAccent),
                                      SizedBox(width: 12),
                                      Expanded(child: Text('Failed to submit review. Please try again.')),
                                    ],
                                  ),
                                  backgroundColor: Colors.grey[900],
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  margin: const EdgeInsets.all(16),
                                  duration: const Duration(seconds: 4),
                                ),
                              );
                            }
                          }
                          setState(() { isLoading = false; });
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                      : const Text('Submit'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (widget.status == 'pending') {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Material(
          elevation: 12,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          color: colorScheme.surface,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                // TODO: Implement payment logic
              },
              child: Ink(
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text('Pay Now', style: GoogleFonts.poppins(fontSize: 16, color: colorScheme.onPrimary)),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    } else if (widget.status == 'completed' && !_isClosed && !_isDisputed) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Material(
          elevation: 12,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          color: colorScheme.surface,
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _isClosing ? null : _handleCloseBooking,
                  child: _isClosing
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Close Booking'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton(
                  onPressed: _isDisputing ? null : _handleDisputeBooking,
                  child: _isDisputing
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Dispute Booking'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorScheme.primary,
                    side: BorderSide(color: colorScheme.primary),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } else if (_isClosed) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Material(
          elevation: 12,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          color: colorScheme.surface,
          child: Center(
            child: Text('Booking Closed', style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold)),
          ),
        ),
      );
    } else if (_isDisputed || widget.status == 'disputed') {
      // Hide the action bar, just return an empty box
      return const SizedBox.shrink();
    }
    return const SizedBox.shrink();
  }
}