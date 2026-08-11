import 'dart:convert';
import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';


import '../../app/navigator_key.dart';
import '../caching/cach_helper.dart';

class AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    log('AuthInterceptor - Request sending: ${options.method} ${options.uri}');
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // log('AuthInterceptor - Response received: ${response.data}');
    // Check if response indicates invalid token
    if (response.statusCode == 401 || _isInvalidTokenResponse(response.data)) {
      log('Invalid token detected, redirecting to login');
      _handleInvalidToken();
      return; // Don't continue with the response
    }
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Check if error response indicates invalid token or unauthorized
    final statusCode = err.response?.statusCode;
    if (statusCode == 401 ||
        (err.response?.data != null &&
            _isInvalidTokenResponse(err.response!.data))) {
      log('Invalid token detected in error, redirecting to login');
      _handleInvalidToken();
    }
    super.onError(err, handler);
  }

  bool _isInvalidTokenResponse(dynamic responseData) {
    log('AuthInterceptor - Checking response data: $responseData');

    if (responseData is String) {
      try {
        // Try to parse JSON string
        final Map<String, dynamic> jsonData = const JsonDecoder().convert(
          responseData,
        );
        return _checkInvalidTokenInMap(jsonData);
      } catch (e) {
        log('AuthInterceptor - Failed to parse JSON string: $e');
        return false;
      }
    } else if (responseData is Map<String, dynamic>) {
      return _checkInvalidTokenInMap(responseData);
    }
    return false;
  }

  bool _checkInvalidTokenInMap(Map<String, dynamic> data) {
    // Some APIs return different keys for auth errors. Normalize common fields.
    final dynamic message =
        data['message'] ??
        data['error_message'] ??
        data['error'] ??
        data['detail'];
    final dynamic status =
        data['status'] ?? data['status_code'] ?? data['statusCode'];

    log('AuthInterceptor - Checking: status=$status, message=$message');

    // Exact/explicit checks
    if (message == 'Invalid token.' && status == 'fail') {
      log('AuthInterceptor - Exact match found!');
      return true;
    }

    // Pattern-based checks for auth-related messages
    final msgStr = message?.toString().toLowerCase() ?? '';
    if (msgStr.contains('invalid token') ||
        msgStr.contains('unauthorized') ||
        msgStr.contains('token expired') ||
        msgStr.contains('authentication credentials') ||
        msgStr.contains('authentication') && msgStr.contains('provided') ||
        msgStr.contains('not authenticated') ||
        msgStr.contains('login required')) {
      log('AuthInterceptor - Pattern match found for auth issue!');
      return true;
    }

    return false;
  }

  void _handleInvalidToken() async {
    try {
      // Clear all cached auth data
      await CacheHelper().removeData(key: 'access_token');
      await CacheHelper().removeData(key: 'refresh_token');
      await CacheHelper().removeData(key: 'user_id');

      // Navigate to login screen using the global navigator key
      final context = navigatorKey.currentContext;
      if (context != null) {
        // Clear all routes and navigate to login
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/login', (route) => false);

        // Show a message to user
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('انتهت صلاحية الجلسة، يرجى تسجيل الدخول مرة أخرى'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      log('Error handling invalid token: $e');
    }
  }
}
