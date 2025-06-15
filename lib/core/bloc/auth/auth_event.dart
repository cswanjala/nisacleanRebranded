import 'package:equatable/equatable.dart';
import 'auth_state.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class LoginRequested extends AuthEvent {
  final String email;
  final String password;
  final UserType userType;

  const LoginRequested({
    required this.email,
    required this.password,
    required this.userType,
  });

  @override
  List<Object?> get props => [email, password, userType];
}

class RegisterRequested extends AuthEvent {
  final String email;
  final String password;
  final String name;
  final UserType userType;

  const RegisterRequested({
    required this.email,
    required this.password,
    required this.name,
    required this.userType,
  });

  @override
  List<Object?> get props => [email, password, name, userType];
}

class LogoutRequested extends AuthEvent {}

class CheckAuthStatus extends AuthEvent {} 