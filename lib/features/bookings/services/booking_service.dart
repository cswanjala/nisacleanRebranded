import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/booking.dart';
import 'package:nisacleanv1/core/constants/api_constants.dart';

class BookingService {
  static const String baseUrl = ApiConstants.baseUrl;

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    print('Retrieved token: ${token != null ? '${token.substring(0, 20)}...' : 'null'}');
    return token;
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    print('Request headers: $headers');
    return headers;
  }

  // Create a new booking
  Future<Map<String, dynamic>> createBooking({
    required String service,
    required String date,
    required String time,
    required BookingLocation location,
    required String notes,
    String? bookingType,
    String? selectedProvider,
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

      final response = await http.post(
        Uri.parse('$baseUrl/booking/create'),
        headers: headers,
        body: jsonEncode(requestBody),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        return data['data'];
      } else {
        throw data['message'] ?? 'Failed to create booking';
      }
    } catch (e) {
      throw e.toString();
    }
  }

  // Get bookings for the current user (client)
  Future<List<Booking>> getBookings({
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('$baseUrl/booking/my-bookings');
      final response = await http.get(uri, headers: headers);
      print('Get my bookings response: \\${response.statusCode} - \\${response.body}');
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        final bookingsList = data['data'] as List;
        return bookingsList.map((json) => Booking.fromJson(json)).toList();
      } else {
        throw data['message'] ?? 'Failed to fetch bookings';
      }
    } catch (e) {
      print('Get my bookings error: \\${e.toString()}');
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

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return Booking.fromJson(data['data']);
      } else {
        throw data['message'] ?? 'Failed to fetch booking';
      }
    } catch (e) {
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

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return data['data'];
      } else {
        throw data['message'] ?? 'Failed to confirm budget';
      }
    } catch (e) {
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

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return data['data'];
      } else {
        throw data['message'] ?? 'Failed to start booking';
      }
    } catch (e) {
      throw e.toString();
    }
  }

  // Mark booking as complete (for workers)
  Future<Map<String, dynamic>> markBookingAsComplete(String bookingId) async {
    assert(bookingId != null && bookingId.isNotEmpty, 'bookingId must not be null or empty');
    print('[DEBUG] markBookingAsComplete called with bookingId: $bookingId');
    try {
      final headers = await _getHeaders();
      final body = jsonEncode({
        'bookingId': bookingId,
      });
      print('[DEBUG] Sending POST to /booking/complete with body: $body');
      final response = await http.post(
        Uri.parse('$baseUrl/booking/complete'),
        headers: headers,
        body: body,
      );
      print('[DEBUG] Response status: \\${response.statusCode}');
      print('[DEBUG] Response body: \\${response.body}');
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return data['data'];
      } else {
        throw data['message'] ?? 'Failed to mark booking as complete';
      }
    } catch (e) {
      print('[DEBUG] Exception in markBookingAsComplete: $e');
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
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return data['data'];
      } else {
        throw data['message'] ?? 'Failed to mark booking as closed';
      }
    } catch (e) {
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

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return data['data'];
      } else {
        throw data['message'] ?? 'Failed to cancel booking';
      }
    } catch (e) {
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

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return data['data'];
      } else {
        throw data['message'] ?? 'Failed to create dispute';
      }
    } catch (e) {
      throw e.toString();
    }
  }

  // Fetch available providers for a service and location
  Future<List<Map<String, dynamic>>> getAvailableProviders({
    required String service,
    required double lng,
    required double lat,
  }) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl/providers/get-available-providers?service=$service&lng=$lng&lat=$lat');
    final response = await http.get(uri, headers: headers);
    final data = jsonDecode(response.body);
    print('Get available providers response: \\${response.statusCode} - \\${response.body}');
    if (response.statusCode == 200 && data['success'] == true) {
      final providers = data['data'] as List;
      return providers.map((e) => Map<String, dynamic>.from(e)).toList();
    } else {
      throw data['message'] ?? 'Failed to fetch providers';
    }
  }

  // Fetch all available service providers
  Future<List<Map<String, dynamic>>> getAllAvailableProviders() async {
    final headers = await _getHeaders();
    final uri = Uri.parse('${baseUrl}/booking/all-available-providers');
    final response = await http.get(uri, headers: headers);
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      final providers = data['data'] as List;
      return providers.map((e) => Map<String, dynamic>.from(e)).toList();
    } else {
      throw data['message'] ?? 'Failed to fetch providers';
    }
  }

  // Fetch bookings for the current provider (worker)
  Future<List<Map<String, dynamic>>> getProviderBookings() async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl/booking/provider-bookings');
    final response = await http.get(uri, headers: headers);
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      final bookings = data['data'] as List;
      return bookings.map((e) => Map<String, dynamic>.from(e)).toList();
    } else {
      throw data['message'] ?? 'Failed to fetch provider bookings';
    }
  }

  // Send invoice (for workers)
  Future<Map<String, dynamic>> sendInvoice({
    required String bookingId,
    required double amount,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/booking/confirm-budget'),
        headers: headers,
        body: jsonEncode({
          'bookingId': bookingId,
          'budget': amount,
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return data['data'];
      } else {
        throw data['message'] ?? 'Failed to send invoice';
      }
    } catch (e) {
      throw e.toString();
    }
  }

  // Approve invoice (for clients)
  Future<Map<String, dynamic>> approveInvoice({
    required String bookingId,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/booking/approve-invoice'),
        headers: headers,
        body: jsonEncode({
          'bookingId': bookingId,
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return data['data'];
      } else {
        throw data['message'] ?? 'Failed to approve invoice';
      }
    } catch (e) {
      throw e.toString();
    }
  }

  // Fetch provider bookings by date
  Future<List<Booking>> getProviderBookingsByDate(DateTime date) async {
    final headers = await _getHeaders();
    final dateString = date.toIso8601String().split('T')[0];
    final uri = Uri.parse('$baseUrl/provider/get-booking-by-date?date=$dateString');
    final response = await http.get(uri, headers: headers);
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      final bookings = data['data'] as List;
      return bookings.map((json) => Booking.fromJson(json)).toList();
    } else {
      throw data['message'] ?? 'Failed to fetch provider bookings by date';
    }
  }

  // Submit a review for a booking
  Future<void> submitReview({required String bookingId, required double rating, required String review}) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/booking/submit-review'),
      headers: headers,
      body: jsonEncode({
        'bookingId': bookingId,
        'rating': rating,
        'review': review,
      }),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return;
    } else {
      throw data['message'] ?? 'Failed to submit review';
    }
  }

  // Fetch workflow steps for a given service
  Future<List<String>> getWorkflowForService(String serviceId) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('[200~$baseUrl/service/workflow/$serviceId');
      final response = await http.get(uri, headers: headers);
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        final steps = data['data'] as List?;
        if (steps == null) return [];
        // Each step may be a map with a 'description' or 'name' field
        return steps.map<String>((step) {
          if (step is Map && step.containsKey('description')) {
            return step['description'] as String;
          } else if (step is Map && step.containsKey('name')) {
            return step['name'] as String;
          } else if (step is String) {
            return step;
          } else {
            return 'Step';
          }
        }).toList();
      } else {
        throw data['message'] ?? 'Failed to fetch workflow steps';
      }
    } catch (e) {
      return [];
    }
  }

  // Fetch services for a given provider (using /service/provider/:providerId)
  Future<List<Map<String, dynamic>>> getProviderServices(String providerId) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('$baseUrl/service/provider/$providerId');
      final response = await http.get(uri, headers: headers);
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        final services = data['data'] as List?;
        if (services == null) return [];
        return services.map((e) => Map<String, dynamic>.from(e)).toList();
      } else {
        throw data['message'] ?? 'Failed to fetch provider services';
      }
    } catch (e) {
      return [];
    }
  }

  // Fetch provider metrics for dashboard quick stats
  Future<Map<String, dynamic>> getProviderMetrics() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/providers/metrics'),
        headers: headers,
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return data['data'] as Map<String, dynamic>;
      } else {
        throw data['message'] ?? 'Failed to fetch provider metrics';
      }
    } catch (e) {
      throw e.toString();
    }
  }
} 