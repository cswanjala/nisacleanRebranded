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
    return amount >= 0
        ? Colors.greenAccent.shade400
        : Colors.redAccent.shade200;
  }

  String _formatAmount() {
    final prefix = amount >= 0 ? '+' : '-';
    return '$prefix KES ${amount.abs().toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _getAmountColor().withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                amount >= 0
                    ? Icons.arrow_downward_rounded
                    : Icons.arrow_upward_rounded,
                color: _getAmountColor(),
                size: 26,
              ),
            ),
            const SizedBox(width: 16),

            /// Transaction Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date,
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                ],
              ),
            ),

            /// Amount
            Text(
              _formatAmount(),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _getAmountColor(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
