import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final List<Map<String, dynamic>> notifications = [
      {
        'title': 'Booking Confirmed',
        'body': 'Your booking for house cleaning is confirmed.',
        'timestamp': '2 hours ago',
        'icon': Icons.check_circle_outline,
        'color': Colors.green,
        'read': false,
      },
      {
        'title': 'Payment Received',
        'body': 'You have received a payment of KES 2,000.',
        'timestamp': 'Yesterday',
        'icon': Icons.payment,
        'color': Colors.blue,
        'read': true,
      },
      {
        'title': 'Booking Cancelled',
        'body': 'A client cancelled a booking.',
        'timestamp': '3 days ago',
        'icon': Icons.cancel,
        'color': Colors.red,
        'read': true,
      },
      {
        'title': 'New Review',
        'body': 'You received a new 5-star review!',
        'timestamp': '1 week ago',
        'icon': Icons.star,
        'color': Colors.amber,
        'read': false,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        elevation: 0,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 24),
        itemCount: notifications.length,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final notification = notifications[index];
          final bool unread = !notification['read'];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: isDark
                    ? LinearGradient(
                        colors: [
                          colorScheme.surfaceVariant.withOpacity(0.7),
                          colorScheme.surface.withOpacity(0.9),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : LinearGradient(
                        colors: [
                          colorScheme.background.withOpacity(0.95),
                          colorScheme.surfaceVariant.withOpacity(0.7),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                boxShadow: [
                  if (unread)
                    BoxShadow(
                      color: notification['color'].withOpacity(0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                ],
                border: Border.all(
                  color: unread
                      ? notification['color'].withOpacity(0.4)
                      : colorScheme.outline.withOpacity(0.08),
                  width: unread ? 1.5 : 1,
                ),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                leading: CircleAvatar(
                  radius: 26,
                  backgroundColor: notification['color'].withOpacity(0.18),
                  child: Icon(
                    notification['icon'],
                    color: notification['color'],
                    size: 28,
                  ),
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        notification['title'],
                        style: TextStyle(
                          fontWeight: unread ? FontWeight.bold : FontWeight.w500,
                          fontSize: 17,
                          color: unread
                              ? colorScheme.primary
                              : colorScheme.onSurface.withOpacity(0.85),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (unread)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.primary.withOpacity(0.5),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification['body'],
                        style: TextStyle(
                          color: colorScheme.onSurface.withOpacity(0.85),
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 14, color: colorScheme.outline),
                          const SizedBox(width: 4),
                          Text(
                            notification['timestamp'],
                            style: TextStyle(
                              fontSize: 13,
                              color: colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                onTap: () {
                  // In a real app, mark as read or navigate to details
                },
              ),
            ),
          );
        },
      ),
      backgroundColor: colorScheme.background,
    );
  }
}
