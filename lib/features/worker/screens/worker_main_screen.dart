import 'package:flutter/material.dart';
import 'package:nisacleanv1/features/worker/screens/worker_home_screen.dart';
import 'package:nisacleanv1/features/worker/screens/worker_jobs_screen.dart';
import 'package:nisacleanv1/features/worker/screens/worker_earnings_screen.dart';
import 'package:nisacleanv1/features/profile/screens/profile_screen.dart';
import 'package:nisacleanv1/services/auth_service.dart';

class WorkerMainScreen extends StatefulWidget {
  const WorkerMainScreen({super.key});

  @override
  State<WorkerMainScreen> createState() => _WorkerMainScreenState();
}

class _WorkerMainScreenState extends State<WorkerMainScreen> {
  int _currentIndex = 0;
  final AuthService _authService = AuthService();
  
  final List<Widget> _screens = [
    const WorkerHomeScreen(),
    const WorkerJobsScreen(),
    const WorkerEarningsScreen(),
    const ProfileScreen(),
  ];

  Future<void> _handleLogout() async {
    try {
      await _authService.logout();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error logging out: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          if (index == 3) { // Profile tab
            _handleLogout();
          } else {
            setState(() {
              _currentIndex = index;
            });
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.work_outline),
            selectedIcon: Icon(Icons.work),
            label: 'Jobs',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'Earnings',
          ),
          NavigationDestination(
            icon: Icon(Icons.logout),
            selectedIcon: Icon(Icons.logout),
            label: 'Logout',
          ),
        ],
      ),
    );
  }
} 