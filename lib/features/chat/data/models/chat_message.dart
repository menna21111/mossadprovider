class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.senderType,
    required this.senderId,
    required this.message,
    required this.isRead,
    this.readAt,
    this.createdAt,
  });

  final String id;
  final String senderType;
  final String senderId;
  final String message;
  final bool isRead;
  final String? readAt;
  final String? createdAt;

  bool get isFromProvider => senderType.toLowerCase() == 'provider';

  ChatMessage copyWith({bool? isRead, String? readAt}) {
    return ChatMessage(
      id: id,
      senderType: senderType,
      senderId: senderId,
      message: message,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt,
    );
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id']?.toString() ?? '',
      senderType: json['sender_type']?.toString() ?? '',
      senderId: json['sender_id']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      isRead: json['is_read'] == true,
      readAt: json['read_at']?.toString(),
      createdAt: json['created_at']?.toString(),
    );
  }
}

class ChatMessagesPage {
  const ChatMessagesPage({
    required this.results,
    required this.count,
    required this.hasMore,
    this.limit = 30,
    this.offset = 0,
  });

  final List<ChatMessage> results;
  final int count;
  final bool hasMore;
  final int limit;
  final int offset;

  factory ChatMessagesPage.fromJson(Map<String, dynamic> json) {
    final resultsRaw = json['results'];
    return ChatMessagesPage(
      results: resultsRaw is List
          ? resultsRaw
              .whereType<Map<String, dynamic>>()
              .map(ChatMessage.fromJson)
              .where((m) => m.id.isNotEmpty)
              .toList()
          : const [],
      count: int.tryParse(json['count']?.toString() ?? '') ?? 0,
      hasMore: json['has_more'] == true,
      limit: int.tryParse(json['limit']?.toString() ?? '') ?? 30,
      offset: int.tryParse(json['offset']?.toString() ?? '') ?? 0,
    );
  }
}
