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
  final String? phone;
  final UserType userType;

  const RegisterRequested({
    required this.email,
    required this.password,
    required this.name,
    this.phone,
    required this.userType,
  });

  @override
  List<Object?> get props => [email, password, name, phone, userType];
}

class LogoutRequested extends AuthEvent {}

class CheckAuthStatus extends AuthEvent {}

class UpdateProfileRequested extends AuthEvent {
  final String? name;
  final String? email;
  final String? phone;
  final String? imagePath;

  const UpdateProfileRequested({this.name, this.email, this.phone, this.imagePath});

  @override
  List<Object?> get props => [name, email, phone, imagePath];
}

class FetchProfileRequested extends AuthEvent {}