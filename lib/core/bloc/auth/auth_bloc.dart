import 'package:flutter_bloc/flutter_bloc.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(const AuthState()) {
    on<LoginRequested>(_onLoginRequested);
    on<RegisterRequested>(_onRegisterRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<CheckAuthStatus>(_onCheckAuthStatus);
  }

  void _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    // Static login validation for different user types
    if (event.userType == UserType.client) {
      if (event.email == 'client@example.com' && event.password == 'password123') {
        emit(state.copyWith(
          isAuthenticated: true,
          userType: event.userType,
          name: 'Test Client',
          email: event.email,
        ));
      } else {
        emit(state.copyWith(
          isAuthenticated: false,
          error: 'Invalid client credentials',
        ));
      }
    } else {
      // Service Provider login
      if (event.email == 'provider@example.com' && event.password == 'password123') {
        emit(state.copyWith(
          isAuthenticated: true,
          userType: event.userType,
          name: 'Test Provider',
          email: event.email,
        ));
      } else {
        emit(state.copyWith(
          isAuthenticated: false,
          error: 'Invalid service provider credentials',
        ));
      }
    }
  }

  void _onRegisterRequested(
    RegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    // Static registration validation
    if (event.email.isNotEmpty && event.password.length >= 6) {
      emit(state.copyWith(
        isAuthenticated: true,
        userType: event.userType,
        name: event.name,
        email: event.email,
      ));
    } else {
      emit(state.copyWith(
        isAuthenticated: false,
        error: 'Registration failed. Please check your details.',
      ));
    }
  }

  void _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) {
    emit(const AuthState());
  }

  void _onCheckAuthStatus(
    CheckAuthStatus event,
    Emitter<AuthState> emit,
  ) {
    // For now, always return not authenticated
    emit(const AuthState());
  }
} 