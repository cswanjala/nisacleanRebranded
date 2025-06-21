import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../services/auth_service.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService _authService = AuthService();
  
  AuthBloc() : super(const AuthState()) {
    on<LoginRequested>(_onLoginRequested);
    on<RegisterRequested>(_onRegisterRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<CheckAuthStatus>(_onCheckAuthStatus);
    on<UpdateProfileRequested>(_onUpdateProfileRequested);
    on<FetchProfileRequested>(_onFetchProfileRequested);
  }

  void _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));
    
    try {
      final result = await _authService.login(event.email, event.password);
      
      // Map backend role to UserType
      UserType userType = UserType.client;
      if (result['role'] == 'worker') {
        userType = UserType.serviceProvider;
      }
      
      // Fetch real user profile after login
      final profile = await _authService.fetchUserProfile();
      print('Fetched user profile: ' + profile.toString());
        emit(state.copyWith(
          isAuthenticated: true,
        isLoading: false,
        userType: userType,
        name: profile['name'] ?? 'User',
        email: profile['email'] ?? event.email,
        phone: profile['phone'] ?? '',
        token: result['token'],
        ));
    } catch (e) {
        emit(state.copyWith(
          isAuthenticated: false,
        isLoading: false,
        error: e.toString(),
        ));
    }
  }

  void _onRegisterRequested(
    RegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));
    
    try {
      // Map UserType to backend role
      String role = 'client';
      if (event.userType == UserType.serviceProvider) {
        role = 'worker';
      }
      
      await _authService.register(
        name: event.name,
        email: event.email,
        phone: event.phone ?? '', // Add phone field if needed
        password: event.password,
        role: role,
      );
      
      // Registration successful, but user needs to login
      emit(state.copyWith(
        isLoading: false,
        error: null,
      ));
      
      // You might want to automatically login after registration
      // or show a success message and redirect to login
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  void _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await _authService.logout();
    } catch (e) {
      // Log error but still clear local state
      print('Logout error: $e');
    }
    emit(const AuthState());
  }

  void _onCheckAuthStatus(
    CheckAuthStatus event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final isAuthenticated = await _authService.isAuthenticated();
      if (isAuthenticated) {
        final user = await _authService.getUser();
        final token = await _authService.getToken();
        
        UserType userType = UserType.client;
        if (user?['role'] == 'worker') {
          userType = UserType.serviceProvider;
        }
        
        // Fetch real user profile
        final profile = await _authService.fetchUserProfile();
        print('Fetched user profile: ' + profile.toString());
        emit(state.copyWith(
          isAuthenticated: true,
          userType: userType,
          name: profile['name'] ?? 'User',
          email: profile['email'] ?? '',
          phone: profile['phone'] ?? '',
          token: token,
        ));
      } else {
        emit(const AuthState());
      }
    } catch (e) {
    emit(const AuthState());
    }
  }

  void _onUpdateProfileRequested(
    UpdateProfileRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      await _authService.updateUserProfile(
        name: event.name,
        email: event.email,
        phone: event.phone,
      );
      // Fetch updated profile
      final profile = await _authService.fetchUserProfile();
      emit(state.copyWith(
        isLoading: false,
        name: profile['name'] ?? state.name,
        email: profile['email'] ?? state.email,
        phone: profile['phone'] ?? state.phone,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  void _onFetchProfileRequested(
    FetchProfileRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final profile = await _authService.fetchUserProfile();
      emit(state.copyWith(
        isLoading: false,
        name: profile['name'] ?? state.name,
        email: profile['email'] ?? state.email,
        phone: profile['phone'] ?? state.phone,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }
} 