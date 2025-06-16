import 'package:flutter/material.dart';

class BalanceCard extends StatelessWidget {
  final double balance;
  final String phoneNumber;
  final String paymentMethod; // Unused, but kept in constructor

  const BalanceCard({
    super.key,
    required this.balance,
    required this.phoneNumber,
    required this.paymentMethod,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF1E1E1E),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Title
            const Text(
              'Available Balance',
              style: TextStyle(fontSize: 13, color: Colors.white70),
            ),
            const SizedBox(height: 4),

            /// Balance
            Text(
              'KES ${balance.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),

            /// Phone number
            Row(
              children: [
                const Icon(Icons.phone, size: 18, color: Colors.white70),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    phoneNumber,
                    style: const TextStyle(fontSize: 13, color: Colors.white),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () {
                    // TODO: Navigate to edit phone number screen
                  },
                  child: const Text(
                    "Edit",
                    style: TextStyle(
                      fontSize: 12,
                      color: Color.fromARGB(255, 83, 185, 241),
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
}
