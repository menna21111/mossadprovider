import 'dart:io';

import 'package:dio/dio.dart';

abstract class Failure {
  final String errMessage;

  const Failure(this.errMessage);
}

class ServerFailure extends Failure {
  ServerFailure(super.errMessage);

  static String extractApiMessage(
    dynamic data, {
    String fallback = 'حدث خطأ، حاول مرة أخرى',
  }) {
    if (data is String && data.trim().isNotEmpty) return data.trim();

    if (data is Map<String, dynamic>) {
      final detail = data['detail'];
      if (detail != null && detail.toString().trim().isNotEmpty) {
        return detail.toString();
      }

      final message = data['message'];
      if (message != null && message.toString().trim().isNotEmpty) {
        return message.toString();
      }

      final nonFieldErrors = data['non_field_errors'];
      if (nonFieldErrors is List && nonFieldErrors.isNotEmpty) {
        return nonFieldErrors.first.toString();
      }

      final errorMessage = data['error_message'];
      if (errorMessage is List && errorMessage.isNotEmpty) {
        return errorMessage.first.toString();
      }
      if (errorMessage is String && errorMessage.trim().isNotEmpty) {
        return errorMessage;
      }

      final error = data['error'];
      if (error != null && error.toString().trim().isNotEmpty) {
        return error.toString();
      }

      for (final entry in data.entries) {
        if (entry.value is List && (entry.value as List).isNotEmpty) {
          return (entry.value as List).first.toString();
        }
        if (entry.value is String && entry.value.toString().trim().isNotEmpty) {
          return entry.value.toString();
        }
      }
    }

    return fallback;
  }

  static bool _isConnectionIssue(DioException dioError) {
    if (dioError.type == DioExceptionType.connectionTimeout ||
        dioError.type == DioExceptionType.sendTimeout ||
        dioError.type == DioExceptionType.receiveTimeout ||
        dioError.type == DioExceptionType.connectionError) {
      return true;
    }

    final error = dioError.error;
    if (error is SocketException || error is HandshakeException) {
      return true;
    }

    final message = '${dioError.message ?? ''} ${error ?? ''}'.toLowerCase();
    return message.contains('socketexception') ||
        message.contains('failed host lookup') ||
        message.contains('network is unreachable') ||
        message.contains('connection refused') ||
        message.contains('connection reset') ||
        message.contains('no route to host');
  }

  factory ServerFailure.fromDioError(DioException dioError) {
    if (_isConnectionIssue(dioError)) {
      return ServerFailure('No Internet Connection');
    }

    switch (dioError.type) {
      case DioExceptionType.connectionTimeout:
        return ServerFailure('Connection timeout with ApiServer');

      case DioExceptionType.sendTimeout:
        return ServerFailure('Send timeout with ApiServer');

      case DioExceptionType.receiveTimeout:
        return ServerFailure('Receive timeout with ApiServer');

      case DioExceptionType.badResponse:
        return ServerFailure.fromResponse(
          dioError.response?.statusCode,
          dioError.response?.data,
        );

      case DioExceptionType.cancel:
        return ServerFailure('Request to ApiServer was canceld');

      case DioExceptionType.unknown:
        return ServerFailure('Unexpected Error, Please try again!');

      default:
        return ServerFailure('Opps There was an Error, Please try again');
    }
  }

  factory ServerFailure.fromResponse(int? statusCode, dynamic response) {
    final apiMessage = extractApiMessage(response, fallback: '');
    if (apiMessage.isNotEmpty) {
      return ServerFailure(apiMessage);
    }

    if (statusCode == 401) {
      return ServerFailure('Unauthorized, Please login again');
    } else if (statusCode == 404) {
      return ServerFailure('Your request not found, Please try later!');
    } else if (statusCode == 500) {
      return ServerFailure('Internal Server error, Please try later');
    } else {
      return ServerFailure('Opps There was an Error, Please try again');
    }
  }
}
