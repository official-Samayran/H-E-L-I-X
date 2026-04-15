import 'dart:convert';

enum MessageRole { user, ai, system }

class ChatMessage {
  final String text;
  final MessageRole role;
  final DateTime timestamp;
  final bool isOfflineContext;

  ChatMessage({
    required this.text,
    required this.role,
    required this.timestamp,
    this.isOfflineContext = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'role': role.index,
      'timestamp': timestamp.toIso8601String(),
      'isOfflineContext': isOfflineContext,
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      text: json['text'],
      role: MessageRole.values[json['role']],
      timestamp: DateTime.parse(json['timestamp']),
      isOfflineContext: json['isOfflineContext'] ?? false,
    );
  }
}
