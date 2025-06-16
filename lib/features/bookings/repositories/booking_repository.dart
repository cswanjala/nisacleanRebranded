import 'package:dio/dio.dart';
import 'package:nisacleanv1/core/network/api_client.dart';
import 'package:nisacleanv1/features/bookings/models/booking.dart';

class BookingRepository {
  final ApiClient _apiClient;

  BookingRepository(this._apiClient);

  Future<List<Booking>> getBookings() async {
    try {
      final response = await _apiClient.dio.get('/bookings');
      return (response.data as List)
          .map((json) => Booking.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Booking> createBooking({
    required String serviceName,
    required DateTime scheduledDate,
    required String scheduledTime,
    required double amount,
    String? location,
    String? notes,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/bookings',
        data: {
          'service_name': serviceName,
          'scheduled_date': scheduledDate.toIso8601String(),
          'scheduled_time': scheduledTime,
          'amount': amount,
          'location': location,
          'notes': notes,
        },
      );
      return Booking.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Booking> updateBookingStatus(String bookingId, BookingStatus status) async {
    try {
      final response = await _apiClient.dio.patch(
        '/bookings/$bookingId',
        data: {
          'status': status.toString().split('.').last,
        },
      );
      return Booking.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(DioException error) {
    // TODO: Implement proper error handling
    return Exception(error.message);
  }
} 