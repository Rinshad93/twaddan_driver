import 'package:equatable/equatable.dart';
import '../../../data/models/driver_model.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;
  final bool isPhoneLogin;

  const AuthLoginRequested({
    required this.email,
    required this.password,
    this.isPhoneLogin = false,
  });

  @override
  List<Object?> get props => [email, password, isPhoneLogin];
}

class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

class AuthDriverStatusToggled extends AuthEvent {
  final bool isOnline;

  const AuthDriverStatusToggled(this.isOnline);

  @override
  List<Object?> get props => [isOnline];
}

class AuthDriverUpdated extends AuthEvent {
  final Driver driver;

  const AuthDriverUpdated(this.driver);

  @override
  List<Object?> get props => [driver];
}

class AuthErrorCleared extends AuthEvent {
  const AuthErrorCleared();
}