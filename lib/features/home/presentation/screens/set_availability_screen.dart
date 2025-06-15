import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SetAvailabilityScreen extends StatefulWidget {
  const SetAvailabilityScreen({super.key});

  @override
  State<SetAvailabilityScreen> createState() => _SetAvailabilityScreenState();
}

class _SetAvailabilityScreenState extends State<SetAvailabilityScreen> {
  final List<Map<String, dynamic>> _days = [
    {'name': 'Monday', 'enabled': true, 'start': TimeOfDay(hour: 8, minute: 0), 'end': TimeOfDay(hour: 17, minute: 0)},
    {'name': 'Tuesday', 'enabled': true, 'start': TimeOfDay(hour: 8, minute: 0), 'end': TimeOfDay(hour: 17, minute: 0)},
    {'name': 'Wednesday', 'enabled': true, 'start': TimeOfDay(hour: 8, minute: 0), 'end': TimeOfDay(hour: 17, minute: 0)},
    {'name': 'Thursday', 'enabled': true, 'start': TimeOfDay(hour: 8, minute: 0), 'end': TimeOfDay(hour: 17, minute: 0)},
    {'name': 'Friday', 'enabled': true, 'start': TimeOfDay(hour: 8, minute: 0), 'end': TimeOfDay(hour: 17, minute: 0)},
    {'name': 'Saturday', 'enabled': false, 'start': TimeOfDay(hour: 9, minute: 0), 'end': TimeOfDay(hour: 14, minute: 0)},
    {'name': 'Sunday', 'enabled': false, 'start': TimeOfDay(hour: 9, minute: 0), 'end': TimeOfDay(hour: 14, minute: 0)},
  ];

  Future<void> _pickTime(int index, bool isStart) async {
    final initial = isStart ? _days[index]['start'] : _days[index]['end'];
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _days[index]['start'] = picked;
        } else {
          _days[index]['end'] = picked;
        }
      });
    }
  }

  void _saveAvailability() {
    // In a real app, save to backend or state management
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Availability saved!'), backgroundColor: Colors.green),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Set Availability',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _days.length,
        itemBuilder: (context, index) {
          final day = _days[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          day['name'],
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Switch(
                        value: day['enabled'],
                        onChanged: (val) {
                          setState(() {
                            day['enabled'] = val;
                          });
                        },
                      ),
                    ],
                  ),
                  if (day['enabled'])
                    Row(
                      children: [
                        TextButton.icon(
                          icon: const Icon(Icons.access_time),
                          label: Text('Start: ${day['start'].format(context)}'),
                          onPressed: () => _pickTime(index, true),
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          icon: const Icon(Icons.access_time),
                          label: Text('End: ${day['end'].format(context)}'),
                          onPressed: () => _pickTime(index, false),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: _saveAvailability,
          style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
          child: const Text('Save Availability'),
        ),
      ),
    );
  }
} 