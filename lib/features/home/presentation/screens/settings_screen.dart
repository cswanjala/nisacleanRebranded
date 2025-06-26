import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  String _selectedCurrency = 'KSH';
  String _selectedPaymentMethod = 'M-Pesa';

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
                  _buildSectionTitle('Payment Settings'),
                  _buildSettingTile(
                    title: 'Payment Method',
                    subtitle: _selectedPaymentMethod,
                    icon: Icons.payment,
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Select Payment Method'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                title: const Text('M-Pesa'),
                                onTap: () {
                                  setState(() {
                                    _selectedPaymentMethod = 'M-Pesa';
                                  });
                                  Navigator.pop(context);
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  _buildSettingTile(
                    title: 'Currency',
                    subtitle: _selectedCurrency,
                    icon: Icons.currency_exchange,
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Select Currency'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                title: const Text('KSH'),
                                onTap: () {
                                  setState(() {
                                    _selectedCurrency = 'KSH';
                                  });
                                  Navigator.pop(context);
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const Divider(),
                  _buildSectionTitle('App Settings'),
                  _buildSettingTile(
                    title: 'Notifications',
                    subtitle: _notificationsEnabled ? 'Enabled' : 'Disabled',
                    icon: Icons.notifications,
                    trailing: Switch(
                      value: _notificationsEnabled,
                      onChanged: (val) {
                        setState(() {
                          _notificationsEnabled = val;
                        });
                      },
                    ),
                  ),
                  _buildSettingTile(
                    title: 'Dark Mode',
                    subtitle: _darkModeEnabled ? 'Enabled' : 'Disabled',
                    icon: Icons.dark_mode,
                    trailing: Switch(
                      value: _darkModeEnabled,
                      onChanged: (val) {
                        setState(() {
                          _darkModeEnabled = val;
                        });
                      },
                    ),
                  ),
                  const Divider(),
                  _buildSectionTitle('About'),
                  _buildSettingTile(
                    title: 'Version',
                    subtitle: '1.0.0',
                    icon: Icons.info_outline,
                  ),
                  _buildSettingTile(
                    title: 'Terms of Service',
                    icon: Icons.description_outlined,
                    onTap: () {
                      // TODO: Navigate to terms of service
                    },
                  ),
                  _buildSettingTile(
                    title: 'Privacy Policy',
                    icon: Icons.privacy_tip_outlined,
                    onTap: () {
                      // TODO: Navigate to privacy policy
                    },
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [colorScheme.primary, colorScheme.primary.withOpacity(0.85)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withOpacity(0.18),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.settings, color: Colors.white, size: 32),
              const SizedBox(width: 18),
              Expanded(
                child: Text(
                  'Settings',
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

  Widget _buildSettingTile({
    required String title,
    String? subtitle,
    required IconData icon,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: trailing,
      onTap: onTap,
    );
  }
} 