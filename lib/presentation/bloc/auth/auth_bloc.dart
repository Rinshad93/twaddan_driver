import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/utils/service_locator.dart';
import '../../../data/models/driver_model.dart';
import '../../../data/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc({AuthRepository? authRepository})
      : _authRepository = authRepository ?? ServiceLocator().authRepository,
        super(const AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthLoginRequested>(_onAuthLoginRequested);
    on<AuthLogoutRequested>(_onAuthLogoutRequested);
    on<AuthDriverStatusToggled>(_onAuthDriverStatusToggled);
    on<AuthDriverUpdated>(_onAuthDriverUpdated);
    on<AuthErrorCleared>(_onAuthErrorCleared);
  }

  Future<void> _onAuthCheckRequested(
      AuthCheckRequested event,
      Emitter<AuthState> emit,
      ) async {
    try {
      emit(const AuthLoading());

      final isLoggedIn = await _authRepository.isLoggedIn();

      if (isLoggedIn) {
        final driver = await _authRepository.getCurrentDriver();
        if (driver != null) {
          emit(AuthAuthenticated(driver));
        } else {
          emit(const AuthUnauthenticated());
        }
      } else {
        emit(const AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthError('Failed to check authentication: ${e.toString()}'));
    }
  }

  Future<void> _onAuthLoginRequested(
      AuthLoginRequested event,
      Emitter<AuthState> emit,
      ) async {
    try {
      emit(const AuthLoading());

      final driver = event.isPhoneLogin
          ? await _authRepository.loginWithPhone(event.email, event.password)
          : await _authRepository.login(event.email, event.password);

      emit(AuthAuthenticated(driver));
    } catch (e) {
      emit(AuthError(_getReadableErrorMessage(e.toString())));
    }
  }

  Future<void> _onAuthLogoutRequested(
      AuthLogoutRequested event,
      Emitter<AuthState> emit,
      ) async {
    // Check if user is currently authenticated and online
    if (state is AuthAuthenticated) {
      final driver = (state as AuthAuthenticated).driver;

      // Prevent logout if driver is online
      if (driver.isOnline) {
        emit(AuthError('You cannot logout while you are online. Please go offline first.'));
        // Return to authenticated state after showing error
        await Future.delayed(const Duration(milliseconds: 100));
        emit(AuthAuthenticated(driver));
        return;
      }
    }

    try {
      emit(const AuthLoading());
      await _authRepository.logout();
      emit(const AuthUnauthenticated());
    } catch (e) {
      emit(AuthError('Failed to logout: ${e.toString()}'));
      // Return to previous state on error
      if (state is AuthAuthenticated) {
        final driver = (state as AuthAuthenticated).driver;
        emit(AuthAuthenticated(driver));
      }
    }
  }

  Future<void> _onAuthDriverStatusToggled(
      AuthDriverStatusToggled event,
      Emitter<AuthState> emit,
      ) async {
    if (state is! AuthAuthenticated) return;

    final currentDriver = (state as AuthAuthenticated).driver;

    try {
      // Use AuthStatusUpdating instead of AuthLoading to prevent navigation issues
      emit(AuthStatusUpdating(currentDriver));

      final updatedDriver = await _authRepository.updateDriverStatus(event.isOnline);

      // Emit the status updated state briefly with success feedback
      emit(AuthStatusUpdated(updatedDriver));

      // After a brief moment, return to authenticated state
      await Future.delayed(const Duration(milliseconds: 800));
      emit(AuthAuthenticated(updatedDriver));
    } catch (e) {
      emit(AuthError('Failed to update status: ${e.toString()}'));
      // Return to previous state on error
      await Future.delayed(const Duration(milliseconds: 100));
      emit(AuthAuthenticated(currentDriver));
    }
  }

  Future<void> _onAuthDriverUpdated(
      AuthDriverUpdated event,
      Emitter<AuthState> emit,
      ) async {
    if (state is! AuthAuthenticated) return;

    try {
      // Use a more specific loading state for profile updates
      final currentDriver = (state as AuthAuthenticated).driver;
      emit(AuthProfileUpdating(currentDriver));

      final updatedDriver = await _authRepository.updateDriver(event.driver);

      emit(AuthAuthenticated(updatedDriver));
    } catch (e) {
      emit(AuthError('Failed to update profile: ${e.toString()}'));
      // Return to previous state on error
      if (state is AuthAuthenticated) {
        final driver = (state as AuthAuthenticated).driver;
        emit(AuthAuthenticated(driver));
      }
    }
  }

  Future<void> _onAuthErrorCleared(
      AuthErrorCleared event,
      Emitter<AuthState> emit,
      ) async {
    if (state is AuthError) {
      // Check current auth state after clearing error
      try {
        final isLoggedIn = await _authRepository.isLoggedIn();
        if (isLoggedIn) {
          final driver = await _authRepository.getCurrentDriver();
          if (driver != null) {
            emit(AuthAuthenticated(driver));
          } else {
            emit(const AuthUnauthenticated());
          }
        } else {
          emit(const AuthUnauthenticated());
        }
      } catch (e) {
        emit(const AuthUnauthenticated());
      }
    }
  }

  String _getReadableErrorMessage(String error) {
    if (error.contains('Invalid email') || error.contains('Invalid phone')) {
      return 'Invalid email or password';
    } else if (error.contains('password')) {
      return 'Invalid password';
    } else if (error.contains('network') || error.contains('connection')) {
      return 'Network connection error. Please try again.';
    } else if (error.contains('online')) {
      return 'You cannot logout while you are online. Please go offline first.';
    } else {
      return 'Login failed. Please check your credentials.';
    }
  }

  // Helper method to check if driver is online
  bool get isDriverOnline {
    if (state is AuthAuthenticated) {
      return (state as AuthAuthenticated).driver.isOnline;
    }
    return false;
  }

  // Helper method to get current driver
  Driver? get currentDriver {
    if (state is AuthAuthenticated) {
      return (state as AuthAuthenticated).driver;
    }
    return null;
  }

  // Helper method to check if any operation is in progress
  bool get isOperationInProgress {
    return state is AuthStatusUpdating ||
        state is AuthStatusUpdated ||
        state is AuthProfileUpdating;
  }
}

