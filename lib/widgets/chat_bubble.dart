import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/theme_manager.dart';
import '../models/chat_message.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeManager>(context);
    final isUser = message.role == MessageRole.user;
    final isSystem = message.role == MessageRole.system;

    return Align(
      alignment: isUser ? Alignment.centerRight : (isSystem ? Alignment.center : Alignment.centerLeft),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isSystem
              ? theme.chatBackgroundColor.withOpacity(0.5)
              : (isUser ? theme.accentColor.withOpacity(0.2) : theme.chatBackgroundColor),
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(16),
            bottomLeft: !isUser && !isSystem ? const Radius.circular(4) : const Radius.circular(16),
          ),
          border: Border.all(
            color: isSystem 
                ? theme.textColor.withOpacity(0.1) 
                : (isUser ? theme.accentColor.withOpacity(0.5) : theme.chatBackgroundColor),
            width: 1,
          ),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: isSystem ? theme.textColor.withOpacity(0.5) : theme.textColor,
            fontSize: isSystem ? 12 : 14,
            fontWeight: isSystem ? FontWeight.bold : FontWeight.normal,
            letterSpacing: isSystem ? 1.0 : 0.0,
          ),
        ),
      ),
    );
  }
}
