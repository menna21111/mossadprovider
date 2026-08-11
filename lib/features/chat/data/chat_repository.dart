import 'package:dio/dio.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/network/dio_helper.dart';
import '../../../core/network/failure.dart';
import 'models/chat_message.dart';

class ChatRepository {
  String _extractError(dynamic data) => ServerFailure.extractApiMessage(data);

  Future<ChatMessagesPage> getMessages({
    required String requestId,
    int limit = 30,
    int offset = 0,
  }) async {
    try {
      final response = await DioHelper.getData(
        url: AppConstants.providerCustomRequestChat(requestId),
        query: {'limit': limit, 'offset': offset},
      );
      final data = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};
      return ChatMessagesPage.fromJson(data);
    } on DioException catch (e) {
      throw ServerFailure.fromDioError(e);
    }
  }

  Future<ChatMessage> sendMessage({
    required String requestId,
    required String message,
  }) async {
    try {
      final response = await DioHelper.postData(
        url: AppConstants.providerCustomRequestChat(requestId),
        data: {'message': message},
      );
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw ServerFailure(_extractError(response.data));
      }
      final data = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};
      return ChatMessage.fromJson(data);
    } on DioException catch (e) {
      throw ServerFailure.fromDioError(e);
    }
  }

  Future<void> markMessagesAsRead(String requestId) async {
    try {
      await DioHelper.postData(
        url: AppConstants.providerCustomRequestChatRead(requestId),
        data: const {},
      );
    } on DioException catch (e) {
      throw ServerFailure.fromDioError(e);
    }
  }
}
