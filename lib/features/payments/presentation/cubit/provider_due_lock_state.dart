part of 'provider_due_lock_cubit.dart';

class ProviderDueLockState extends Equatable {
  const ProviderDueLockState({
    this.loading = false,
    this.errorMessage,
    this.isBlocked = false,
    this.outstandingAmount = '',
    this.blockedAt = '',
    this.currentPaymentLink = '',
  });

  final bool loading;
  final String? errorMessage;
  final bool isBlocked;
  final String outstandingAmount;
  final String blockedAt;
  final String currentPaymentLink;

  ProviderDueLockState copyWith({
    bool? loading,
    String? errorMessage,
    bool? isBlocked,
    String? outstandingAmount,
    String? blockedAt,
    String? currentPaymentLink,
  }) {
    return ProviderDueLockState(
      loading: loading ?? this.loading,
      errorMessage: errorMessage,
      isBlocked: isBlocked ?? this.isBlocked,
      outstandingAmount: outstandingAmount ?? this.outstandingAmount,
      blockedAt: blockedAt ?? this.blockedAt,
      currentPaymentLink: currentPaymentLink ?? this.currentPaymentLink,
    );
  }

  @override
  List<Object?> get props => [
        loading,
        errorMessage,
        isBlocked,
        outstandingAmount,
        blockedAt,
        currentPaymentLink,
      ];
}

