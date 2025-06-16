import 'package:flutter/material.dart';

class BalanceCard extends StatelessWidget {
  final double balance;
  final String phoneNumber;
  final String paymentMethod;

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
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Available Balance',
              style: TextStyle(fontSize: 14, color: Colors.white70),
            ),
            const SizedBox(height: 6),
            Text(
              'KES ${balance.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),

            /// Phone Number Row
            Row(
              children: [
                const Icon(Icons.phone, size: 20, color: Colors.white70),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Phone: $phoneNumber',
                    style: const TextStyle(fontSize: 14, color: Colors.white),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // TODO: Navigate to edit phone number screen
                  },
                  child: const Text(
                    "Change",
                    style: TextStyle(color: Colors.tealAccent),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            /// Payment Method Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 20,
                  color: Colors.white70,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Payment Method:',
                  style: TextStyle(fontSize: 14, color: Colors.white),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButton<String>(
                    isExpanded: true, // Important to allow wrapping
                    dropdownColor: const Color(0xFF2A2A2A),
                    value: paymentMethod,
                    iconEnabledColor: Colors.white70,
                    underline: Container(height: 0),
                    style: const TextStyle(color: Colors.white),
                    items: const [
                      DropdownMenuItem(value: 'Mpesa', child: Text('Mpesa')),
                      DropdownMenuItem(
                        value: 'PayPal',
                        enabled: false,
                        child: Text(
                          'PayPal (Coming Soon)',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'GooglePay',
                        enabled: false,
                        child: Text(
                          'Google Pay (Coming Soon)',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      // No action for now
                    },
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
