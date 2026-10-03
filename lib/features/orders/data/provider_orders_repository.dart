import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:dio/dio.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/network/dio_helper.dart';
import '../../../core/network/failure.dart';
import 'booking_model.dart';
import 'completion_form_model.dart';
import 'dynamic_json_model.dart';
import 'provider_custom_request_model.dart';
import 'provider_offer_model.dart';

class ProviderOrdersRepository {
  String _extractError(dynamic data) => ServerFailure.extractApiMessage(data);

  Future<Booking> getProviderBookingDetail(String bookingId) async {
    try {
      final response = await DioHelper.getData(
        url: AppConstants.providerBookingDetail(bookingId),
      );

      log(
        '[ProviderOrders] booking detail:\n${jsonEncode(response.data)}',
        name: 'ProviderOrdersRepository',
      );

      final data = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};
      return Booking.fromJson(data);
    } on DioException catch (e) {
      throw ServerFailure.fromDioError(e);
    }
  }

  Future<List<Booking>> getProviderBookings() async {
    try {
      final response = await DioHelper.getData(
        url: AppConstants.providerBookings,
      );

      log(
        '[ProviderOrders] bookings list:\n${jsonEncode(response.data)}',
        name: 'ProviderOrdersRepository',
      );

      final rawItems =
          response.data is List ? response.data : DynamicJsonModel.parseList(response.data);
      final bookings = <Booking>[];
      for (final item in rawItems) {
        Map<String, dynamic>? map;
        if (item is Map<String, dynamic>) {
          map = item;
        } else if (item is Map) {
          map = item.map((k, v) => MapEntry(k.toString(), v));
        }
        if (map == null) continue;
        final booking = Booking.fromJson(map);
        if (booking.id.isNotEmpty) bookings.add(booking);
      }
      return bookings;
    } on DioException catch (e) {
      throw ServerFailure.fromDioError(e);
    }
  }

  Future<List<CompletionForm>> getCompletionForms({
    String? status,
    String? dateFrom,
    String? dateTo,
  }) async {
    try {
      final response = await DioHelper.getData(
        url: AppConstants.providerCompletionForms,
        query: _completionFormsQuery(
          status: status,
          dateFrom: dateFrom,
          dateTo: dateTo,
        ),
      );

      log(
        '[ProviderOrders] completion-forms (bookings) response:\n${jsonEncode(response.data)}',
        name: 'ProviderOrdersRepository',
      );

      final forms = _parseCompletionForms(
        response.data,
        kind: CompletionFormKind.booking,
      );
      return _withExistedServiceImages(forms);
    } on DioException catch (e) {
      throw ServerFailure.fromDioError(e);
    }
  }

  Future<List<CompletionForm>> getCustomCompletionForms({
    String? status,
    String? dateFrom,
    String? dateTo,
  }) async {
    try {
      final response = await DioHelper.getData(
        url: AppConstants.providerCustomCompletionForms,
        query: _completionFormsQuery(
          status: status,
          dateFrom: dateFrom,
          dateTo: dateTo,
        ),
      );

      log(
        '[ProviderOrders] custom-requests completion-forms response:\n${jsonEncode(response.data)}',
        name: 'ProviderOrdersRepository',
      );

      return _parseCompletionForms(
        response.data,
        kind: CompletionFormKind.customRequest,
      );
    } on DioException catch (e) {
      throw ServerFailure.fromDioError(e);
    }
  }

  Map<String, dynamic>? _completionFormsQuery({
    String? status,
    String? dateFrom,
    String? dateTo,
  }) {
    final query = <String, dynamic>{};
    final trimmedStatus = status?.trim();
    if (trimmedStatus != null && trimmedStatus.isNotEmpty) {
      query['status'] = trimmedStatus;
    }
    final from = dateFrom?.trim();
    if (from != null && from.isNotEmpty) {
      query['date_from'] = from;
    }
    final to = dateTo?.trim();
    if (to != null && to.isNotEmpty) {
      query['date_to'] = to;
    }
    return query.isEmpty ? null : query;
  }

  List<CompletionForm> _parseCompletionForms(
    dynamic data, {
    required CompletionFormKind kind,
  }) {
    final rawItems = data is List ? data : DynamicJsonModel.parseList(data);
    final maps = <Map<String, dynamic>>[];
    for (final item in rawItems) {
      if (item is Map<String, dynamic>) {
        maps.add(item);
      } else if (item is Map) {
        maps.add(item.map((k, v) => MapEntry(k.toString(), v)));
      }
    }

    return maps
        .map((json) => CompletionForm.fromJson(json, kind: kind))
        .where((form) => form.id.isNotEmpty || form.bookingId.isNotEmpty)
        .toList();
  }

  Future<List<CompletionForm>> _withExistedServiceImages(
    List<CompletionForm> forms,
  ) async {
    final needsImage = forms.any((form) {
      if (form.isCustomRequest) return false;
      return (form.cardImage ?? '').trim().isEmpty;
    });
    if (!needsImage) return forms;

    final imagesByTitle = await _existedServiceImagesByTitle();
    if (imagesByTitle.isEmpty) return forms;

    return forms.map((form) {
      if (form.isCustomRequest) return form;
      if ((form.cardImage ?? '').trim().isNotEmpty) return form;
      final image = _imageForServiceTitle(form.serviceTitle, imagesByTitle);
      if (image == null) return form;
      return form.copyWith(serviceImage: image);
    }).toList();
  }

  Future<Map<String, String>> _existedServiceImagesByTitle() async {
    final byTitle = <String, String>{};
    try {
      final response = await DioHelper.getData(
        url: AppConstants.existedServices,
      );
      final raw = response.data is List
          ? response.data
          : DynamicJsonModel.parseList(response.data);
      for (final item in raw) {
        Map<String, dynamic>? map;
        if (item is Map<String, dynamic>) {
          map = item;
        } else if (item is Map) {
          map = item.map((key, value) => MapEntry(key.toString(), value));
        }
        if (map == null) continue;
        final title = (map['title'] ?? map['name'] ?? '').toString().trim();
        final image = (map['image'] ?? map['cover'] ?? map['photo'])
            ?.toString()
            .trim();
        if (title.isEmpty ||
            image == null ||
            image.isEmpty ||
            image.toLowerCase() == 'null') {
          continue;
        }
        byTitle[title] = image;
      }
    } catch (_) {}

    if (byTitle.isNotEmpty) return byTitle;

    try {
      final bookings = await getProviderBookings();
      for (final booking in bookings) {
        final title = booking.serviceTitle.trim();
        final image = booking.serviceImage?.trim();
        if (title.isEmpty || image == null || image.isEmpty) continue;
        byTitle[title] = image;
      }
    } catch (_) {}

    return byTitle;
  }

  String? _imageForServiceTitle(
    String? title,
    Map<String, String> imagesByTitle,
  ) {
    final key = (title ?? '').trim();
    if (key.isEmpty) return null;
    final exact = imagesByTitle[key];
    if (exact != null && exact.isNotEmpty) return exact;
    for (final entry in imagesByTitle.entries) {
      if (entry.key.contains(key) || key.contains(entry.key)) {
        return entry.value;
      }
    }
    return null;
  }

  Future<CompletionForm> getCompletionFormDetail(
    String workId, {
    CompletionFormKind kind = CompletionFormKind.booking,
  }) async {
    try {
      final url = kind == CompletionFormKind.customRequest
          ? AppConstants.providerCustomCompletionFormDetail(workId)
          : AppConstants.providerCompletionFormDetail(workId);

      final response = await DioHelper.getData(url: url);

      log(
        '[ProviderOrders] completion-form detail ($kind):\n${jsonEncode(response.data)}',
        name: 'ProviderOrdersRepository',
      );

      final data = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};
      if (data.isNotEmpty) {
        var form = CompletionForm.fromJson(
          data,
          kind: kind,
          preferredWorkId: workId,
        );
        if (!form.isCustomRequest && (form.cardImage ?? '').trim().isEmpty) {
          final images = await _existedServiceImagesByTitle();
          final image = _imageForServiceTitle(form.serviceTitle, images);
          if (image != null) form = form.copyWith(serviceImage: image);
        }
        return form;
      }

      if (kind == CompletionFormKind.customRequest) {
        return _findCustomCompletionFormInList(workId);
      }
      throw ServerFailure('Empty completion form detail');
    } on DioException catch (e) {
      if (kind == CompletionFormKind.customRequest) {
        try {
          return await _findCustomCompletionFormInList(workId);
        } catch (_) {
          throw ServerFailure.fromDioError(e);
        }
      }
      throw ServerFailure.fromDioError(e);
    }
  }

  Future<CompletionForm> _findCustomCompletionFormInList(String requestId) async {
    final list = await getCustomCompletionForms();
    for (final form in list) {
      if (form.workId == requestId || form.id == requestId) {
        return form;
      }
    }
    throw ServerFailure('Custom completion form not found');
  }

  /// POST — رفع صورة قبل فقط
  Future<PreviousWork> uploadPreviousWork({
    required String bookingId,
    required File beforeImageFile,
    CompletionFormKind kind = CompletionFormKind.booking,
  }) async {
    try {
      final formData = FormData.fromMap({
        'before_image': await MultipartFile.fromFile(
          beforeImageFile.path,
          filename: beforeImageFile.path.split('/').last,
        ),
      });

      final url = kind == CompletionFormKind.customRequest
          ? AppConstants.customRequestPreviousWork(bookingId)
          : AppConstants.bookingPreviousWork(bookingId);

      final response = await DioHelper.postMultipart(
        url: url,
        data: formData,
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw ServerFailure(_extractError(response.data));
      }

      final responseData = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};
      return PreviousWork.fromJson(responseData);
    } on DioException catch (e) {
      throw ServerFailure.fromDioError(e);
    }
  }

  /// PATCH — رفع صورة بعد فقط
  Future<PreviousWork> updatePreviousWorkAfter({
    required String bookingId,
    required File afterImageFile,
    CompletionFormKind kind = CompletionFormKind.booking,
  }) async {
    try {
      final formData = FormData.fromMap({
        'after_image': await MultipartFile.fromFile(
          afterImageFile.path,
          filename: afterImageFile.path.split('/').last,
        ),
      });

      final url = kind == CompletionFormKind.customRequest
          ? AppConstants.customRequestPreviousWork(bookingId)
          : AppConstants.bookingPreviousWork(bookingId);

      final response = await DioHelper.patchMultipart(
        url: url,
        data: formData,
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw ServerFailure(_extractError(response.data));
      }

      final responseData = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};
      return PreviousWork.fromJson(responseData);
    } on DioException catch (e) {
      throw ServerFailure.fromDioError(e);
    }
  }

  Future<CompletionForm> submitCompletionForm({
    required String bookingId,
    required String notes,
    bool isFinished = true,
    CompletionFormKind kind = CompletionFormKind.booking,
  }) async {
    try {
      if (kind == CompletionFormKind.customRequest) {
        return _submitCustomCompletionForm(
          requestId: bookingId,
          notes: notes,
          isFinished: isFinished,
        );
      }

      final response = await DioHelper.patchData(
        url: AppConstants.providerCompletionFormDetail(bookingId),
        data: {
          'notes': notes,
          'is_finished': isFinished,
        },
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw ServerFailure(_extractError(response.data));
      }

      final data = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};
      if (data.isNotEmpty) {
        return CompletionForm.fromJson(data, kind: kind);
      }

      return getCompletionFormDetail(bookingId, kind: kind);
    } on DioException catch (e) {
      throw ServerFailure.fromDioError(e);
    }
  }

  Future<CompletionForm> _submitCustomCompletionForm({
    required String requestId,
    required String notes,
    required bool isFinished,
  }) async {
    try {
      final patchResponse = await DioHelper.patchData(
        url: AppConstants.providerCustomCompletionFormDetail(requestId),
        data: {
          'notes': notes,
          'is_finished': isFinished,
        },
      );

      if (patchResponse.statusCode == 200 || patchResponse.statusCode == 201) {
        final data = patchResponse.data is Map<String, dynamic>
            ? patchResponse.data as Map<String, dynamic>
            : <String, dynamic>{};
        if (data.isNotEmpty) {
          return CompletionForm.fromJson(
            data,
            kind: CompletionFormKind.customRequest,
          );
        }
        return getCompletionFormDetail(
          requestId,
          kind: CompletionFormKind.customRequest,
        );
      }
    } on DioException {
      // fall through to POST completion/
    }

    await completeCustomRequest(requestId);
    try {
      return await getCompletionFormDetail(
        requestId,
        kind: CompletionFormKind.customRequest,
      );
    } catch (_) {
      return CompletionForm(
        id: requestId,
        bookingId: requestId,
        kind: CompletionFormKind.customRequest,
        isFinished: true,
        notes: notes,
        media: const [],
      );
    }
  }

  Future<List<ProviderCustomRequest>> getProviderCustomRequests({
    double? lat,
    double? lng,
  }) async {
    try {
      final query = <String, dynamic>{};
      if (lat != null) query['lat'] = lat;
      if (lng != null) query['lng'] = lng;

      final response = await DioHelper.getData(
        url: AppConstants.providerCustomRequests,
        query: query.isEmpty ? null : query,
      );

      log(
        '[ProviderOrders] custom-requests list:\n${jsonEncode(response.data)}',
        name: 'ProviderOrdersRepository',
      );

      return DynamicJsonModel.parseList(response.data)
          .map(ProviderCustomRequest.fromJson)
          .where((request) => request.id.isNotEmpty)
          .toList();
    } on DioException catch (e) {
      throw ServerFailure.fromDioError(e);
    }
  }

  Future<ProviderCustomRequest> getProviderCustomRequestDetail(
    String requestId,
  ) async {
    try {
      final response = await DioHelper.getData(
        url: AppConstants.providerCustomRequestDetail(requestId),
      );

      log(
        '[ProviderOrders] custom-request detail:\n${jsonEncode(response.data)}',
        name: 'ProviderOrdersRepository',
      );

      final data = response.data is Map
          ? Map<String, dynamic>.from(response.data as Map)
          : <String, dynamic>{};
      return ProviderCustomRequest.fromJson(data);
    } on DioException catch (e) {
      throw ServerFailure.fromDioError(e);
    }
  }

  Future<ProviderOffer> submitOffer({
    required String requestId,
    required SubmitOfferPayload payload,
  }) async {
    try {
      final response = await DioHelper.postData(
        url: AppConstants.providerCustomRequestOffers(requestId),
        data: payload.toJson(),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw ServerFailure(_extractError(response.data));
      }

      log(
        '[ProviderOrders] submit offer response:\n${jsonEncode(response.data)}',
        name: 'ProviderOrdersRepository',
      );

      final data = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};
      return ProviderOffer.fromJson(data);
    } on DioException catch (e) {
      throw ServerFailure.fromDioError(e);
    }
  }

  Future<Map<String, dynamic>> completeCustomRequest(String requestId) async {
    try {
      final response = await DioHelper.postData(
        url: AppConstants.providerCustomRequestCompletion(requestId),
        data: const {},
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw ServerFailure(_extractError(response.data));
      }

      return response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : {};
    } on DioException catch (e) {
      throw ServerFailure.fromDioError(e);
    }
  }

  Future<List<ProviderOffer>> getProviderOffers({String? status}) async {
    try {
      final trimmed = status?.trim();
      final response = await DioHelper.getData(
        url: AppConstants.providerOffers,
        query: (trimmed != null && trimmed.isNotEmpty)
            ? {'status': trimmed}
            : null,
      );

      log(
        '[ProviderOrders] my offers list:\n${jsonEncode(response.data)}',
        name: 'ProviderOrdersRepository',
      );

      return DynamicJsonModel.parseList(response.data)
          .map(ProviderOffer.fromJson)
          .where((offer) => offer.id.isNotEmpty)
          .toList();
    } on DioException catch (e) {
      throw ServerFailure.fromDioError(e);
    }
  }

  Future<ProviderOfferDetail> getProviderOfferDetail(String offerId) async {
    try {
      final response = await DioHelper.getData(
        url: AppConstants.providerOfferDetail(offerId),
      );

      log(
        '[ProviderOrders] offer detail:\n${jsonEncode(response.data)}',
        name: 'ProviderOrdersRepository',
      );

      final data = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};
      return ProviderOfferDetail.fromJson(data);
    } on DioException catch (e) {
      throw ServerFailure.fromDioError(e);
    }
  }

  Future<ProviderOfferDetail> updateProviderOffer({
    required String offerId,
    required SubmitOfferPayload payload,
  }) async {
    try {
      final response = await DioHelper.putData(
        url: AppConstants.providerOfferDetail(offerId),
        data: payload.toJson(),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw ServerFailure(_extractError(response.data));
      }

      final data = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};
      return ProviderOfferDetail.fromJson(data);
    } on DioException catch (e) {
      throw ServerFailure.fromDioError(e);
    }
  }

  Future<void> confirmCashPayment(String paymentRequestId) async {
    try {
      final response = await DioHelper.postData(
        url: AppConstants.paymentConfirmCash(paymentRequestId),
        data: const {},
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw ServerFailure(_extractError(response.data));
      }
    } on DioException catch (e) {
      throw ServerFailure.fromDioError(e);
    }
  }

  /// Fetches payment request linked to a booking or custom request.
  /// Returns `{id, status, ...}` or null if not found.
  Future<Map<String, String>?> getLinkedPayment({
    required String workId,
    required CompletionFormKind kind,
  }) async {
    try {
      final url = kind == CompletionFormKind.customRequest
          ? AppConstants.paymentByCustomRequest(workId)
          : AppConstants.paymentByBooking(workId);
      final response = await DioHelper.getData(url: url);
      final data = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};
      if (data.isEmpty) return null;

      final id = data['id']?.toString() ??
          data['payment_request_id']?.toString() ??
          '';
      final status = data['status']?.toString() ??
          data['payment_status']?.toString() ??
          '';
      if (id.isEmpty && status.isEmpty) return null;
      return {
        if (id.isNotEmpty) 'id': id,
        if (status.isNotEmpty) 'status': status,
      };
    } on DioException {
      return null;
    } catch (_) {
      return null;
    }
  }
}
