import 'package:dio/dio.dart';
import 'package:nisacleanv1/core/network/api_client.dart';

class MpesaService {
  final ApiClient _apiClient;

  MpesaService(this._apiClient);

  Future<Map<String, dynamic>> initiateSTKPush({
    required String phoneNumber,
    required double amount,
    required String accountReference,
    required String transactionDesc,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/mpesa/stk-push',
        data: {
          'phone_number': phoneNumber,
          'amount': amount,
          'account_reference': accountReference,
          'transaction_desc': transactionDesc,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> checkTransactionStatus(String checkoutRequestId) async {
    try {
      final response = await _apiClient.dio.get(
        '/mpesa/transaction-status',
        queryParameters: {'checkout_request_id': checkoutRequestId},
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(DioException error) {
    // TODO: Implement proper error handling
    return Exception(error.message);
  }
} 