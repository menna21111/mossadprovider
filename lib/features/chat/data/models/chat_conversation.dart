enum ChatConversationStatus { active, completed, open }

/// Provider conversations list row from
/// `GET /api/custom_services/provider/custom-requests/conversations/`.
class ChatConversation {
  const ChatConversation({
    required this.requestId,
    required this.peerName,
    required this.requestTitle,
    this.peerImage,
    this.peerId,
    this.peerRating,
    this.price,
    this.lastMessage,
    this.lastMessageAt,
    this.lastMessageSenderType,
    this.unreadCount = 0,
    this.status = ChatConversationStatus.active,
    this.isPreview = false,
  });

  final String requestId;
  final String peerName;
  final String requestTitle;
  final String? peerImage;
  final String? peerId;
  final String? peerRating;
  final double? price;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final String? lastMessageSenderType;
  final int unreadCount;
  final ChatConversationStatus status;
  final bool isPreview;

  bool get hasUnread => unreadCount > 0;

  /// Always the customer name — never request title.
  /// Empty → UI shows localized "customer" / "عميل".
  String get displayPeerName => peerName.trim();

  bool get hasPeerImage =>
      peerImage != null && peerImage!.trim().isNotEmpty;

  ChatConversation copyWith({
    String? lastMessage,
    DateTime? lastMessageAt,
    int? unreadCount,
    String? peerName,
    String? peerImage,
  }) {
    return ChatConversation(
      requestId: requestId,
      peerName: peerName ?? this.peerName,
      requestTitle: requestTitle,
      peerImage: peerImage ?? this.peerImage,
      peerId: peerId,
      peerRating: peerRating,
      price: price,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      lastMessageSenderType: lastMessageSenderType,
      unreadCount: unreadCount ?? this.unreadCount,
      status: status,
      isPreview: isPreview,
    );
  }

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    final statusRaw = json['request_status']?.toString() ??
        json['status']?.toString() ??
        '';

    final requestTitle = _stringOrNull(json['request_title']) ??
        _stringOrNull(json['title']) ??
        '';

    // Real provider conversations payload: customer_name / customer_photo.
    final customerName = _stringOrNull(json['customer_name']);
    final peerName = customerName ??
        _stringOrNull(json['peer_name']) ??
        _stringOrNull(json['provider_name']) ??
        '';

    return ChatConversation(
      requestId: json['request_id']?.toString() ??
          json['custom_request_id']?.toString() ??
          json['id']?.toString() ??
          '',
      peerName: peerName,
      requestTitle: requestTitle,
      peerImage: _stringOrNull(
        json['customer_photo'] ??
            json['customer_image'] ??
            json['peer_image'] ??
            json['provider_photo'] ??
            json['provider_image'],
      ),
      peerId: _stringOrNull(
        json['customer_id'] ?? json['peer_id'] ?? json['provider_id'],
      ),
      peerRating: _stringOrNull(
        json['customer_rating'] ??
            json['peer_rating'] ??
            json['provider_rating'],
      ),
      lastMessage: _stringOrNull(json['last_message']),
      lastMessageAt:
          DateTime.tryParse(json['last_message_at']?.toString() ?? ''),
      lastMessageSenderType: _stringOrNull(json['last_message_sender_type']),
      unreadCount: int.tryParse(json['unread_count']?.toString() ?? '') ?? 0,
      status: statusFrom(statusRaw),
      price: double.tryParse(json['price']?.toString() ?? ''),
    );
  }

  static ChatConversationStatus statusFrom(String raw) {
    final s = raw.toLowerCase();
    if (s.contains('complete') ||
        s.contains('done') ||
        s.contains('finish') ||
        s.contains('cancel')) {
      return ChatConversationStatus.completed;
    }
    if (s.contains('progress') ||
        s.contains('accept') ||
        s.contains('assign') ||
        s.contains('active') ||
        s.contains('ongoing')) {
      return ChatConversationStatus.active;
    }
    return ChatConversationStatus.open;
  }

  static String? _stringOrNull(dynamic value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty || text == 'null') return null;
    return text;
  }
}

class ChatConversationsPage {
  const ChatConversationsPage({
    required this.results,
    required this.count,
    required this.hasMore,
    this.limit = 20,
    this.offset = 0,
  });

  final List<ChatConversation> results;
  final int count;
  final bool hasMore;
  final int limit;
  final int offset;

  factory ChatConversationsPage.fromJson(Map<String, dynamic> json) {
    // Support raw page or wrapped `{ data: { results... } }`.
    final root = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;

    final resultsRaw = root['results'];
    final results = <ChatConversation>[];
    if (resultsRaw is List) {
      for (final item in resultsRaw) {
        Map<String, dynamic>? map;
        if (item is Map<String, dynamic>) {
          map = item;
        } else if (item is Map) {
          map = item.map((k, v) => MapEntry(k.toString(), v));
        }
        if (map == null) continue;
        final conversation = ChatConversation.fromJson(map);
        if (conversation.requestId.isNotEmpty) {
          results.add(conversation);
        }
      }
    }
    return ChatConversationsPage(
      results: results,
      count: int.tryParse(root['count']?.toString() ?? '') ?? results.length,
      hasMore: root['has_more'] == true,
      limit: int.tryParse(root['limit']?.toString() ?? '') ?? 20,
      offset: int.tryParse(root['offset']?.toString() ?? '') ?? 0,
    );
  }
}
