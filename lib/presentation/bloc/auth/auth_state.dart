import 'package:equatable/equatable.dart';
import '../../../data/models/driver_model.dart';


abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final Driver driver;

  const AuthAuthenticated(this.driver);

  @override
  List<Object?> get props => [driver];
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}

class AuthStatusUpdating extends AuthState {
  final Driver driver;

  const AuthStatusUpdating(this.driver);

  @override
  List<Object?> get props => [driver];
}

class AuthStatusUpdated extends AuthState {
  final Driver driver;

  const AuthStatusUpdated(this.driver);

  @override
  List<Object?> get props => [driver];
}

class AuthProfileUpdating extends AuthState {
  final Driver driver;

  const AuthProfileUpdating(this.driver);

  @override
  List<Object?> get props => [driver];
}


