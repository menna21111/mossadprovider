class ProviderDuesStatus {
  final String outstandingAmount;
  final bool isBlocked;
  final String blockedAt;
  final String currentPaymentLink;

  const ProviderDuesStatus({
    required this.outstandingAmount,
    required this.isBlocked,
    required this.blockedAt,
    required this.currentPaymentLink,
  });

  factory ProviderDuesStatus.fromJson(Map<String, dynamic> json) {
    // Supports both flat status payloads and nested `{ "due": {...} }`.
    final nested = json['due'];
    final source =
        nested is Map<String, dynamic> ? nested : json;

    final rawIsBlocked = source['is_blocked'];
    final isBlocked = rawIsBlocked == true ||
        rawIsBlocked?.toString().toLowerCase() == 'true' ||
        rawIsBlocked?.toString() == '1';

    final blockedAt = source['blocked_at']?.toString() ?? '';
    final paymentLink = source['current_payment_link']?.toString() ?? '';

    return ProviderDuesStatus(
      outstandingAmount: source['outstanding_amount']?.toString() ?? '0',
      isBlocked: isBlocked,
      blockedAt: blockedAt == 'null' ? '' : blockedAt,
      currentPaymentLink: paymentLink == 'null' ? '' : paymentLink,
    );
  }
}
