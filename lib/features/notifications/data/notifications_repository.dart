import 'package:dio/dio.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/network/dio_helper.dart';
import '../../../core/network/failure.dart';
import 'models/app_notification.dart';

class NotificationsRepository {
  String _extractError(dynamic data) => ServerFailure.extractApiMessage(data);

  Future<int> getUnreadCount() async {
    try {
      final response = await DioHelper.getData(
        url: AppConstants.notificationsUnreadCount,
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return int.tryParse(
              data['unread_count']?.toString() ??
                  data['count']?.toString() ??
                  '0',
            ) ??
            0;
      }
      return int.tryParse(data?.toString() ?? '') ?? 0;
    } on DioException catch (e) {
      throw ServerFailure.fromDioError(e);
    }
  }

  Future<NotificationsPage> getNotifications({
    bool? isRead,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await DioHelper.getData(
        url: AppConstants.notifications,
        query: {
          if (isRead != null) 'is_read': isRead,
          'limit': limit,
          'offset': offset,
        },
      );
      final data = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};
      return NotificationsPage.fromJson(data);
    } on DioException catch (e) {
      throw ServerFailure.fromDioError(e);
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await DioHelper.patchData(
        url: AppConstants.notificationRead(notificationId),
        data: const {},
      );
    } on DioException catch (e) {
      throw ServerFailure.fromDioError(e);
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await DioHelper.postData(
        url: AppConstants.notificationsMarkAllRead,
        data: const {},
      );
    } on DioException catch (e) {
      throw ServerFailure.fromDioError(e);
    }
  }

  Future<void> registerDeviceToken(String token) async {
    try {
      final response = await DioHelper.postData(
        url: AppConstants.deviceTokens,
        data: {'token': token},
      );
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw ServerFailure(_extractError(response.data));
      }
    } on DioException catch (e) {
      throw ServerFailure.fromDioError(e);
    }
  }

  Future<void> deleteDeviceToken(String token) async {
    try {
      await DioHelper.deleteData(
        url: AppConstants.deviceTokens,
        data: {'token': token},
      );
    } on DioException catch (e) {
      throw ServerFailure.fromDioError(e);
    }
  }
}
