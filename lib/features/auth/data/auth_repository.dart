import 'dart:io';

import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../core/caching/cach_helper.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/network/dio_helper.dart';
import '../../../core/network/failure.dart';
import '../../../core/services/biometric_service.dart';
import '../../../core/services/device_service.dart';
import 'models/auth_session.dart';
import 'models/customer_profile.dart';

class AuthRepository {
  String _extractError(dynamic data) => ServerFailure.extractApiMessage(data);

  Future<String?> sendOtp(String phoneNumber) async {
    try {
      final response = await DioHelper.postDataWithoutAuth(
        url: AppConstants.otpSend,
        data: {
          'phone_number': phoneNumber,
          'user_type': AppConstants.userType,
        },
      );
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw ServerFailure(_extractError(response.data));
      }
      return _extractOtpCode(response.data);
    } on DioException catch (e) {
      throw ServerFailure.fromDioError(e);
    }
  }

  String? _extractOtpCode(dynamic data) {
    if (data is! Map<String, dynamic>) return null;

    for (final key in ['otp_code', 'otp', 'code', 'verification_code']) {
      final value = data[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return null;
  }

  Future<AuthSession> verifyOtp({
    required String phoneNumber,
    required String otpCode,
    String? deviceToken,
  }) async {
    try {
      final response = await DioHelper.postDataWithoutAuth(
        url: AppConstants.otpVerify,
        data: {
          'phone_number': phoneNumber,
          'user_type': AppConstants.userType,
          'otp_code': otpCode,
          if (deviceToken != null && deviceToken.isNotEmpty)
            'device_token': deviceToken,
        },
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw ServerFailure(_extractError(response.data));
      }

      final session = AuthSession.fromJson(
        response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : {},
      );

      await _persistSession(
        session.copyWith(phoneNumber: phoneNumber),
      );
      return session;
    } on DioException catch (e) {
      throw ServerFailure.fromDioError(e);
    }
  }

  Future<CustomerProfile> getProviderProfile() async {
    try {
      final response = await DioHelper.getData(
        url: AppConstants.providerProfile,
      );

      if (response.statusCode != 200) {
        throw ServerFailure(_extractError(response.data));
      }

      final profile = CustomerProfile.fromJson(
        response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : {},
      );

      await CacheHelper().saveData(
        key: AppConstants.userNameKey,
        value: profile.name,
      );
      await CacheHelper().saveData(
        key: AppConstants.phoneNumberKey,
        value: profile.phoneNumber,
      );

      return profile;
    } on DioException catch (e) {
      throw ServerFailure.fromDioError(e);
    }
  }

  Future<CustomerProfile> updateProfile({
    required String name,
    required String phoneNumber,
    File? photo,
  }) async {
    try {
      Response response;
      if (photo != null) {
        final formData = FormData.fromMap({
          'name': name,
          'phone_number': phoneNumber,
          'photo': await MultipartFile.fromFile(
            photo.path,
            filename: photo.path.split('/').last,
          ),
        });
        response = await DioHelper.patchMultipart(
          url: AppConstants.providerProfile,
          data: formData,
        );
      } else {
        response = await DioHelper.patchData(
          url: AppConstants.providerProfile,
          data: {
            'name': name,
            'phone_number': phoneNumber,
          },
        );
      }

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw ServerFailure(_extractError(response.data));
      }

      final map = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};
      final profile = (map.containsKey('id') || map.containsKey('name'))
          ? CustomerProfile.fromJson(map)
          : await getProviderProfile();

      await CacheHelper().saveData(
        key: AppConstants.userNameKey,
        value: profile.name,
      );
      await CacheHelper().saveData(
        key: AppConstants.phoneNumberKey,
        value: profile.phoneNumber,
      );
      return profile;
    } on DioException catch (e) {
      throw ServerFailure.fromDioError(e);
    }
  }

  Future<void> deleteAccount() async {
    try {
      await DioHelper.deleteData(url: AppConstants.providerProfile);
    } on DioException catch (e) {
      throw ServerFailure.fromDioError(e);
    }
    await clearSession();
  }

  Future<void> registerProvider({
    required String name,
    required String phoneNumber,
    required String email,
    required String specializationId,
    required String nationalId,
    required String commercialRegistration,
    required File contractImage,
  }) async {
    try {
      final formData = FormData.fromMap({
        'name': name,
        'phone_number': phoneNumber,
        'email': email,
        'specialization': specializationId,
        'national_id': nationalId,
        'commercial_registration': commercialRegistration,
        'contract_image': await MultipartFile.fromFile(
          contractImage.path,
          filename: contractImage.path.split('/').last,
        ),
      });

      final response = await DioHelper.postMultipartWithoutAuth(
        url: AppConstants.providerRegister,
        data: formData,
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw ServerFailure(_extractError(response.data));
      }

      await CacheHelper().saveData(
        key: AppConstants.userNameKey,
        value: name,
      );
      await CacheHelper().saveData(
        key: AppConstants.phoneNumberKey,
        value: phoneNumber,
      );
    } on DioException catch (e) {
      throw ServerFailure.fromDioError(e);
    }
  }

  Future<void> registerCustomer({
    required String name,
    required String phoneNumber,
  }) async {
    try {
      final response = await DioHelper.postDataWithoutAuth(
        url: AppConstants.providerRegister,
        data: {
          'name': name,
          'phone_number': phoneNumber,
        },
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw ServerFailure(_extractError(response.data));
      }

      await CacheHelper().saveData(
        key: AppConstants.userNameKey,
        value: name,
      );
      await CacheHelper().saveData(
        key: AppConstants.phoneNumberKey,
        value: phoneNumber,
      );
    } on DioException catch (e) {
      throw ServerFailure.fromDioError(e);
    }
  }

  Future<String> registerBiometric() async {
    try {
      final deviceId = await DeviceService.getDeviceId();
      final response = await DioHelper.postData(
        url: AppConstants.biometricRegister,
        data: {'device_id': deviceId},
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw ServerFailure(_extractError(response.data));
      }

      final data = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};

      final biometricToken = data['biometric_token']?.toString();
      if (biometricToken == null || biometricToken.isEmpty) {
        throw ServerFailure('mosaedBiometricTokenNotReceived'.tr());
      }

      await CacheHelper().saveData(
        key: AppConstants.biometricTokenKey,
        value: biometricToken,
      );

      return biometricToken;
    } on DioException catch (e) {
      throw ServerFailure.fromDioError(e);
    }
  }

  Future<AuthSession> loginWithBiometric({String? deviceToken}) async {
    final biometricToken = CacheHelper().getDataString(
      key: AppConstants.biometricTokenKey,
    );

    if (biometricToken == null || biometricToken.isEmpty) {
      throw ServerFailure('mosaedBiometricNoToken'.tr());
    }

    final authenticated = await BiometricService.authenticate(
      reason: 'mosaedBiometricPromptReason'.tr(),
    );

    if (!authenticated) {
      throw ServerFailure('mosaedBiometricAuthFailed'.tr());
    }

    try {
      final deviceId = await DeviceService.getDeviceId();
      final response = await DioHelper.postDataWithoutAuth(
        url: AppConstants.biometricLogin,
        data: {
          'biometric_token': biometricToken,
          'device_id': deviceId,
          if (deviceToken != null && deviceToken.isNotEmpty)
            'device_token': deviceToken,
        },
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw ServerFailure(_extractError(response.data));
      }

      final session = AuthSession.fromJson(
        response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : {},
      );

      await _persistSession(session);
      return session;
    } on DioException catch (e) {
      throw ServerFailure.fromDioError(e);
    }
  }

  Future<void> logout() async {
    final refresh = CacheHelper().getDataString(
      key: AppConstants.refreshTokenKey,
    );

    if (refresh != null && refresh.isNotEmpty) {
      try {
        await DioHelper.postData(
          url: AppConstants.logout,
          data: {'refresh': refresh},
        );
      } catch (_) {}
    }

    await clearSession();
  }

  Future<void> clearSession() async {
    await Future.wait([
      CacheHelper().removeData(key: AppConstants.accessTokenKey),
      CacheHelper().removeData(key: AppConstants.refreshTokenKey),
      CacheHelper().removeData(key: AppConstants.biometricTokenKey),
      CacheHelper().removeData(key: AppConstants.isLoggedInKey),
      CacheHelper().removeData(key: AppConstants.biometricEnabledKey),
    ]);
  }

  bool get isLoggedIn =>
      CacheHelper().getData(key: AppConstants.isLoggedInKey) == true;

  bool get isBiometricEnabled =>
      CacheHelper().getData(key: AppConstants.biometricEnabledKey) == true;

  bool get hasBiometricToken {
    final token = CacheHelper().getDataString(key: AppConstants.biometricTokenKey);
    return token != null && token.isNotEmpty;
  }

  bool get canUseBiometricLogin =>
      isBiometricEnabled && hasBiometricToken;

  Future<bool> canUseBiometricLoginOnDevice() async {
    if (!canUseBiometricLogin) return false;
    return BiometricService.isFingerprintAvailable();
  }

  Future<void> registerBiometricInBackground() async {
    try {
      final available = await BiometricService.isFingerprintAvailable();
      if (!available) return;
      await registerBiometric();
      await enableBiometric();
    } catch (_) {}
  }

  Future<({bool success, String? error})> setupBiometricLogin({
    required String promptMessage,
  }) async {
    final authenticated = await BiometricService.authenticate(
      reason: promptMessage,
    );
    if (!authenticated) {
      return (success: false, error: 'mosaedBiometricAuthCancelled'.tr());
    }

    try {
      await registerBiometric();
    } on ServerFailure catch (e) {
      return (success: false, error: e.errMessage);
    }

    await enableBiometric();
    return (success: true, error: null);
  }

  String? get storedPhone =>
      CacheHelper().getDataString(key: AppConstants.phoneNumberKey);

  String get userName =>
      CacheHelper().getDataString(key: AppConstants.userNameKey) ??
      'user'.tr();

  Future<void> enableBiometric() async {
    await CacheHelper().saveData(
      key: AppConstants.biometricEnabledKey,
      value: true,
    );
  }

  Future<bool> enableBiometricLogin() async {
    if (!hasBiometricToken) return false;
    await enableBiometric();
    return true;
  }

  Future<void> disableBiometric() async {
    await CacheHelper().removeData(key: AppConstants.biometricEnabledKey);
  }

  Future<void> _persistSession(AuthSession session) async {
    if (session.accessToken != null) {
      await CacheHelper().saveData(
        key: AppConstants.accessTokenKey,
        value: session.accessToken!,
      );
    }
    if (session.refreshToken != null) {
      await CacheHelper().saveData(
        key: AppConstants.refreshTokenKey,
        value: session.refreshToken!,
      );
    }
    if (session.biometricToken != null) {
      await CacheHelper().saveData(
        key: AppConstants.biometricTokenKey,
        value: session.biometricToken!,
      );
    }
    if (session.userName != null) {
      await CacheHelper().saveData(
        key: AppConstants.userNameKey,
        value: session.userName!,
      );
    }
    if (session.phoneNumber != null) {
      await CacheHelper().saveData(
        key: AppConstants.phoneNumberKey,
        value: session.phoneNumber!,
      );
    }
    await CacheHelper().saveData(key: AppConstants.isLoggedInKey, value: true);
  }
}

extension _AuthSessionCopy on AuthSession {
  AuthSession copyWith({
    String? accessToken,
    String? refreshToken,
    String? biometricToken,
    String? userName,
    String? phoneNumber,
  }) {
    return AuthSession(
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      biometricToken: biometricToken ?? this.biometricToken,
      userName: userName ?? this.userName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
    );
  }
}
