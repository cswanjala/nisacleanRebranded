import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nisacleanv1/core/constants/api_constants.dart';
import 'package:nisacleanv1/core/bloc/auth/auth_state.dart';

class AuthService {
  // Use centralized base URL
  static const String baseUrl = ApiConstants.baseUrl;
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';

  // Login user
  Future<Map<String, dynamic>> login(String identifier, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'identifier': identifier,
          'password': password,
        }),
      );

      print('Login Response Status: ${response.statusCode}');
      print('Login Response Body: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final responseData = data['data'];
        if (responseData['token'] == null) {
          throw 'Token not found in response';
        }
        // Save token and user data
        await _saveAuthData(responseData['token'], {
          'role': responseData['role'] ?? 'client',
          'token': responseData['token'],
        });
        return responseData;
      } else {
        final errorMessage = data['message'] ?? 'Login failed';
        throw errorMessage;
      }
    } catch (e) {
      print('Login Error: $e');
      if (e is FormatException) {
        throw 'Invalid response from server';
      }
      throw e.toString();
    }
  }

  // Register user - Updated to match backend API
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String role,
  }) async {
    try {
      final requestBody = {
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
        'role': role,
        'location': {
          'coordinates': [0.0, 0.0] // Default coordinates (can be updated later)
        }
      };

      print('Registering user with data: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      print('Registration Response Status: ${response.statusCode}');
      print('Registration Response Body: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return data;
      } else {
        final errorMessage = data['message'] ?? 'Registration failed';
        throw errorMessage;
      }
    } catch (e) {
      print('Registration Error: $e');
      if (e is FormatException) {
        throw 'Invalid response from server';
      }
      throw e.toString();
    }
  }

  // Forgot password
  Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/forgotPassword'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data;
      } else {
        throw data['message'] ?? 'Failed to send reset token';
      }
    } catch (e) {
      throw e.toString();
    }
  }

  // Reset password
  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String passwordResetToken,
    required String password,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/auth/resetPassword'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'passwordResetToken': passwordResetToken,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data;
      } else {
        throw data['message'] ?? 'Failed to reset password';
      }
    } catch (e) {
      throw e.toString();
    }
  }

  // Get current user
  Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final token = await getToken();
      if (token == null) throw 'Not authenticated';

      final response = await http.get(
        Uri.parse('$baseUrl/auth/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data;
      } else {
        throw data['message'] ?? 'Failed to get user data';
      }
    } catch (e) {
      throw e.toString();
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      final token = await getToken();
      if (token == null) return;

      final response = await http.get(
        Uri.parse('$baseUrl/auth/logout'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        await _clearAuthData();
      } else {
        throw 'Logout failed';
      }
    } catch (e) {
      throw e.toString();
    }
  }

  // Helper methods for token management
  Future<void> _saveAuthData(String token, Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    // DEBUG: Print what is being saved
    print('[DEBUG] _saveAuthData: user = ' + jsonEncode(user));
    await prefs.setString(tokenKey, token);
    await prefs.setString(userKey, jsonEncode(user));
  }

  Future<void> _clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(tokenKey);
    await prefs.remove(userKey);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(tokenKey);
  }

  Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString(userKey);
    if (userStr == null) return null;
    final user = jsonDecode(userStr);
    // DEBUG: Print what is being loaded
    print('[DEBUG] getUser: loaded user = ' + userStr);
    return user;
  }

  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null;
  }

  // Fetch user profile
  Future<Map<String, dynamic>> fetchUserProfile({UserType? userType}) async {
    try {
      final token = await getToken();
      if (token == null) throw 'Not authenticated';
      // Determine user type
      UserType? type = userType;
      if (type == null) {
        final user = await getUser();
        final role = user?['role']?.toString()?.toLowerCase()?.trim();
        if (role == 'worker') {
          type = UserType.serviceProvider;
        } else {
          type = UserType.client;
        }
      }
      if (type == UserType.serviceProvider) {
        // Fetch provider profile
        final url = '$baseUrl/providers/get-current-provider';
        final headers = {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        };
        print('Fetching provider profile: $url');
        final response = await http.get(
          Uri.parse(url),
          headers: headers,
        );
        print('Provider Profile Response Status: \\${response.statusCode}');
        print('Provider Profile Response Body: \\${response.body}');
        final data = jsonDecode(response.body);
        if (response.statusCode == 200 && data['data'] != null) {
          final provider = data['data'];
          // Return a unified profile map for workers
          return {
            'name': provider['user']?['name'] ?? '',
            'email': provider['user']?['email'] ?? '',
            'phone': provider['user']?['phone'] ?? '',
            'providerProfile': provider,
          };
        } else {
          throw data['message'] ?? 'Failed to fetch provider profile';
        }
      } else {
        // Fetch normal user profile
        final url = '$baseUrl/users/me';
        final headers = {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        };
        print('Fetching user profile: $url');
        final response = await http.get(
          Uri.parse(url),
          headers: headers,
        );
        print('Profile Response Status: \\${response.statusCode}');
        print('Profile Response Body: \\${response.body}');
        final data = jsonDecode(response.body);
        if (response.statusCode == 200 && data['_id'] != null) {
          return data;
        } else if (response.statusCode == 200 && data['data'] != null) {
          return data['data'];
        } else {
          throw data['message'] ?? 'Failed to fetch user profile';
        }
      }
    } catch (e) {
      print('Profile Fetch Error: $e');
      throw e.toString();
    }
  }

  // Update user profile
  Future<Map<String, dynamic>> updateUserProfile({
    String? name,
    String? email,
    String? phone,
  }) async {
    try {
      final token = await getToken();
      if (token == null) throw 'Not authenticated';
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (email != null) body['email'] = email;
      if (phone != null) body['phone'] = phone;
      final response = await http.put(
        Uri.parse('$baseUrl/users/updateMe'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['data'] != null) {
        return data['data'];
      } else {
        throw data['message'] ?? 'Failed to update profile';
      }
    } catch (e) {
      throw e.toString();
    }
  }

  // Fetch current provider profile (ensure correct endpoint)
  Future<Map<String, dynamic>> fetchCurrentProviderProfile() async {
    try {
      final token = await getToken();
      if (token == null) throw 'Not authenticated';
      final url = '$baseUrl/providers/get-current-provider';
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };
      print('Fetching provider profile: $url');
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );
      print('Provider Profile Response Status: \\${response.statusCode}');
      print('Provider Profile Response Body: \\${response.body}');
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['data'] != null) {
        return data['data'];
      } else {
        throw data['message'] ?? 'Failed to fetch provider profile';
      }
    } catch (e) {
      print('Provider Profile Fetch Error: $e');
      throw e.toString();
    }
  }

  // Toggle provider availability
  Future<bool> toggleProviderAvailability() async {
    final token = await getToken();
    if (token == null) throw 'Not authenticated';
    final url = '$baseUrl/providers/toggle-availability';
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return data['isAvailable'] == true;
    } else {
      throw data['message'] ?? 'Failed to toggle availability';
    }
  }
} 