import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Fired when app starts
class CheckAuthStatus extends AuthEvent {
  const CheckAuthStatus();
}

/// Email & Password Login
class SignInRequested extends AuthEvent {
  final String email;
  final String password;

  const SignInRequested({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

/// Email & Password Signup
class SignUpRequested extends AuthEvent {
  final String email;
  final String password;

  const SignUpRequested({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

/// Google Login
class GoogleSignInRequested extends AuthEvent {
  const GoogleSignInRequested();
}

/// Logout
class SignOutRequested extends AuthEvent {
  const SignOutRequested();
}

/// Forgot Password
class ForgotPasswordRequested extends AuthEvent {
  final String email;

  const ForgotPasswordRequested({required this.email});

  @override
  List<Object?> get props => [email];
}

/// Update display name
class UpdateProfileRequested extends AuthEvent {
  final String displayName;

  const UpdateProfileRequested({required this.displayName});

  @override
  List<Object?> get props => [displayName];
}
