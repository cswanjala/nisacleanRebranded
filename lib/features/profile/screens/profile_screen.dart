import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nisacleanv1/features/auth/providers/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final blue = const Color(0xFF1E88E5);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const SizedBox(height: 40),
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [blue.withOpacity(0.5), Colors.transparent],
                          radius: 0.6,
                          center: Alignment.center,
                        ),
                      ),
                    ),
                    const CircleAvatar(
                      radius: 45,
                      backgroundImage: AssetImage(
                        'assets/avatar_placeholder.png',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Victoria Heard',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Active since - Jul, 2019',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: 24),
              _buildInfoSection(context, 'Personal Information', blue, [
                _InfoItem(icon: Icons.email, label: 'heard_j@gmail.com'),
                _InfoItem(icon: Icons.phone, label: '9898712132'),
                _InfoItem(icon: Icons.location_on, label: 'Antigua'),
              ]),
              const SizedBox(height: 24),
              _buildInfoSection(context, 'Utilities', blue, [
                _NavItem(icon: Icons.settings, label: 'Settings', onTap: () {}),
                _NavItem(icon: Icons.language, label: 'Language', onTap: () {}),
                _NavItem(
                  icon: Icons.help_outline,
                  label: 'Ask Help-Desk',
                  onTap: () {},
                ),
                _NavItem(
                  icon: Icons.logout,
                  label: 'Log-Out',
                  onTap: authProvider.logout,
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection(
    BuildContext context,
    String title,
    Color blue,
    List<Widget> children,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: blue,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (title == 'Personal Information')
              TextButton(
                onPressed: () {},
                child: Text(
                  'Edit',
                  style: TextStyle(color: blue.withOpacity(0.9)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),

            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(label, style: const TextStyle(color: Colors.white)),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(label, style: const TextStyle(color: Colors.white)),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.white70,
      ),
      onTap: onTap,
    );
  }
}
