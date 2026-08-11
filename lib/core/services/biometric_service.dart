import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

class BiometricService {
  BiometricService._();

  static final LocalAuthentication _localAuth = LocalAuthentication();

  static bool _isChannelError(Object error) {
    return error is PlatformException && error.code == 'channel-error';
  }

  static bool _isAndroidFingerprint(List<BiometricType> types) {
    if (types.isEmpty) return true;
    return types.contains(BiometricType.fingerprint) ||
        types.contains(BiometricType.strong) ||
        types.contains(BiometricType.weak);
  }

  static Future<bool> isFingerprintAvailable() async {
    try {
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      if (!isDeviceSupported) return false;

      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      if (!canCheckBiometrics) return false;

      final availableBiometrics = await _localAuth.getAvailableBiometrics();

      if (defaultTargetPlatform == TargetPlatform.android) {
        return _isAndroidFingerprint(availableBiometrics);
      }

      return availableBiometrics.contains(BiometricType.fingerprint);
    } on PlatformException catch (e) {
      if (_isChannelError(e)) return false;
      return false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> authenticate({required String reason}) async {
    try {
      if (!await isFingerprintAvailable()) return false;

      return await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
    } on PlatformException catch (e) {
      if (_isChannelError(e)) return false;
      return false;
    } catch (_) {
      return false;
    }
  }
}
