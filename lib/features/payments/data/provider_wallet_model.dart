class ProviderRecentTransaction {
  final String id;
  final String amount;
  final String transactionType;
  final String balanceAfter;
  final String createdAt;
  final String? title;
  final String? serviceTotal;
  final String? platformDue;
  final String? paymentLink;

  const ProviderRecentTransaction({
    required this.id,
    required this.amount,
    required this.transactionType,
    required this.balanceAfter,
    required this.createdAt,
    this.title,
    this.serviceTotal,
    this.platformDue,
    this.paymentLink,
  });

  factory ProviderRecentTransaction.fromJson(Map<String, dynamic> json) {
    return ProviderRecentTransaction(
      id: json['id']?.toString() ?? '',
      amount: json['amount']?.toString() ??
          json['platform_due']?.toString() ??
          json['platform_share']?.toString() ??
          '0',
      transactionType: json['transaction_type']?.toString() ??
          json['type']?.toString() ??
          '',
      balanceAfter: json['balance_after']?.toString() ?? '0',
      createdAt: json['created_at']?.toString() ??
          json['date']?.toString() ??
          '',
      title: json['title']?.toString() ??
          json['service_name']?.toString() ??
          json['name']?.toString(),
      serviceTotal: json['service_total']?.toString() ??
          json['total_amount']?.toString() ??
          json['total']?.toString(),
      platformDue: json['platform_due']?.toString() ??
          json['platform_share']?.toString() ??
          json['due_amount']?.toString(),
      paymentLink: json['payment_link']?.toString() ??
          json['current_payment_link']?.toString(),
    );
  }

  bool get isCredit {
    final t = transactionType.toLowerCase();
    if (t.contains('debit') ||
        t.contains('fee') ||
        t.contains('charge') ||
        t.contains('payment') ||
        t.contains('due')) {
      return false;
    }
    if (t.contains('credit') ||
        t.contains('refund') ||
        t.contains('top') ||
        t.contains('charge_wallet') ||
        t.contains('earned') ||
        t.contains('commission') ||
        t.contains('شحن') ||
        t.contains('استرداد')) {
      return true;
    }
    final raw = amount.trim();
    return !raw.startsWith('-');
  }

  String get displayTitle {
    if (title != null && title!.trim().isNotEmpty) return title!;
    final t = transactionType.toLowerCase();
    if (t.contains('refund') || t.contains('استرداد')) {
      return 'mosaedTxRefund';
    }
    if (t.contains('top') || t.contains('شحن') || t.contains('credit')) {
      return 'mosaedTxTopUp';
    }
    if (t.contains('fee') || t.contains('platform') || t.contains('رسوم')) {
      return 'mosaedTxPlatformFee';
    }
    if (t.contains('payment') || t.contains('مدفوع')) {
      return 'mosaedTxPayment';
    }
    return transactionType.isEmpty ? 'mosaedTxGeneric' : transactionType;
  }
}

class ProviderWallet {
  final String availableBalance;
  final String pendingBalance;
  final String totalEarned;
  final String totalPaidOut;
  final String updatedAt;
  final List<ProviderRecentTransaction> recentTransactions;

  const ProviderWallet({
    required this.availableBalance,
    required this.pendingBalance,
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
      pendingBalance: walletJson['pending_balance']?.toString() ??
          walletJson['processing_balance']?.toString() ??
          walletJson['pending_amount']?.toString() ??
          '0',
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
