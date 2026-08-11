class ProviderRecentTransaction {
  final String id;
  final String amount;
  final String transactionType;
  final String balanceAfter;
  final String createdAt;

  const ProviderRecentTransaction({
    required this.id,
    required this.amount,
    required this.transactionType,
    required this.balanceAfter,
    required this.createdAt,
  });

  factory ProviderRecentTransaction.fromJson(Map<String, dynamic> json) {
    return ProviderRecentTransaction(
      id: json['id']?.toString() ?? '',
      amount: json['amount']?.toString() ?? '0',
      transactionType: json['transaction_type']?.toString() ?? '',
      balanceAfter: json['balance_after']?.toString() ?? '0',
      createdAt: json['created_at']?.toString() ?? '',
    );
  }
}

class ProviderWallet {
  final String availableBalance;
  final String totalEarned;
  final String totalPaidOut;
  final String updatedAt;
  final List<ProviderRecentTransaction> recentTransactions;

  const ProviderWallet({
    required this.availableBalance,
    required this.totalEarned,
    required this.totalPaidOut,
    required this.updatedAt,
    required this.recentTransactions,
  });

  factory ProviderWallet.fromJson(Map<String, dynamic> json) {
    final walletJson = json['wallet'] is Map<String, dynamic>
        ? (json['wallet'] as Map<String, dynamic>)
        : json;

    final txJson = json['recent_transactions'];

    return ProviderWallet(
      availableBalance: walletJson['available_balance']?.toString() ?? '0',
      totalEarned: walletJson['total_earned']?.toString() ?? '0',
      totalPaidOut: walletJson['total_paid_out']?.toString() ?? '0',
      updatedAt: walletJson['updated_at']?.toString() ?? '',
      recentTransactions: txJson is List
          ? txJson
              .whereType<Map<String, dynamic>>()
              .map(ProviderRecentTransaction.fromJson)
              .toList()
          : const [],
    );
  }
}

