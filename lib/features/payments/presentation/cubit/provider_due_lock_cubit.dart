import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/provider_dues_repository.dart';
import '../../data/provider_dues_status_model.dart';

part 'provider_due_lock_state.dart';

class ProviderDueLockCubit extends Cubit<ProviderDueLockState> {
  ProviderDueLockCubit(this._duesRepository) : super(const ProviderDueLockState());

  final ProviderDuesRepository _duesRepository;

  Future<void> fetchStatus() async {
    emit(state.copyWith(loading: true, errorMessage: null));
    try {
      final status = await _duesRepository.getStatus();
      applyStatus(status);
    } catch (e) {
      // Keep previous values if fetch fails; just expose error.
      emit(state.copyWith(loading: false, errorMessage: e.toString()));
    }
  }

  void applyStatus(ProviderDuesStatus status) {
    emit(
      state.copyWith(
        loading: false,
        errorMessage: null,
        isBlocked: status.isBlocked,
        outstandingAmount: status.outstandingAmount,
        blockedAt: status.blockedAt,
        currentPaymentLink: status.currentPaymentLink,
      ),
    );
  }

  void handleDuePaymentRequired(Map<String, dynamic> payload) {
    // Requirement: always call GET /provider/dues/status/ after event.
    fetchStatus();
  }

  void handleAccountUnblocked() {
    // Requirement: always call GET /provider/dues/status/ after event.
    fetchStatus();
  }
}
