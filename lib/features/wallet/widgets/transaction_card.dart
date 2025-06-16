import 'package:flutter/material.dart';

class TransactionCard extends StatelessWidget {
  final String title;
  final double amount;
  final String date;
  final String status;

  const TransactionCard({
    super.key,
    required this.title,
    required this.amount,
    required this.date,
    required this.status,
  });

  Color _getAmountColor() {
    return amount >= 0 ? Colors.green : Colors.red;
  }

  String _formatAmount() {
    final prefix = amount >= 0 ? '+' : '';
    return '$prefix KES ${amount.abs().toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _getAmountColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                amount >= 0 ? Icons.add : Icons.remove,
                color: _getAmountColor(),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date,
                    style: const TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              _formatAmount(),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _getAmountColor(),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 