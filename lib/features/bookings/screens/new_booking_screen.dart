import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:nisacleanv1/features/bookings/widgets/location_picker.dart';
import 'package:nisacleanv1/features/bookings/repositories/booking_repository.dart';
import 'package:nisacleanv1/features/bookings/screens/service_provider_selection_screen.dart';

class NewBookingScreen extends StatefulWidget {
  const NewBookingScreen({super.key});

  @override
  State<NewBookingScreen> createState() => _NewBookingScreenState();
}

class _NewBookingScreenState extends State<NewBookingScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedService;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _selectedLocation;
  LatLng? _selectedCoordinates;
  String? _notes;
  bool _isLoading = false;

  final List<String> _services = [
    'House Cleaning',
    'Office Cleaning',
    'Deep Cleaning',
    'Special Cleaning',
  ];

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (time != null) {
      setState(() => _selectedTime = time);
    }
  }

  Future<void> _createBooking() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // TODO: Get booking repository from provider
      // final repository = context.read<BookingRepository>();
      // await repository.createBooking(
      //   serviceName: _selectedService!,
      //   scheduledDate: _selectedDate!,
      //   scheduledTime: _selectedTime!.format(context),
      //   amount: 0, // TODO: Get from service price
      //   location: _selectedLocation,
      //   notes: _notes,
      // );

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      // TODO: Show error
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      final bookingDetails = {
        'service': _selectedService,
        'date': _selectedDate,
        'time': _selectedTime,
        'address': _selectedLocation,
        'notes': _notes,
      };

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ServiceProviderSelectionScreen(
            bookingDetails: bookingDetails,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Booking'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<String>(
              value: _selectedService,
              decoration: const InputDecoration(
                labelText: 'Service',
                hintText: 'Select a service',
              ),
              items: _services.map((service) {
                return DropdownMenuItem(
                  value: service,
                  child: Text(service),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedService = value);
              },
              validator: (value) {
                if (value == null) {
                  return 'Please select a service';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Date',
                      hintText: 'Select date',
                    ),
                    controller: TextEditingController(
                      text: _selectedDate?.toString().split(' ')[0],
                    ),
                    onTap: _selectDate,
                    validator: (value) {
                      if (_selectedDate == null) {
                        return 'Please select a date';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Time',
                      hintText: 'Select time',
                    ),
                    controller: TextEditingController(
                      text: _selectedTime?.format(context),
                    ),
                    onTap: _selectTime,
                    validator: (value) {
                      if (_selectedTime == null) {
                        return 'Please select a time';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Location',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            LocationPicker(
              onLocationSelected: (address, location) {
                setState(() {
                  _selectedLocation = address;
                  _selectedCoordinates = location;
                });
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Notes',
                hintText: 'Any special instructions?',
              ),
              maxLines: 3,
              onChanged: (value) => _notes = value,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _handleSubmit,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Create Booking'),
            ),
          ],
        ),
      ),
    );
  }
} 