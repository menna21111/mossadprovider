import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/network/dio_helper.dart';
import '../../../core/network/failure.dart';
import 'models/chat_conversation.dart';
import 'models/chat_message.dart';

class ChatRepository {
  String _extractError(dynamic data) => ServerFailure.extractApiMessage(data);

  Future<ChatConversationsPage> getConversations({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await DioHelper.getData(
        url: AppConstants.providerCustomRequestConversations,
        query: {'limit': limit, 'offset': offset},
      );
      final data = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};
      return ChatConversationsPage.fromJson(data);
    } on DioException catch (e) {
      throw ServerFailure.fromDioError(e);
    }
  }

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

  /// Text-only send via JSON body (existing provider API).
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
      final nested = data['data'];
      final payload = nested is Map<String, dynamic> ? nested : data;
      return ChatMessage.fromJson(payload);
    } on DioException catch (e) {
      throw ServerFailure.fromDioError(e);
    }
  }

  /// Multipart send for attachments (image / voice / file).
  /// Falls back to [sendMessage] for plain text with no attachment.
  Future<ChatMessage> send({
    required String requestId,
    required String messageType,
    String? message,
    String? attachmentPath,
    String? attachmentName,
  }) async {
    final attachment = attachmentPath?.trim();
    final hasAttachment = attachment != null && attachment.isNotEmpty;
    if (!hasAttachment && messageType == ChatMessageType.text) {
      return sendMessage(
        requestId: requestId,
        message: message?.trim() ?? '',
      );
    }

    try {
      final map = <String, dynamic>{
        'message_type': messageType,
        if (message != null && message.trim().isNotEmpty)
          'message': message.trim(),
      };

      if (hasAttachment) {
        final name =
            (attachmentName != null && attachmentName.trim().isNotEmpty)
                ? attachmentName.trim()
                : attachment.split(RegExp(r'[/\\]')).last;
        map['attachment'] = await MultipartFile.fromFile(
          attachment,
          filename: name.isNotEmpty ? name : _fallbackName(messageType),
          contentType: _contentType(messageType, name),
        );
      }

      final response = await DioHelper.postMultipart(
        url: AppConstants.providerCustomRequestChat(requestId),
        data: FormData.fromMap(map),
        sendTimeout: const Duration(minutes: 2),
        receiveTimeout: const Duration(minutes: 2),
      );
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw ServerFailure(_extractError(response.data));
      }
      final data = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};
      final nested = data['data'];
      final payload = nested is Map<String, dynamic> ? nested : data;
      return ChatMessage.fromJson(payload);
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

  String _fallbackName(String type) {
    switch (type) {
      case ChatMessageType.image:
        return 'photo.jpg';
      case ChatMessageType.voice:
        return 'voice_note.m4a';
      case ChatMessageType.file:
        return 'file.bin';
      default:
        return 'attachment';
    }
  }

  MediaType? _contentType(String type, String filename) {
    final ext = filename.split('.').last.toLowerCase();
    switch (type) {
      case ChatMessageType.image:
        if (ext == 'png') return MediaType('image', 'png');
        if (ext == 'webp') return MediaType('image', 'webp');
        if (ext == 'gif') return MediaType('image', 'gif');
        return MediaType('image', 'jpeg');
      case ChatMessageType.voice:
        if (ext == 'mp3') return MediaType('audio', 'mpeg');
        if (ext == 'wav') return MediaType('audio', 'wav');
        if (ext == 'aac') return MediaType('audio', 'aac');
        return MediaType('audio', 'mp4');
      default:
        if (ext == 'pdf') return MediaType('application', 'pdf');
        return null;
    }
  }
}
