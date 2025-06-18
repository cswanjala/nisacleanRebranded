import 'package:equatable/equatable.dart';

enum UserType { client, serviceProvider }

class AuthState extends Equatable {
  final bool isAuthenticated;
  final bool isLoading;
  final UserType? userType;
  final String? name;
  final String? email;
  final String? token;
  final String? error;

  const AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.userType,
    this.name,
    this.email,
    this.token,
    this.error,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    UserType? userType,
    String? name,
    String? email,
    String? token,
    String? error,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      userType: userType ?? this.userType,
      name: name ?? this.name,
      email: email ?? this.email,
      token: token ?? this.token,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [isAuthenticated, isLoading, userType, name, email, token, error];
} 