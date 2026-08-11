part of 'auth_cubit.dart';

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

class OtpSent extends AuthState {
  const OtpSent({
    required this.phoneNumber,
    this.otpCode,
  });

  final String phoneNumber;
  final String? otpCode;

  @override
  List<Object?> get props => [phoneNumber, otpCode];
}

class RegisterSuccess extends AuthState {
  const RegisterSuccess({required this.phoneNumber});

  final String phoneNumber;

  @override
  List<Object?> get props => [phoneNumber];
}

class AuthVerified extends AuthState {
  const AuthVerified({required this.session});

  final AuthSession session;

  @override
  List<Object?> get props => [session];
}

class AuthLoggedOut extends AuthState {
  const AuthLoggedOut();
}

class AuthFailure extends AuthState {
  const AuthFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class ProfileLoading extends AuthState {
  const ProfileLoading();
}

class ProfileLoaded extends AuthState {
  const ProfileLoaded({required this.profile});

  final CustomerProfile profile;

  @override
  List<Object?> get props => [profile];
}

class ProfileFailure extends AuthState {
  const ProfileFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
