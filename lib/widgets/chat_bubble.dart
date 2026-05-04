import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/theme_manager.dart';
import '../models/chat_message.dart';
import 'package:add_2_calendar/add_2_calendar.dart';
import 'adaptive_ui.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeManager>(context);
    final isUser = message.role == MessageRole.user;
    final isSystem = message.role == MessageRole.system;

    if (theme.currentThemeType == AppThemeType.ascii) {
      return _buildAsciiBubble(context, theme, isUser, isSystem);
    }

    return Align(
      alignment: isUser ? Alignment.centerRight : (isSystem ? Alignment.center : Alignment.centerLeft),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: EdgeInsets.symmetric(vertical: 6.s(context)),
            padding: EdgeInsets.symmetric(horizontal: 16.s(context), vertical: 12.s(context)),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            decoration: theme.currentThemeType == AppThemeType.oled 
                ? BoxDecoration(
                    color: theme.textColor.withOpacity(0.02),
                    borderRadius: BorderRadius.circular(16).copyWith(
                      bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(16),
                      bottomLeft: !isUser && !isSystem ? const Radius.circular(4) : const Radius.circular(16),
                    ),
                    border: Border.all(
                      color: theme.textColor.withOpacity(0.15),
                      width: 1,
                    ),
                  )
                : BoxDecoration(
                    color: isSystem
                        ? theme.chatBackgroundColor.withOpacity(0.5)
                        : (isUser ? theme.accentColor.withOpacity(0.2) : theme.chatBackgroundColor),
                    borderRadius: BorderRadius.circular(theme.borderRadius).copyWith(
                      bottomRight: isUser ? Radius.circular(4) : Radius.circular(theme.borderRadius),
                      bottomLeft: !isUser && !isSystem ? Radius.circular(4) : Radius.circular(theme.borderRadius),
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
              style: DefaultTextStyle.of(context).style.copyWith(
                color: isSystem ? theme.textColor.withOpacity(0.5) : theme.textColor,
                fontSize: isSystem ? 12 : 14,
                letterSpacing: isSystem ? 1.0 : 0.0,
              ),
            ),
          ),
          if (message.hasTaskIntent)
            Padding(
              padding: EdgeInsets.only(top: 4.s(context), bottom: 8.s(context), right: 8.s(context), left: 8.s(context)),
              child: ActionChip(
                backgroundColor: theme.accentColor.withOpacity(0.1),
                side: BorderSide(color: theme.accentColor.withOpacity(0.5)),
                labelStyle: TextStyle(color: theme.accentColor, fontSize: 12),
                label: const Text('Add to Task'),
                avatar: Icon(Icons.calendar_today, size: 14, color: theme.accentColor),
                onPressed: () {
                  final Event event = Event(
                    title: message.taskTitle,
                    description: 'Scheduled via Helix AI: ${message.text}',
                    location: '',
                    startDate: DateTime.now().add(const Duration(days: 1, hours: 9)), 
                    endDate: DateTime.now().add(const Duration(days: 1, hours: 10)),
                  );
                  Add2Calendar.addEvent2Cal(event);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAsciiBubble(BuildContext context, ThemeManager theme, bool isUser, bool isSystem) {
    const int maxChars = 32;
    List<String> lines = [];
    final words = message.text.split(' ');
    String currentLine = '';
    
    for (var word in words) {
      if ((currentLine + word).length > maxChars) {
        if (currentLine.isNotEmpty) {
          lines.add(currentLine.trimRight());
          currentLine = '';
        }
        if (word.length > maxChars) {
          for (int i = 0; i < word.length; i += maxChars) {
            if (i + maxChars < word.length) {
              lines.add(word.substring(i, i + maxChars));
            } else {
              currentLine = word.substring(i) + ' ';
            }
          }
        } else {
          currentLine = word + ' ';
        }
      } else {
        currentLine += word + ' ';
      }
    }
    if (currentLine.isNotEmpty) {
      lines.add(currentLine.trimRight());
    }

    int longestLine = lines.fold(0, (max, line) => line.length > max ? line.length : max);
    if (longestLine == 0) longestLine = 1;

    String topBorder = '+${'-' * (longestLine + 2)}+';
    String bottomBorder = '+${'-' * (longestLine + 2)}+';

    List<String> boxLines = [topBorder];
    for (var line in lines) {
      boxLines.add('| ${line.padRight(longestLine)} |');
    }
    boxLines.add(bottomBorder);

    String prefix = isSystem ? '[SYSTEM]\n' : (isUser ? '>[USER]\n' : '>[HELIX]\n');
    String finalAscii = prefix + boxLines.join('\n');

    return Align(
      alignment: isUser ? Alignment.centerRight : (isSystem ? Alignment.center : Alignment.centerLeft),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: EdgeInsets.symmetric(vertical: 6.s(context)),
            child: Text(
              finalAscii,
              style: TextStyle(
                color: isSystem ? theme.textColor.withOpacity(0.5) : theme.textColor,
                fontFamily: 'monospace',
                fontSize: 12,
                height: 1.2,
              ),
            ),
          ),
          if (message.hasTaskIntent)
            Padding(
              padding: EdgeInsets.only(bottom: 8.s(context)),
              child: Text(
                '+---[ ADD TO CALENDAR ]---+',
                style: TextStyle(color: theme.accentColor, fontFamily: 'monospace', fontSize: 10),
              ),
            ),
        ],
      ),
    );
  }
}
