import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final List<Map<String, String>> _faqs = [
    {
      'question': 'How do I book a service?',
      'answer': 'Go to the Home tab, tap "Book Service," select your service, schedule a date and time, and confirm your booking.',
    },
    {
      'question': 'How do I pay for a service?',
      'answer': 'We accept M-Pesa payments in KSH. You will receive a prompt to pay after booking.',
    },
    {
      'question': 'How do I cancel a booking?',
      'answer': 'Go to the Bookings tab, select your booking, and tap "Cancel Booking."',
    },
    {
      'question': 'How do I contact support?',
      'answer': 'You can reach us via email at support@nisaclean.com or call us at +254 700 000 000.',
    },
  ];

  final TextEditingController _feedbackController = TextEditingController();

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  void _submitFeedback() {
    if (_feedbackController.text.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Feedback submitted!'), backgroundColor: Colors.green),
      );
      _feedbackController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          children: [
            _buildModernAppBar(context),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildSectionTitle('Frequently Asked Questions'),
                  ..._faqs.map((faq) => _buildFaqTile(faq['question']!, faq['answer']!)).toList(),
                  const Divider(),
                  _buildSectionTitle('Contact Us'),
                  _buildContactTile(
                    icon: Icons.email_outlined,
                    title: 'Email',
                    subtitle: 'support@nisaclean.com',
                    onTap: () {
                      // TODO: Open email client
                    },
                  ),
                  _buildContactTile(
                    icon: Icons.phone_outlined,
                    title: 'Phone',
                    subtitle: '+254 700 000 000',
                    onTap: () {
                      // TODO: Open phone dialer
                    },
                  ),
                  const Divider(),
                  _buildSectionTitle('Feedback'),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: TextField(
                      controller: _feedbackController,
                      decoration: const InputDecoration(
                        labelText: 'Your Feedback',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _submitFeedback,
                    style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                    child: const Text('Submit Feedback'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernAppBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 18),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                height: 90,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.white.withOpacity(0.12), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withOpacity(0.10),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(Icons.help_outline, color: Colors.white, size: 28),
                const SizedBox(width: 18),
                Expanded(
                  child: Text(
                    'Help & Support',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildFaqTile(String question, String answer) {
    return ExpansionTile(
      title: Text(question),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(answer),
        ),
      ],
    );
  }

  Widget _buildContactTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: onTap,
    );
  }
} 