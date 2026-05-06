enum MessageRole { user, ai, system }

class ChatMessage {
  final String text;
  final MessageRole role;
  final DateTime timestamp;
  final bool isOfflineContext;
  final String? attachmentPath;
  final bool isImageAttachment;

  ChatMessage({
    required this.text,
    required this.role,
    required this.timestamp,
    this.isOfflineContext = false,
    this.attachmentPath,
    this.isImageAttachment = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'role': role.index,
      'timestamp': timestamp.toIso8601String(),
      'isOfflineContext': isOfflineContext,
      'attachmentPath': attachmentPath,
      'isImageAttachment': isImageAttachment,
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      text: json['text'],
      role: MessageRole.values[json['role']],
      timestamp: DateTime.parse(json['timestamp']),
      isOfflineContext: json['isOfflineContext'] ?? false,
      attachmentPath: json['attachmentPath'],
      isImageAttachment: json['isImageAttachment'] ?? false,
    );
  }

  bool get hasTaskIntent {
    if (role != MessageRole.user) return false;
    final lower = text.toLowerCase();
    return lower.contains('remind me') || 
           lower.contains('schedule') || 
           lower.contains('kal subah') ||
           lower.contains('remind');
  }

  String get taskTitle {
    final lower = text.toLowerCase();
    int idx = lower.indexOf('remind me to ');
    if (idx != -1) {
      return text.substring(idx + 'remind me to '.length).trim();
    }
    idx = lower.indexOf('schedule ');
    if (idx != -1) {
      return text.substring(idx + 'schedule '.length).trim();
    }
    return text.length > 50 ? '${text.substring(0, 47)}...' : text;
  }
}
