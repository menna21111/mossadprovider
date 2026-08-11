// مؤقتًا معطّل لحد تفعيل cloudinary upload preset — الكود محفوظ للاستخدام لاحقًا
import 'dart:io';

import 'package:dio/dio.dart';

import '../constants/app_constants.dart';
import '../network/failure.dart';

/// رفع الصور على Cloudinary — جاهز للتفعيل لما يتوفر upload preset صحيح
class CloudinaryUploadService {
  Future<String> uploadImage(File file) async {
    try {
      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 60),
        ),
      );

      final formData = FormData.fromMap({
        'upload_preset': AppConstants.cloudinaryUploadPreset,
        'folder': AppConstants.cloudinaryCustomRequestsFolder,
        'file': await MultipartFile.fromFile(
          file.path,
          filename: file.path.split('/').last,
        ),
      });

      final response = await dio.post<Map<String, dynamic>>(
        AppConstants.cloudinaryImageUploadUrl,
        data: formData,
      );

      final data = response.data;
      final secureUrl = data?['secure_url']?.toString();
      if (response.statusCode == 200 && secureUrl != null && secureUrl.isNotEmpty) {
        return secureUrl;
      }

      throw ServerFailure(
        data?['error']?['message']?.toString() ?? 'تعذّر رفع الصورة',
      );
    } on DioException catch (e) {
      String? message;
      final responseData = e.response?.data;
      if (responseData is Map<String, dynamic>) {
        final error = responseData['error'];
        if (error is Map<String, dynamic>) {
          message = error['message']?.toString();
        }
      }
      throw ServerFailure(message ?? 'تعذّر رفع الصورة');
    }
  }
}
