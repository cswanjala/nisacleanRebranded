import 'package:dio/dio.dart';
import 'package:nisacleanv1/core/models/api_response.dart';
import 'package:nisacleanv1/core/utils/error_handler.dart';

class PaymentService {
  final Dio _dio;

  PaymentService(this._dio);

  Future<ApiResponse<Map<String, dynamic>>> initiateMpesaPayment({
    required String phoneNumber,
    required double amount,
    required String reference,
    required String description,
  }) async {
    try {
      final response = await _dio.post(
        '/api/payments/mpesa/initiate',
        data: {
          'phone_number': phoneNumber,
          'amount': amount,
          'reference': reference,
          'description': description,
        },
      );

      return ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) => json as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw AppError.fromDioError(e);
    } catch (e) {
      throw AppError.unknown(e.toString());
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> checkPaymentStatus(String reference) async {
    try {
      final response = await _dio.get(
        '/api/payments/mpesa/status/$reference',
      );

      return ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) => json as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw AppError.fromDioError(e);
    } catch (e) {
      throw AppError.unknown(e.toString());
    }
  }
} 