import 'package:equatable/equatable.dart';

enum UserType { client, serviceProvider }

class AuthState extends Equatable {
  final bool isAuthenticated;
  final bool isLoading;
  final UserType? userType;
  final String? name;
  final String? email;
  final String? phone;
  final String? token;
  final String? error;
  final String? userId;

  const AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.userType,
    this.name,
    this.email,
    this.phone,
    this.token,
    this.error,
    this.userId,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    UserType? userType,
    String? name,
    String? email,
    String? phone,
    String? token,
    String? error,
    String? userId,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      userType: userType ?? this.userType,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      token: token ?? this.token,
      error: error ?? this.error,
      userId: userId ?? this.userId,
    );
  }

  @override
  List<Object?> get props => [isAuthenticated, isLoading, userType, name, email, phone, token, error, userId];
} 