import 'package:dio/dio.dart';

import '../../../core/caching/cach_helper.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/network/dio_helper.dart';
import '../../../core/network/failure.dart';
import 'models/address_models.dart';
import 'models/existed_service.dart';
import '../../orders/data/booking_model.dart';

class ServicesRepository {
  String _extractError(dynamic data) => ServerFailure.extractApiMessage(data);

  List<dynamic> _parseList(dynamic data) {
    if (data is List) return data;
    if (data is Map<String, dynamic>) {
      for (final key in ['results', 'data', 'items']) {
        if (data[key] is List) return data[key] as List;
      }
    }
    return [];
  }

  Future<List<ExistedService>> getExistedServices() async {
    try {
      final response = await DioHelper.getData(url: AppConstants.existedServices);
      return _parseList(response.data)
          .whereType<Map<String, dynamic>>()
          .map(ExistedService.fromJson)
          .where((s) => s.isActive && s.id.isNotEmpty)
          .toList();
    } on DioException catch (e) {
      throw ServerFailure.fromDioError(e);
    }
  }

  Future<ExistedServiceDetail> getServiceDetail(String serviceId) async {
    try {
      final response = await DioHelper.getData(
        url: AppConstants.existedServiceDetail(serviceId),
      );
      final data = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};
      return ExistedServiceDetail.fromJson(data);
    } on DioException catch (e) {
      throw ServerFailure.fromDioError(e);
    }
  }

  Future<List<ServiceProvider>> getServiceProviders(String serviceId) async {
    try {
      final response = await DioHelper.getData(
        url: AppConstants.serviceProviders(serviceId),
      );
      return _parseList(response.data)
          .whereType<Map<String, dynamic>>()
          .map(ServiceProvider.fromJson)
          .where((p) => p.isAvailable)
          .toList();
    } on DioException catch (e) {
      throw ServerFailure.fromDioError(e);
    }
  }

  Future<List<ServicePreviousWork>> getServicePreviousWorks(
    String serviceId,
  ) async {
    try {
      final response = await DioHelper.getData(
        url: AppConstants.servicePreviousWorks(serviceId),
      );
      return _parseList(response.data)
          .whereType<Map<String, dynamic>>()
          .map(ServicePreviousWork.fromJson)
          .where((w) => w.beforeImage.isNotEmpty || w.afterImage.isNotEmpty)
          .toList();
    } on DioException catch (e) {
      throw ServerFailure.fromDioError(e);
    }
  }

  Future<CouponValidationResult> validateCoupon({
    required String code,
    required String serviceId,
    required num totalCost,
  }) async {
    try {
      final response = await DioHelper.postData(
        url: AppConstants.validateCoupon,
        data: {
          'code': code,
          'service_id': serviceId,
          'total_cost': totalCost,
        },
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw ServerFailure(_extractError(response.data));
      }

      final data = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};

      final result = CouponValidationResult.fromJson(data);
      if (!result.isValid) {
        throw ServerFailure(
          result.message ?? 'كود الخصم غير صالح',
        );
      }
      return result;
    } on DioException catch (e) {
      throw ServerFailure.fromDioError(e);
    }
  }

  Future<Map<String, dynamic>> createBooking(CreateBookingPayload payload) async {
    try {
      final response = await DioHelper.postData(
        url: AppConstants.providerBookings,
        data: payload.toJson(),
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

  Future<List<Booking>> getBookings() async {
    try {
      final response = await DioHelper.getData(url: AppConstants.providerBookings);
      return _parseList(response.data)
          .whereType<Map<String, dynamic>>()
          .map(Booking.fromJson)
          .where((b) => b.id.isNotEmpty)
          .toList();
    } on DioException catch (e) {
      throw ServerFailure.fromDioError(e);
    }
  }

  Future<Booking> getBookingDetail(String bookingId) async {
    try {
      final response = await DioHelper.getData(
        url: AppConstants.providerBookingDetail(bookingId),
      );
      final data = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};
      return Booking.fromJson(data);
    } on DioException catch (e) {
      throw ServerFailure.fromDioError(e);
    }
  }

  Future<List<CustomerAddress>> getAddresses() async {
    try {
      final response = await DioHelper.getData(
        url: AppConstants.providerAddresses,
      );
      return _parseList(response.data)
          .whereType<Map<String, dynamic>>()
          .map(CustomerAddress.fromJson)
          .toList();
    } on DioException catch (e) {
      throw ServerFailure.fromDioError(e);
    }
  }

  Future<CustomerAddress> createAddress(CreateAddressPayload payload) async {
    try {
      final response = await DioHelper.postData(
        url: AppConstants.providerAddresses,
        data: payload.toJson(),
      );
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw ServerFailure(_extractError(response.data));
      }
      final address = CustomerAddress.fromJson(
        response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : {},
      );
      if (payload.isDefault) {
        await CacheHelper().saveData(
          key: AppConstants.defaultAddressIdKey,
          value: address.id,
        );
        await CacheHelper().saveData(
          key: AppConstants.locationSetupDoneKey,
          value: true,
        );
      }
      return address;
    } on DioException catch (e) {
      throw ServerFailure.fromDioError(e);
    }
  }

  Future<CustomerAddress> updateAddress(
    String addressId,
    CreateAddressPayload payload,
  ) async {
    try {
      final response = await DioHelper.patchData(
        url: AppConstants.deleteAddress(addressId),
        data: payload.toJson(),
      );
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw ServerFailure(_extractError(response.data));
      }
      final map = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};
      final address = map.isEmpty
          ? CustomerAddress(
              id: addressId,
              city: payload.city,
              cityName: '',
              region: payload.region,
              regionName: '',
              district: payload.district,
              street: payload.street,
              buildingNo: payload.buildingNo,
              lat: payload.lat.toString(),
              lng: payload.lng.toString(),
              apartmentNo: payload.apartmentNo,
              label: payload.label,
              isDefault: payload.isDefault,
            )
          : CustomerAddress.fromJson(map);
      if (payload.isDefault) {
        await CacheHelper().saveData(
          key: AppConstants.defaultAddressIdKey,
          value: address.id,
        );
      }
      return address;
    } on DioException catch (e) {
      throw ServerFailure.fromDioError(e);
    }
  }

  Future<void> deleteAddress(String addressId) async {
    try {
      await DioHelper.deleteData(
        url: AppConstants.deleteAddress(addressId),
      );
      final cached = CacheHelper().getDataString(
        key: AppConstants.defaultAddressIdKey,
      );
      if (cached == addressId) {
        await CacheHelper().removeData(key: AppConstants.defaultAddressIdKey);
      }
    } on DioException catch (e) {
      throw ServerFailure.fromDioError(e);
    }
  }

  Future<List<CityModel>> getCities() async {
    try {
      final response = await DioHelper.getData(url: AppConstants.cities);
      return _parseList(response.data)
          .whereType<Map<String, dynamic>>()
          .map(CityModel.fromJson)
          .where((c) => c.isActive)
          .toList();
    } on DioException catch (e) {
      throw ServerFailure.fromDioError(e);
    }
  }

  Future<List<RegionModel>> getRegions(String cityId) async {
    try {
      final response = await DioHelper.getData(
        url: AppConstants.regions,
        query: {'city_id': cityId},
      );
      return _parseList(response.data)
          .whereType<Map<String, dynamic>>()
          .map(RegionModel.fromJson)
          .where((r) => r.isActive)
          .toList();
    } on DioException catch (e) {
      throw ServerFailure.fromDioError(e);
    }
  }

  Future<bool> hasSavedAddress() async {
    final addresses = await getAddresses();
    return addresses.isNotEmpty;
  }

  String? get cachedDefaultAddressId =>
      CacheHelper().getDataString(key: AppConstants.defaultAddressIdKey);
}
