import 'package:dio/dio.dart';

class ApiClient {
  static const String baseUrl = 'YOUR_API_BASE_URL'; // TODO: Replace with actual API URL
  
  late final Dio _dio;

  ApiClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.addAll([
      LogInterceptor(
        requestBody: true,
        responseBody: true,
      ),
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // TODO: Add auth token if needed
          return handler.next(options);
        },
        onError: (error, handler) {
          // TODO: Handle common errors
          return handler.next(error);
        },
      ),
    ]);
  }

  Dio get dio => _dio;
} 