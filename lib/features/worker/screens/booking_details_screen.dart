import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/workflow_progress.dart';

class BookingDetailsScreen extends StatefulWidget {
  const BookingDetailsScreen({super.key});

  @override
  State<BookingDetailsScreen> createState() => _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends State<BookingDetailsScreen> {
  // Mock data - replace with actual data from your backend
  final List<WorkflowStep> _workflowSteps = [
    WorkflowStep(
      id: '1',
      title: 'Received',
      description: 'Order received and confirmed',
      icon: Icons.check_circle,
    ),
    WorkflowStep(
      id: '2',
      title: 'Washing',
      description: 'Items are being washed',
      icon: Icons.cleaning_services,
    ),
    WorkflowStep(
      id: '3',
      title: 'Drying',
      description: 'Items are being dried',
      icon: Icons.dry_cleaning,
    ),
    WorkflowStep(
      id: '4',
      title: 'Ironing',
      description: 'Items are being ironed',
      icon: Icons.iron,
    ),
    WorkflowStep(
      id: '5',
      title: 'Ready for Pickup',
      description: 'Order is ready for pickup',
      icon: Icons.check_circle,
    ),
  ];

  int _currentStepIndex = 1; // Mock current step - replace with actual data

  void _moveToNextStep() {
    if (_currentStepIndex < _workflowSteps.length - 1) {
      setState(() {
        _currentStepIndex++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Booking Details',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Service Details Card
            Card(
              elevation: 0,
              color: const Color(0xFF2A2A2A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.cleaning_services,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Laundry Service',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Booking #12345',
                                style: GoogleFonts.poppins(
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'In Progress',
                            style: GoogleFonts.poppins(
                              color: Colors.orange,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Colors.white24),
                    const SizedBox(height: 16),
                    _buildInfoRow(
                      Icons.calendar_today,
                      'Date',
                      'March 15, 2024',
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      Icons.access_time,
                      'Time',
                      '2:00 PM',
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      Icons.location_on,
                      'Location',
                      '123 Main St, City',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Workflow Progress
            WorkflowProgress(
              steps: _workflowSteps,
              currentStepIndex: _currentStepIndex,
            ),
            const SizedBox(height: 16),
            // Client Details Card
            Card(
              elevation: 0,
              color: const Color(0xFF2A2A2A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Client Details',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow(
                      Icons.person,
                      'Name',
                      'John Doe',
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      Icons.phone,
                      'Phone',
                      '+1 234 567 890',
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      Icons.email,
                      'Email',
                      'john@example.com',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _moveToNextStep,
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Next Step'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // TODO: Implement contact client
                    },
                    icon: const Icon(Icons.message),
                    label: const Text('Contact Client'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Colors.white24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
            Text(
              value,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
} 