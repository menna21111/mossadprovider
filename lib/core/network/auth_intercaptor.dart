import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../app/functions.dart';
import '../../app/navigator_key.dart';
import '../caching/cach_helper.dart';
import '../constants/app_constants.dart';
import '../constants/mosaed_colors.dart';

class AuthInterceptor extends Interceptor {
  static const _publicPathSnippets = [
    AppConstants.otpSend,
    AppConstants.otpVerify,
    AppConstants.providerRegister,
    AppConstants.specializations,
    AppConstants.biometricLogin,
    AppConstants.tokenRefresh,
  ];

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    log('AuthInterceptor - Request sending: ${options.method} ${options.uri}');
    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final statusCode = err.response?.statusCode;
    if (statusCode == 401) {
      _handleUnauthorized(err.requestOptions.path);
    }
    super.onError(err, handler);
  }

  bool _isPublicPath(String path) {
    return _publicPathSnippets.any(
      (snippet) => path.contains(snippet),
    );
  }

  bool _isLoggedIn() {
    return CacheHelper().getData(key: AppConstants.isLoggedInKey) == true;
  }

  void _handleUnauthorized(String path) {
    if (_isPublicPath(path)) {
      log('AuthInterceptor - 401 on public path ignored: $path');
      return;
    }

    if (!_isLoggedIn()) {
      log('AuthInterceptor - 401 while logged out, skipping session toast');
      return;
    }

    log('Invalid token detected, redirecting to login');
    _kickToLogin();
  }

  Future<void> _kickToLogin() async {
    try {
      await CacheHelper().removeData(key: AppConstants.accessTokenKey);
      await CacheHelper().removeData(key: AppConstants.refreshTokenKey);
      await CacheHelper().removeData(key: AppConstants.isLoggedInKey);

      final context = navigatorKey.currentContext;
      if (context == null || !context.mounted) return;

      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);

      AppFunctions.showsToast(
        'mosaedSessionExpired'.tr(),
        MosaedColors.danger,
        context,
        seconds: 3,
      );
    } catch (e) {
      log('Error handling invalid token: $e');
    }
  }
}
