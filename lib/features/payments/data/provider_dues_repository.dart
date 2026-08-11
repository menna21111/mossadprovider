import 'dart:convert';
import 'dart:developer';

import 'package:dio/dio.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/network/dio_helper.dart';
import '../../../core/network/failure.dart';
import 'provider_dues_response_model.dart';
import 'provider_dues_status_model.dart';

class ProviderDuesRepository {
  Future<ProviderDuesStatus> getStatus() async {
    try {
      final response = await DioHelper.getData(
        url: AppConstants.providerDuesStatus,
      );

      log(
        '[ProviderDuesRepository] dues status response:\n${jsonEncode(response.data)}',
        name: 'ProviderDuesRepository',
      );

      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw ServerFailure('Invalid dues status response');
      }

      return ProviderDuesStatus.fromJson(data);
    } on DioException catch (e) {
      // Fallback to /dues/ which also returns the due status object.
      try {
        final dues = await getDues();
        return dues.due;
      } catch (_) {
        throw ServerFailure.fromDioError(e);
      }
    }
  }

  Future<ProviderDuesResponse> getDues() async {
    try {
      final response = await DioHelper.getData(
        url: AppConstants.providerDues,
      );

      log(
        '[ProviderDuesRepository] dues list response:\n${jsonEncode(response.data)}',
        name: 'ProviderDuesRepository',
      );

      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw ServerFailure('Invalid dues response');
      }

      return ProviderDuesResponse.fromJson(data);
    } on DioException catch (e) {
      throw ServerFailure.fromDioError(e);
    }
  }
}
