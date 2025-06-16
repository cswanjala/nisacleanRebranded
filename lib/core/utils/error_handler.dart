import 'package:dio/dio.dart';

class AppError implements Exception {
  final String message;
  final String? code;
  final int? statusCode;

  AppError({
    required this.message,
    this.code,
    this.statusCode,
  });

  factory AppError.fromDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return AppError(
          message: 'Connection timeout. Please check your internet connection.',
          code: 'CONNECTION_TIMEOUT',
        );
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final data = error.response?.data;
        String message = 'An error occurred';
        
        if (data is Map<String, dynamic> && data['message'] != null) {
          message = data['message'];
        } else if (error.message != null) {
          message = error.message!;
        }

        return AppError(
          message: message,
          code: data is Map<String, dynamic> ? data['code'] : null,
          statusCode: statusCode,
        );
      case DioExceptionType.cancel:
        return AppError(
          message: 'Request was cancelled',
          code: 'REQUEST_CANCELLED',
        );
      case DioExceptionType.connectionError:
        return AppError(
          message: 'No internet connection',
          code: 'NO_INTERNET',
        );
      default:
        return AppError(
          message: 'An unexpected error occurred',
          code: 'UNKNOWN_ERROR',
        );
    }
  }

  factory AppError.unknown(String message) {
    return AppError(
      message: message,
      code: 'UNKNOWN_ERROR',
    );
  }

  @override
  String toString() => message;
} 