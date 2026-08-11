class AppNotification {
  const AppNotification({
    required this.id,
    required this.event,
    required this.title,
    required this.body,
    required this.data,
    required this.isRead,
    this.createdAt,
    this.readAt,
  });

  final String id;
  final String event;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final bool isRead;
  final String? createdAt;
  final String? readAt;

  String? get requestId => data['request_id']?.toString();
  String? get offerId => data['offer_id']?.toString();

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final dataRaw = json['data'];
    return AppNotification(
      id: json['id']?.toString() ?? json['notification_id']?.toString() ?? '',
      event: json['event']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      data: dataRaw is Map<String, dynamic>
          ? Map<String, dynamic>.from(dataRaw)
          : _extractDataFields(json),
      isRead: json['is_read'] == true,
      createdAt: json['created_at']?.toString(),
      readAt: json['read_at']?.toString(),
    );
  }

  factory AppNotification.fromSocket(Map<String, dynamic> json) {
    final data = _extractDataFields(json);
    return AppNotification(
      id: json['notification_id']?.toString() ?? json['id']?.toString() ?? '',
      event: json['event']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      data: data,
      isRead: false,
      createdAt: json['created_at']?.toString(),
    );
  }

  static Map<String, dynamic> _extractDataFields(Map<String, dynamic> json) {
    const keys = [
      'request_id',
      'offer_id',
      'provider_name',
      'sender_type',
      'description_preview',
      'specialization_name',
      'scheduled_date',
      'distance_km',
      'average_rating',
      'final_price',
      'note',
    ];
    final map = <String, dynamic>{};
    for (final key in keys) {
      if (json[key] != null) map[key] = json[key];
    }
    return map;
  }
}

class NotificationsPage {
  const NotificationsPage({
    required this.results,
    required this.count,
    required this.hasMore,
    this.limit = 20,
    this.offset = 0,
  });

  final List<AppNotification> results;
  final int count;
  final bool hasMore;
  final int limit;
  final int offset;

  factory NotificationsPage.fromJson(Map<String, dynamic> json) {
    final resultsRaw = json['results'];
    return NotificationsPage(
      results: resultsRaw is List
          ? resultsRaw
              .whereType<Map<String, dynamic>>()
              .map(AppNotification.fromJson)
              .where((n) => n.id.isNotEmpty)
              .toList()
          : const [],
      count: int.tryParse(json['count']?.toString() ?? '') ?? 0,
      hasMore: json['has_more'] == true,
      limit: int.tryParse(json['limit']?.toString() ?? '') ?? 20,
      offset: int.tryParse(json['offset']?.toString() ?? '') ?? 0,
    );
  }
}
