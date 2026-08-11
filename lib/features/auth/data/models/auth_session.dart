class AuthSession {
  final String? accessToken;
  final String? refreshToken;
  final String? biometricToken;
  final String? userName;
  final String? phoneNumber;

  const AuthSession({
    this.accessToken,
    this.refreshToken,
    this.biometricToken,
    this.userName,
    this.phoneNumber,
  });

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    final tokens = json['tokens'] is Map<String, dynamic>
        ? json['tokens'] as Map<String, dynamic>
        : null;

    return AuthSession(
      accessToken:
          json['access']?.toString() ??
          tokens?['access']?.toString() ??
          json['access_token']?.toString(),
      refreshToken:
          json['refresh']?.toString() ??
          tokens?['refresh']?.toString() ??
          json['refresh_token']?.toString(),
      biometricToken:
          json['biometric_token']?.toString() ??
          tokens?['biometric_token']?.toString(),
      userName: json['name']?.toString() ?? json['user']?['name']?.toString(),
      phoneNumber:
          json['phone_number']?.toString() ??
          json['user']?['phone_number']?.toString(),
    );
  }

  bool get isAuthenticated =>
      (accessToken != null && accessToken!.isNotEmpty) ||
      (refreshToken != null && refreshToken!.isNotEmpty);
}
