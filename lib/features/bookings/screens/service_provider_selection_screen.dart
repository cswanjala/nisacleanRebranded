import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
  bool _autoAssign = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Select Service Provider',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
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
          onPressed: () {
            // TODO: Handle booking confirmation
            Navigator.pop(context);
          },
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
                    onTap: () => setState(() => _autoAssign = true),
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
    // TODO: Replace with actual data from API
    final providers = [
      {
        'id': '1',
        'name': 'John Doe',
        'rating': 4.8,
        'jobs': 156,
        'image': 'assets/avatar_placeholder.png',
      },
      {
        'id': '2',
        'name': 'Jane Smith',
        'rating': 4.9,
        'jobs': 203,
        'image': 'assets/avatar_placeholder.png',
      },
    ];

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
          itemCount: providers.length,
          itemBuilder: (context, index) {
            final provider = providers[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage: AssetImage(provider['image'] as String),
                ),
                title: Text(
                  provider['name'] as String,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                ),
                subtitle: Row(
                  children: [
                    Icon(Icons.star, size: 16, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      provider['rating'].toString(),
                      style: GoogleFonts.poppins(),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${provider['jobs']} jobs',
                      style: GoogleFonts.poppins(color: Colors.grey[600]),
                    ),
                  ],
                ),
                trailing: Radio<String>(
                  value: provider['id'] as String,
                  groupValue: null, // TODO: Add selected provider state
                  onChanged: (value) {
                    // TODO: Handle provider selection
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