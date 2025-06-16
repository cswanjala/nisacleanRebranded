import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nisacleanv1/features/auth/providers/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            title: const Text('Profile'),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {
                  // TODO: Navigate to settings
                },
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 50,
                    backgroundColor: Color(0xFF1E88E5),
                    child: Icon(
                      Icons.person,
                      size: 50,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    authProvider.userPhone ?? 'Not logged in',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildProfileSection(
                    title: 'Account',
                    items: [
                      _ProfileItem(
                        icon: Icons.phone,
                        title: 'Phone Number',
                        subtitle: authProvider.userPhone ?? 'Not set',
                        onTap: () {
                          // TODO: Navigate to phone number update
                        },
                      ),
                      _ProfileItem(
                        icon: Icons.email,
                        title: 'Email',
                        subtitle: 'Not set',
                        onTap: () {
                          // TODO: Navigate to email update
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildProfileSection(
                    title: 'Preferences',
                    items: [
                      _ProfileItem(
                        icon: Icons.notifications,
                        title: 'Notifications',
                        subtitle: 'Manage notification settings',
                        onTap: () {
                          // TODO: Navigate to notification settings
                        },
                      ),
                      _ProfileItem(
                        icon: Icons.language,
                        title: 'Language',
                        subtitle: 'English',
                        onTap: () {
                          // TODO: Navigate to language settings
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildProfileSection(
                    title: 'Support',
                    items: [
                      _ProfileItem(
                        icon: Icons.help,
                        title: 'Help Center',
                        subtitle: 'Get help with your account',
                        onTap: () {
                          // TODO: Navigate to help center
                        },
                      ),
                      _ProfileItem(
                        icon: Icons.info,
                        title: 'About',
                        subtitle: 'App version 1.0.0',
                        onTap: () {
                          // TODO: Show about dialog
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        authProvider.logout();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Logout'),
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

  Widget _buildProfileSection({
    required String title,
    required List<_ProfileItem> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Card(
          child: Column(
            children: items,
          ),
        ),
      ],
    );
  }
}

class _ProfileItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ProfileItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
} 