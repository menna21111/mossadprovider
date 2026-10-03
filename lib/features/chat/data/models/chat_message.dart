class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.senderType,
    required this.senderId,
    required this.message,
    required this.isRead,
    this.readAt,
    this.createdAt,
    this.messageType = ChatMessageType.text,
    this.attachmentUrl,
    this.attachmentDuration,
    this.fileName,
    this.fileSize,
  });

  final String id;
  final String senderType;
  final String senderId;
  final String message;
  final bool isRead;
  final String? readAt;
  final String? createdAt;
  final String messageType;
  final String? attachmentUrl;
  final int? attachmentDuration;
  final String? fileName;
  final int? fileSize;

  bool get isFromCustomer => senderType.toLowerCase() == 'customer';
  bool get isFromProvider => senderType.toLowerCase() == 'provider';
  bool get isText => messageType == ChatMessageType.text;
  bool get isImage => messageType == ChatMessageType.image;
  bool get isVoice => messageType == ChatMessageType.voice;
  bool get isFile => messageType == ChatMessageType.file;
  bool get isLocalPending => id.startsWith('local_');
  bool get hasCaption => message.trim().isNotEmpty;

  bool get isLocalAttachment {
    final url = attachmentUrl;
    if (url == null || url.isEmpty) return false;
    return !url.startsWith('http://') && !url.startsWith('https://');
  }

  ChatMessage copyWith({
    String? id,
    bool? isRead,
    String? readAt,
    String? message,
    String? messageType,
    String? attachmentUrl,
    int? attachmentDuration,
    String? fileName,
    int? fileSize,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      senderType: senderType,
      senderId: senderId,
      message: message ?? this.message,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt,
      messageType: messageType ?? this.messageType,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      attachmentDuration: attachmentDuration ?? this.attachmentDuration,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
    );
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final nested = json['message'];
    if (nested is Map<String, dynamic> && json['sender_type'] == null) {
      return ChatMessage.fromJson(nested);
    }

    final type = json['message_type']?.toString().trim().toLowerCase();
    return ChatMessage(
      id: json['id']?.toString() ?? '',
      senderType: json['sender_type']?.toString() ?? '',
      senderId: json['sender_id']?.toString() ?? '',
      message: nested is String ? nested : (json['text']?.toString() ?? ''),
      isRead: json['is_read'] == true,
      readAt: json['read_at']?.toString(),
      createdAt: json['created_at']?.toString(),
      messageType: (type == null || type.isEmpty) ? ChatMessageType.text : type,
      attachmentUrl:
          _stringOrNull(json['attachment_url'] ?? json['attachment']),
      attachmentDuration: _asInt(json['attachment_duration']),
      fileName: _stringOrNull(json['file_name']),
      fileSize: _asInt(json['file_size']),
    );
  }

  static String? _stringOrNull(dynamic value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty || text == 'null') return null;
    return text;
  }

  static int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.round();
    return int.tryParse(value.toString());
  }
}

class ChatMessageType {
  static const String text = 'text';
  static const String image = 'image';
  static const String voice = 'voice';
  static const String file = 'file';
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
              .where(
                (m) =>
                    m.id.isNotEmpty ||
                    m.hasCaption ||
                    m.attachmentUrl != null,
              )
              .toList()
          : const [],
      count: int.tryParse(json['count']?.toString() ?? '') ?? 0,
      hasMore: json['has_more'] == true,
      limit: int.tryParse(json['limit']?.toString() ?? '') ?? 30,
      offset: int.tryParse(json['offset']?.toString() ?? '') ?? 0,
    );
  }
}
