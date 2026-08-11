import 'dart:convert';
import 'dart:developer';

import 'package:dio/dio.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/network/dio_helper.dart';
import '../../../core/network/failure.dart';
import 'provider_wallet_model.dart';

class ProviderWalletRepository {
  Future<ProviderWallet> getWallet() async {
    try {
      final response = await DioHelper.getData(
        url: AppConstants.providerWallet,
      );

      log(
        '[ProviderWalletRepository] wallet response:\n${jsonEncode(response.data)}',
        name: 'ProviderWalletRepository',
      );

      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw ServerFailure('Invalid wallet response');
      }
      return ProviderWallet.fromJson(data);
    } on DioException catch (e) {
      throw ServerFailure.fromDioError(e);
    }
  }
}

