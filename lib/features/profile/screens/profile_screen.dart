import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nisacleanv1/features/auth/providers/auth_provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nisacleanv1/core/bloc/auth/auth_bloc.dart';
import 'package:nisacleanv1/core/bloc/auth/auth_state.dart';
import 'package:nisacleanv1/core/bloc/auth/auth_event.dart';
import '../../home/presentation/screens/edit_profile_screen.dart';
import 'package:nisacleanv1/services/auth_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Always fetch the latest profile when this screen is built
    context.read<AuthBloc>().add(FetchProfileRequested());
    final blue = const Color(0xFF1E88E5);
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        String name = state.name ?? 'User';
        String email = state.email ?? '';
        String phone = state.phone ?? '';
        final isProvider = state.userType == UserType.serviceProvider;
        if (isProvider) {
          // For service providers, fetch and show provider profile
          return FutureBuilder<Map<String, dynamic>>(
            future: AuthService().fetchCurrentProviderProfile(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: \\${snapshot.error}', style: TextStyle(color: Colors.red)));
              }
              final provider = snapshot.data ?? {};
              final providerName = provider['name'] ?? name;
              final providerEmail = provider['email'] ?? email;
              final providerPhone = provider['phone'] ?? phone;
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
                                child: Icon(Icons.person, size: 48, color: Colors.white),
                                backgroundColor: Color(0xFF1E88E5),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          providerName,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          providerEmail,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70),
                        ),
                        const SizedBox(height: 24),
                        _buildInfoSection(context, 'Provider Information', blue, [
                          _InfoItem(icon: Icons.email, label: providerEmail),
                          _InfoItem(icon: Icons.phone, label: providerPhone),
                        ], name: providerName, phone: providerPhone),
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
                            onTap: () {
                              context.read<AuthBloc>().add(LogoutRequested());
                              Navigator.pushReplacementNamed(context, '/login');
                            },
                          ),
                        ]),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        }
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
                          child: Icon(Icons.person, size: 48, color: Colors.white),
                          backgroundColor: Color(0xFF1E88E5),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70),
                  ),
                  const SizedBox(height: 24),
                  _buildInfoSection(context, 'Personal Information', blue, [
                    _InfoItem(icon: Icons.email, label: email),
                    _InfoItem(icon: Icons.phone, label: phone),
                  ], name: name, phone: phone),
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
                      onTap: () {
                        context.read<AuthBloc>().add(LogoutRequested());
                        Navigator.pushReplacementNamed(context, '/login');
                      },
                    ),
                  ]),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoSection(
    BuildContext context,
    String title,
    Color blue,
    List<Widget> children, {
    String? name,
    String? phone,
  }) {
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
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditProfileScreen(
                        initialName: name ?? '',
                        initialEmail: '',
                        initialPhone: phone ?? '',
                        initialPhotoUrl: null,
                      ),
                    ),
                  );
                  // Optionally handle result if you want to update local state
                },
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
