import 'package:flutter/material.dart';
import 'package:nisacleanv1/features/home/widgets/service_card.dart';
import 'package:nisacleanv1/features/home/widgets/promo_banner.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            title: const Text('NisaClean'),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {
                  // TODO: Implement notifications
                },
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Welcome Back!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'What service do you need today?',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const PromoBanner(),
                  const SizedBox(height: 24),
                  const Text(
                    'Our Services',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.2,
                    children: const [
                      ServiceCard(
                        title: 'House Cleaning',
                        icon: Icons.cleaning_services,
                        color: Color(0xFF1E88E5),
                      ),
                      ServiceCard(
                        title: 'Office Cleaning',
                        icon: Icons.business,
                        color: Color(0xFF42A5F5),
                      ),
                      ServiceCard(
                        title: 'Deep Cleaning',
                        icon: Icons.cleaning_services_outlined,
                        color: Color(0xFF64B5F6),
                      ),
                      ServiceCard(
                        title: 'Special Cleaning',
                        icon: Icons.cleaning_services_rounded,
                        color: Color(0xFF90CAF9),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
} 