import 'package:equatable/equatable.dart';

enum UserType { client, serviceProvider }

class AuthState extends Equatable {
  final bool isAuthenticated;
  final UserType? userType;
  final String? name;
  final String? email;
  final String? error;

  const AuthState({
    this.isAuthenticated = false,
    this.userType,
    this.name,
    this.email,
    this.error,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    UserType? userType,
    String? name,
    String? email,
    String? error,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      userType: userType ?? this.userType,
      name: name ?? this.name,
      email: email ?? this.email,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [isAuthenticated, userType, name, email, error];
} 