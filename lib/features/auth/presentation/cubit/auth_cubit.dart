import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/failure.dart';
import '../../../../core/services/notification/push_notification_service.dart';

import '../../data/auth_repository.dart';
import '../../data/models/auth_session.dart';
import '../../data/models/customer_profile.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._repository) : super(const AuthInitial());

  final AuthRepository _repository;

  Future<void> sendOtp(String phoneNumber) async {
    emit(const AuthLoading());
    try {
      final otpCode = await _repository.sendOtp(phoneNumber);
      emit(OtpSent(phoneNumber: phoneNumber, otpCode: otpCode));
    } on ServerFailure catch (e) {
      emit(AuthFailure(e.errMessage));
    } catch (_) {
      emit(const AuthFailure('حدث خطأ غير متوقع'));
    }
  }

  Future<void> verifyOtp({
    required String phoneNumber,
    required String otpCode,
  }) async {
    emit(const AuthLoading());
    try {
      final session = await _repository.verifyOtp(
        phoneNumber: phoneNumber,
        otpCode: otpCode,
      );
      emit(AuthVerified(session: session));
    } on ServerFailure catch (e) {
      emit(AuthFailure(e.errMessage));
    } catch (_) {
      emit(const AuthFailure('حدث خطأ غير متوقع'));
    }
  }

  Future<void> register({
    required String name,
    required String phoneNumber,
  }) async {
    emit(const AuthLoading());
    try {
      await _repository.registerCustomer(
        name: name,
        phoneNumber: phoneNumber,
      );
      final otpCode = await _repository.sendOtp(phoneNumber);
      emit(OtpSent(phoneNumber: phoneNumber, otpCode: otpCode));
    } on ServerFailure catch (e) {
      emit(AuthFailure(e.errMessage));
    } catch (_) {
      emit(const AuthFailure('حدث خطأ غير متوقع'));
    }
  }

  Future<void> registerProvider({
    required String name,
    required String phoneNumber,
    required String email,
    required String specializationId,
    required String nationalId,
    required String commercialRegistration,
    required File contractImage,
  }) async {
    emit(const AuthLoading());
    try {
      await _repository.registerProvider(
        name: name,
        phoneNumber: phoneNumber,
        email: email,
        specializationId: specializationId,
        nationalId: nationalId,
        commercialRegistration: commercialRegistration,
        contractImage: contractImage,
      );
      final otpCode = await _repository.sendOtp(phoneNumber);
      emit(OtpSent(phoneNumber: phoneNumber, otpCode: otpCode));
    } on ServerFailure catch (e) {
      emit(AuthFailure(e.errMessage));
    } catch (_) {
      emit(const AuthFailure('حدث خطأ غير متوقع'));
    }
  }

  Future<void> loginWithBiometric() async {
    emit(const AuthLoading());
    try {
      final session = await _repository.loginWithBiometric();
      emit(AuthVerified(session: session));
    } on ServerFailure catch (e) {
      emit(AuthFailure(e.errMessage));
    } catch (_) {
      emit(const AuthFailure('حدث خطأ غير متوقع'));
    }
  }

  Future<void> logout() async {
    emit(const AuthLoading());
    try {
      await PushNotificationService.removeTokenFromBackend();
      await _repository.logout();
      emit(const AuthLoggedOut());
    } on ServerFailure catch (e) {
      emit(AuthFailure(e.errMessage));
    } catch (_) {
      emit(const AuthFailure('حدث خطأ غير متوقع'));
    }
  }

  Future<void> fetchProfile() async {
    emit(const ProfileLoading());
    try {
      final profile = await _repository.getProviderProfile();
      emit(ProfileLoaded(profile: profile));
    } on ServerFailure catch (e) {
      emit(ProfileFailure(e.errMessage));
    } catch (_) {
      emit(const ProfileFailure('حدث خطأ غير متوقع'));
    }
  }

  void reset() => emit(const AuthInitial());
}
