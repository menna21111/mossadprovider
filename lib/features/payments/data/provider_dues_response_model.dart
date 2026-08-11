import 'provider_dues_status_model.dart';
import 'provider_wallet_model.dart';

class ProviderDuesResponse {
  const ProviderDuesResponse({
    required this.due,
    required this.recentTransactions,
  });

  final ProviderDuesStatus due;
  final List<ProviderRecentTransaction> recentTransactions;

  factory ProviderDuesResponse.fromJson(Map<String, dynamic> json) {
    final dueRaw = json['due'];
    final dueJson = dueRaw is Map<String, dynamic>
        ? dueRaw
        : <String, dynamic>{
            'outstanding_amount': json['outstanding_amount'],
            'is_blocked': json['is_blocked'],
            'blocked_at': json['blocked_at'],
            'current_payment_link': json['current_payment_link'],
          };

    final txRaw = json['recent_transactions'];
    final transactions = txRaw is List
        ? txRaw
            .whereType<Map<String, dynamic>>()
            .map(ProviderRecentTransaction.fromJson)
            .toList()
        : const <ProviderRecentTransaction>[];

    return ProviderDuesResponse(
      due: ProviderDuesStatus.fromJson(dueJson),
      recentTransactions: transactions,
    );
  }
}
