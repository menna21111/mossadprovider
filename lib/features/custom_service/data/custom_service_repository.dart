import 'package:dio/dio.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/network/dio_helper.dart';
import '../../../core/network/failure.dart';
import 'models/custom_service_models.dart';

class CustomServiceRepository {
  List<dynamic> _parseList(dynamic data) {
    if (data is List) return data;
    if (data is Map<String, dynamic>) {
      for (final key in ['results', 'data', 'items']) {
        if (data[key] is List) return data[key] as List;
      }
    }
    return [];
  }

  Future<List<Specialization>> getSpecializations() async {
    try {
      final response = await DioHelper.getData(
        url: AppConstants.specializations,
        isWithoutToken: true,
      );
      return _parseList(response.data)
          .whereType<Map<String, dynamic>>()
          .map(Specialization.fromJson)
          .where((s) => s.id.isNotEmpty && s.name.isNotEmpty)
          .toList();
    } on DioException catch (e) {
      throw ServerFailure.fromDioError(e);
    }
  }

  Future<CustomRequest> createCustomRequest(CustomRequestPayload payload) async {
    try {
      final response = await DioHelper.postData(
        url: AppConstants.providerCustomRequests,
        data: payload.toJson(),
      );
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw ServerFailure(
          ServerFailure.extractApiMessage(response.data),
        );
      }
      final data = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};
      return CustomRequest.fromJson(data);
    } on DioException catch (e) {
      throw ServerFailure.fromDioError(e);
    }
  }

  Future<List<CustomRequest>> getPublishedCustomRequests() async {
    try {
      final response = await DioHelper.getData(
        url: AppConstants.providerCustomRequests,
        query: {'status': 'published'},
      );
      return _parseList(response.data)
          .whereType<Map<String, dynamic>>()
          .map(CustomRequest.fromJson)
          .where((r) => r.id.isNotEmpty)
          .toList();
    } on DioException catch (e) {
      throw ServerFailure.fromDioError(e);
    }
  }

  Future<CustomRequest> getCustomRequestDetail(String requestId) async {
    try {
      final response = await DioHelper.getData(
        url: AppConstants.providerCustomRequestDetail(requestId),
      );
      final data = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};
      return CustomRequest.fromJson(data);
    } on DioException catch (e) {
      throw ServerFailure.fromDioError(e);
    }
  }
}
