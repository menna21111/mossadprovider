import 'provider_dues_status_model.dart';
import 'provider_wallet_model.dart';

class ProviderDueItem {
  const ProviderDueItem({
    required this.id,
    required this.title,
    required this.serviceTotal,
    required this.platformDue,
    this.paymentLink = '',
    this.category = '',
  });

  final String id;
  final String title;
  final String serviceTotal;
  final String platformDue;
  final String paymentLink;
  final String category;

  factory ProviderDueItem.fromJson(Map<String, dynamic> json) {
    return ProviderDueItem(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ??
          json['service_name']?.toString() ??
          json['name']?.toString() ??
          '',
      serviceTotal: json['service_total']?.toString() ??
          json['total_amount']?.toString() ??
          json['total']?.toString() ??
          '0',
      platformDue: json['platform_due']?.toString() ??
          json['platform_share']?.toString() ??
          json['due_amount']?.toString() ??
          json['amount']?.toString() ??
          '0',
      paymentLink: json['payment_link']?.toString() ??
          json['current_payment_link']?.toString() ??
          '',
      category: json['category']?.toString() ??
          json['specialization']?.toString() ??
          '',
    );
  }
}

class ProviderDuesResponse {
  const ProviderDuesResponse({
    required this.due,
    required this.recentTransactions,
    this.items = const [],
    this.lastServiceAmount = '0',
    this.lastPlatformShare = '0',
  });

  final ProviderDuesStatus due;
  final List<ProviderRecentTransaction> recentTransactions;
  final List<ProviderDueItem> items;
  final String lastServiceAmount;
  final String lastPlatformShare;

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

    final txRaw = json['recent_transactions'] ?? json['history'];
    final transactions = txRaw is List
        ? txRaw
            .whereType<Map<String, dynamic>>()
            .map(ProviderRecentTransaction.fromJson)
            .toList()
        : const <ProviderRecentTransaction>[];

    final itemsRaw = json['items'] ??
        json['dues'] ??
        json['unpaid_dues'] ??
        json['dues_list'];
    var items = itemsRaw is List
        ? itemsRaw
            .whereType<Map<String, dynamic>>()
            .map(ProviderDueItem.fromJson)
            .toList()
        : <ProviderDueItem>[];

    final lastService = json['last_service_amount']?.toString() ??
        dueJson['last_service_amount']?.toString() ??
        (items.isNotEmpty ? items.first.serviceTotal : null) ??
        (transactions.isNotEmpty
            ? (transactions.first.serviceTotal ?? transactions.first.amount)
            : '0');

    final lastShare = json['last_platform_share']?.toString() ??
        dueJson['last_platform_share']?.toString() ??
        (items.isNotEmpty ? items.first.platformDue : null) ??
        (transactions.isNotEmpty
            ? (transactions.first.platformDue ?? transactions.first.amount)
            : '0');

    return ProviderDuesResponse(
      due: ProviderDuesStatus.fromJson(dueJson),
      recentTransactions: transactions,
      items: items,
      lastServiceAmount: lastService,
      lastPlatformShare: lastShare,
    );
  }
}
