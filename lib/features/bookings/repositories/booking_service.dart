import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/booking.dart';

class BookingService {
  static const String baseUrl = 'https://api.nisaclean.com';

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Create a new booking
  Future<Map<String, dynamic>> createBooking({
    required String service,
    required String date,
    required String time,
    required BookingLocation location,
    required String notes,
    String? bookingType, // 'client assigned' or 'system assigned'
    String? selectedProvider, // worker ID if client assigned
  }) async {
    try {
      final headers = await _getHeaders();
      
      final requestBody = {
        'service': service,
        'date': date,
        'time': time,
        'location': location.toJson(),
        'notes': notes,
        if (bookingType != null) 'bookingType': bookingType,
        if (selectedProvider != null) 'selectedProvider': selectedProvider,
      };

      print('Creating booking with data: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse('$baseUrl/booking/create'),
        headers: headers,
        body: jsonEncode(requestBody),
      );

      print('Create booking response: ${response.statusCode} - ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        return data['data'];
      } else {
        throw data['message'] ?? 'Failed to create booking';
      }
    } catch (e) {
      print('Create booking error: $e');
      throw e.toString();
    }
  }

  // Get bookings for the current user
  Future<List<Booking>> getBookings({
    String? status,
    String? service,
    String? dateFrom,
    String? dateTo,
    String? search,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final headers = await _getHeaders();
      
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      
      if (status != null) queryParams['status'] = status;
      if (service != null) queryParams['service'] = service;
      if (dateFrom != null) queryParams['dateFrom'] = dateFrom;
      if (dateTo != null) queryParams['dateTo'] = dateTo;
      if (search != null) queryParams['search'] = search;

      final uri = Uri.parse('$baseUrl/booking/get-bookings').replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: headers);

      print('Get bookings response: ${response.statusCode} - ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final bookingsList = data['data']['bookings'] as List;
        return bookingsList.map((json) => Booking.fromJson(json)).toList();
      } else {
        throw data['message'] ?? 'Failed to fetch bookings';
      }
    } catch (e) {
      print('Get bookings error: $e');
      throw e.toString();
    }
  }

  // Get a specific booking by ID
  Future<Booking> getBookingById(String bookingId) async {
    try {
      final headers = await _getHeaders();
      
      final response = await http.get(
        Uri.parse('$baseUrl/booking/get-booking-byId'),
        headers: headers,
      );

      print('Get booking by ID response: ${response.statusCode} - ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return Booking.fromJson(data['data']);
      } else {
        throw data['message'] ?? 'Failed to fetch booking';
      }
    } catch (e) {
      print('Get booking by ID error: $e');
      throw e.toString();
    }
  }

  // Confirm budget (for workers)
  Future<Map<String, dynamic>> confirmBudget({
    required String bookingId,
    required double budget,
  }) async {
    try {
      final headers = await _getHeaders();
      
      final response = await http.post(
        Uri.parse('$baseUrl/booking/confirm-budget'),
        headers: headers,
        body: jsonEncode({
          'bookingId': bookingId,
          'budget': budget,
        }),
      );

      print('Confirm budget response: ${response.statusCode} - ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return data['data'];
      } else {
        throw data['message'] ?? 'Failed to confirm budget';
      }
    } catch (e) {
      print('Confirm budget error: $e');
      throw e.toString();
    }
  }

  // Start booking (for clients)
  Future<Map<String, dynamic>> startBooking(String bookingId) async {
    try {
      final headers = await _getHeaders();
      
      final response = await http.post(
        Uri.parse('$baseUrl/booking/start'),
        headers: headers,
        body: jsonEncode({
          'bookingId': bookingId,
        }),
      );

      print('Start booking response: ${response.statusCode} - ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return data['data'];
      } else {
        throw data['message'] ?? 'Failed to start booking';
      }
    } catch (e) {
      print('Start booking error: $e');
      throw e.toString();
    }
  }

  // Mark booking as complete (for workers)
  Future<Map<String, dynamic>> markBookingAsComplete(String bookingId) async {
    try {
      final headers = await _getHeaders();
      
      final response = await http.post(
        Uri.parse('$baseUrl/booking/complete'),
        headers: headers,
        body: jsonEncode({
          'bookingId': bookingId,
        }),
      );

      print('Mark booking complete response: ${response.statusCode} - ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return data['data'];
      } else {
        throw data['message'] ?? 'Failed to mark booking as complete';
      }
    } catch (e) {
      print('Mark booking complete error: $e');
      throw e.toString();
    }
  }

  // Mark booking as closed (for clients)
  Future<Map<String, dynamic>> markBookingAsClosed(String bookingId) async {
    try {
      final headers = await _getHeaders();
      
      final response = await http.post(
        Uri.parse('$baseUrl/booking/close'),
        headers: headers,
        body: jsonEncode({
          'bookingId': bookingId,
        }),
      );

      print('Mark booking closed response: ${response.statusCode} - ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return data['data'];
      } else {
        throw data['message'] ?? 'Failed to mark booking as closed';
      }
    } catch (e) {
      print('Mark booking closed error: $e');
      throw e.toString();
    }
  }

  // Cancel booking
  Future<Map<String, dynamic>> cancelBooking(String bookingId) async {
    try {
      final headers = await _getHeaders();
      
      final response = await http.post(
        Uri.parse('$baseUrl/booking/cancel'),
        headers: headers,
        body: jsonEncode({
          'bookingId': bookingId,
        }),
      );

      print('Cancel booking response: ${response.statusCode} - ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return data['data'];
      } else {
        throw data['message'] ?? 'Failed to cancel booking';
      }
    } catch (e) {
      print('Cancel booking error: $e');
      throw e.toString();
    }
  }

  // Create booking dispute
  Future<Map<String, dynamic>> createBookingDispute({
    required String bookingId,
    required String reason,
    required String description,
  }) async {
    try {
      final headers = await _getHeaders();
      
      final response = await http.post(
        Uri.parse('$baseUrl/booking/create-dispute'),
        headers: headers,
        body: jsonEncode({
          'bookingId': bookingId,
          'reason': reason,
          'description': description,
        }),
      );

      print('Create dispute response: ${response.statusCode} - ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return data['data'];
      } else {
        throw data['message'] ?? 'Failed to create dispute';
      }
    } catch (e) {
      print('Create dispute error: $e');
      throw e.toString();
    }
  }
} 