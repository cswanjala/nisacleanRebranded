import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nisacleanv1/features/bookings/services/booking_service.dart';
import 'package:nisacleanv1/features/bookings/models/booking.dart';

class ServiceProviderSelectionScreen extends StatefulWidget {
  final Map<String, dynamic> bookingDetails;

  const ServiceProviderSelectionScreen({
    super.key,
    required this.bookingDetails,
  });

  @override
  State<ServiceProviderSelectionScreen> createState() => _ServiceProviderSelectionScreenState();
}

class _ServiceProviderSelectionScreenState extends State<ServiceProviderSelectionScreen> {
  bool _autoAssign = true;
  String? _selectedProviderId;
  bool _isLoading = false;
  List<Map<String, dynamic>> _providers = [];
  final BookingService _bookingService = BookingService();

  @override
  void initState() {
    super.initState();
    _fetchProviders();
  }

  Future<void> _fetchProviders() async {
    setState(() { _isLoading = true; });
    try {
      final providers = await _bookingService.getAllAvailableProviders();
      setState(() {
        _providers = providers;
      });
    } catch (e) {
      setState(() {
        _providers = [];
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching providers: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  Future<void> _confirmBooking() async {
    setState(() => _isLoading = true);
    try {
      final details = widget.bookingDetails;
      final bookingType = _autoAssign ? 'system assigned' : 'client assigned';
      final selectedProvider = !_autoAssign ? _selectedProviderId : null;
      if (bookingType == 'client assigned' && selectedProvider == null) {
        throw 'Please select a service provider.';
      }
      // Compose location
      final location = BookingLocation(
        address: details['address'] as String,
        coordinates: details['coordinates'] ?? [0.0, 0.0],
      );
      await _bookingService.createBooking(
        service: details['service'] as String,
        date: (details['date'] as DateTime).toIso8601String().split('T')[0],
        time: (details['time'] as TimeOfDay).format(context),
        location: location,
        notes: details['notes'] ?? '',
        bookingType: bookingType,
        selectedProvider: selectedProvider,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking created successfully!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating booking: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Select Service Provider',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSelectionOption(),
                  const SizedBox(height: 24),
                  if (!_autoAssign) _buildServiceProviderList(),
                ],
              ),
            ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _confirmBooking,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            'Confirm Booking',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionOption() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How would you like to select a service provider?',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildOptionCard(
                    title: 'Auto Assign',
                    subtitle: 'Let the system choose the best provider',
                    icon: Icons.auto_awesome,
                    isSelected: _autoAssign,
                    onTap: () => setState(() {
                      _autoAssign = true;
                      _selectedProviderId = null;
                    }),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildOptionCard(
                    title: 'Choose Provider',
                    subtitle: 'Select a provider yourself',
                    icon: Icons.person_search,
                    isSelected: !_autoAssign,
                    onTap: () => setState(() => _autoAssign = false),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).colorScheme.primary.withOpacity(0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey[300]!,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey[600],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: isSelected ? Theme.of(context).colorScheme.primary : Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceProviderList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Available Service Providers',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _providers.length,
          itemBuilder: (context, index) {
            final provider = _providers[index];
            final profilePic = provider['profilePic'] as String?;
            final name = provider['name'] as String? ?? 'Unknown';
            final id = provider['_id'] as String? ?? '';
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: profilePic != null && profilePic.isNotEmpty
                    ? CircleAvatar(backgroundImage: NetworkImage(profilePic))
                    : const CircleAvatar(child: Icon(Icons.person)),
                title: Text(
                  name,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                ),
                trailing: Radio<String>(
                  value: id,
                  groupValue: _selectedProviderId,
                  onChanged: (value) {
                    setState(() {
                      _selectedProviderId = value;
                    });
                  },
                ),
              ),
            );
          },
        ),
      ],
    );
  }
} 