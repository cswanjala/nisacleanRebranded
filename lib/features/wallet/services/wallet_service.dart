import 'package:http/http.dart' as http;
import 'dart:convert';

class WalletService {
  final String baseUrl = 'http://192.168.1.127:8002';

  Future<double> getBalance(String token) async {
    print('Fetching balance from: $baseUrl/wallet/get-balance with token: $token');
    final response = await http.get(
      Uri.parse('$baseUrl/wallet/get-balance'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return (data['data']['balance'] as num).toDouble();
    } else {
      throw data['message'] ?? 'Failed to fetch wallet balance';
    }
  }

  Future<List<Map<String, dynamic>>> getTransactions(String token) async {
    print('Fetching transactions from: $baseUrl/transaction/get-transactions with token: $token');
    final response = await http.get(
      Uri.parse('$baseUrl/transaction/get-transactions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      final List<dynamic> txs = data['data'] ?? [];
      return txs.cast<Map<String, dynamic>>();
    } else {
      throw data['message'] ?? 'Failed to fetch transactions';
    }
  }
} 