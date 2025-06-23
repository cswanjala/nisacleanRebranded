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
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nisacleanv1/core/bloc/auth/auth_bloc.dart';
import 'package:nisacleanv1/core/bloc/auth/auth_state.dart';

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
  late Booking _booking;
  late List<_StepData> _steps;
  late int _currentStep;

  @override
  void initState() {
    super.initState();
    _booking = widget.booking;
    _steps = _buildSteps(_booking.status);
    _currentStep = _getStepIndex(_booking.status);
  }

  Future<void> _refreshBooking() async {
    final updated = await BookingService().getBookingById(_booking.id);
    setState(() {
      _booking = updated;
      _steps = _buildSteps(_booking.status);
      _currentStep = _getStepIndex(_booking.status);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final location = _booking.location.coordinates;
    final address = _booking.location.address;
    final lat = location.length == 2 ? location[1] : null;
    final lng = location.length == 2 ? location[0] : null;
    final amount = _booking.amount ?? 0.0;
    final formattedAmount = NumberFormat('#,##0.00', 'en_US').format(amount);
    final status = _booking.status.toString().split('.').last;
    final provider = _booking.worker;
    final providerName = provider?.name ?? 'N/A';
    final initials = providerName.isNotEmpty ? providerName.trim().split(' ').map((e) => e[0]).take(2).join() : 'N';

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: Text('Booking Details', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
        actions: [
          if (_booking.status == BookingStatus.pending)
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          children: [
            _AnimatedSection(
              child: _StatusBanner(status: status),
            ),
            const SizedBox(height: 18),
            _AnimatedSection(
              child: _BookingStepper(steps: _steps, currentStep: _currentStep),
            ),
            const SizedBox(height: 24),
            _AnimatedSection(
              child: _GlassCard(
                child: Row(
                  children: [
                    Icon(Icons.cleaning_services, color: colorScheme.primary, size: 28),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        _booking.service,
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 20, color: colorScheme.onSurface),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            _AnimatedSection(
              child: _GlassCard(
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
              ),
            ),
            const SizedBox(height: 18),
            _AnimatedSection(
              child: _GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.location_on, color: colorScheme.secondary, size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(address, style: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 15, color: colorScheme.onSurface)),
                        ),
                      ],
                    ),
                    if (lat != null && lng != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SizedBox(
                            height: 120,
                            child: GoogleMap(
                              initialCameraPosition: CameraPosition(
                                target: LatLng(lat, lng),
                                zoom: 15,
                              ),
                              markers: {
                                Marker(
                                  markerId: const MarkerId('service_location'),
                                  position: LatLng(lat, lng),
                                ),
                              },
                              zoomControlsEnabled: false,
                              myLocationButtonEnabled: false,
                              liteModeEnabled: true,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            _AnimatedSection(
              child: _GlassCard(
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, color: colorScheme.secondary, size: 20),
                    const SizedBox(width: 8),
                    Text(_booking.date, style: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 15, color: colorScheme.onSurface)),
                    const SizedBox(width: 16),
                    Icon(Icons.access_time, color: colorScheme.secondary, size: 20),
                    const SizedBox(width: 8),
                    Text(_booking.time, style: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 15, color: colorScheme.onSurface)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            if (_booking.notes.isNotEmpty) ...[
              _AnimatedSection(
                child: _GlassCard(
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
                          _booking.notes,
                          style: GoogleFonts.poppins(fontSize: 15, fontStyle: FontStyle.italic, color: colorScheme.onSurface.withOpacity(0.8)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 18),
            _AnimatedSection(
              child: _GlassCard(
                child: Row(
                  children: [
                    Icon(Icons.payments, color: colorScheme.primary, size: 22),
                    const SizedBox(width: 8),
                    Text('KES $formattedAmount', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 22, color: colorScheme.primary)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(_getPaymentStatus(status), style: GoogleFonts.poppins(fontWeight: FontWeight.w500, color: colorScheme.onSecondaryContainer, fontSize: 13)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomNavigationBar: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          final isClient = authState.userType == UserType.client;
          final isWorker = authState.userType == UserType.serviceProvider;
          print('[DEBUG] BookingDetailsScreen: userType = \\${authState.userType}, status = "${status}"');
          if (status == 'pending' && isClient) {
            return _ActionBar(
              color: colorScheme.surface,
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.orange),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('Booking is awaiting invoice from the service provider.', style: GoogleFonts.poppins(color: Colors.orange, fontWeight: FontWeight.w500)),
                  ),
                ],
              ),
            );
          } else if (status == 'confirmation' && isClient) {
            return _ActionBar(
              color: colorScheme.surface,
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Implement payment action
                      },
                      icon: const Icon(Icons.payment),
                      label: Text('Pay KES $formattedAmount'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            );
          } else if (status == 'completed' && isClient) {
            return _CloseBookingActionBar(
              bookingId: _booking.id,
              onClosed: _refreshBooking,
            );
          }
          return const SizedBox.shrink();
        },
      ),
      backgroundColor: colorScheme.background,
    );
  }
}

class _BookingStepper extends StatelessWidget {
  final List<_StepData> steps;
  final int currentStep;
  const _BookingStepper({required this.steps, required this.currentStep});
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: List.generate(steps.length, (index) {
        final step = steps[index];
        final isActive = index <= currentStep;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isActive ? colorScheme.primary : colorScheme.surfaceVariant,
                    shape: BoxShape.circle,
                    border: Border.all(color: colorScheme.primary, width: 2),
                  ),
                  child: Icon(step.icon, color: isActive ? Colors.white : colorScheme.primary, size: 16),
                ),
                if (index < steps.length - 1)
                  Container(
                    width: 4,
                    height: 32,
                    color: isActive ? colorScheme.primary : colorScheme.surfaceVariant,
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(step.label, style: GoogleFonts.poppins(fontWeight: isActive ? FontWeight.bold : FontWeight.normal, color: isActive ? colorScheme.primary : colorScheme.onSurface.withOpacity(0.5))),
            ),
          ],
        );
      }),
    );
  }
}

class _StepData {
  final String label;
  final IconData icon;
  _StepData(this.label, this.icon);
}

List<_StepData> _buildSteps(BookingStatus status) {
  return [
    _StepData('Pending', Icons.hourglass_empty),
    _StepData('Invoice', Icons.receipt_long),
    _StepData('Confirmation', Icons.hourglass_top),
    _StepData('In Progress', Icons.cleaning_services),
    _StepData('Completed', Icons.check_circle),
  ];
}

int _getStepIndex(BookingStatus status) {
  switch (status) {
    case BookingStatus.pending:
      return 0;
    case BookingStatus.confirmation:
      return 2;
    case BookingStatus.inprogress:
      return 3;
    case BookingStatus.completed:
      return 4;
    default:
      return 0;
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
        child: Padding(
          padding: const EdgeInsets.all(16),
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

class _ActionBar extends StatelessWidget {
  final Widget child;
  final Color color;
  const _ActionBar({required this.child, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      color: color,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: child,
    );
  }
}

Widget _StatusBanner({required String status}) {
  final colorScheme = Colors.blueGrey;
  final label = _getStatusLabel(status);
  final icon = _getStatusIcon(status);
  return ClipRRect(
    borderRadius: BorderRadius.circular(16),
    child: Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade400,
            Colors.blue.shade700,
          ],
        ),
      ),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(width: 10),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ],
      ),
    ),
  );
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
      return Icons.cleaning_services;
    case 'completed':
      return Icons.check_circle;
    case 'cancelled':
      return Icons.cancel;
    case 'disputed':
      return Icons.warning;
    case 'resolved':
      return Icons.verified;
    case 'closed':
      return Icons.lock;
    default:
      return Icons.info;
  }
}

String _getPaymentStatus(String status) {
  switch (status) {
    case 'pending':
      return 'Awaiting Invoice';
    case 'confirmation':
      return 'Awaiting Payment';
    case 'inprogress':
      return 'In Progress';
    case 'completed':
      return 'Completed';
    case 'closed':
      return 'Paid';
    case 'cancelled':
      return 'Cancelled';
    default:
      return status;
  }
}

class _CloseBookingActionBar extends StatefulWidget {
  final String bookingId;
  final VoidCallback? onClosed;
  const _CloseBookingActionBar({required this.bookingId, this.onClosed});

  @override
  State<_CloseBookingActionBar> createState() => _CloseBookingActionBarState();
}

class _CloseBookingActionBarState extends State<_CloseBookingActionBar> {
  bool _isLoading = false;

  Future<void> _closeBooking() async {
    setState(() => _isLoading = true);
    try {
      await BookingService().markBookingAsClosed(widget.bookingId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking closed successfully!'), backgroundColor: Colors.green),
        );
        if (widget.onClosed != null) widget.onClosed!();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to close booking: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return _ActionBar(
      color: colorScheme.surface,
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _isLoading ? null : _closeBooking,
          icon: _isLoading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.lock),
          label: Text(_isLoading ? 'Closing...' : 'Close Booking'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    );
  }
}