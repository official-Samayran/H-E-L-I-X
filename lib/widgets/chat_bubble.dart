import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:flutter_highlighter/flutter_highlighter.dart';
import 'package:flutter_highlighter/themes/atom-one-dark.dart';
import '../theme/theme_manager.dart';
import '../models/chat_message.dart';
import 'package:add_2_calendar/add_2_calendar.dart';
import 'adaptive_ui.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isStreaming;

  const ChatBubble({super.key, required this.message, this.isStreaming = false});

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
            padding: isUser 
                ? EdgeInsets.symmetric(horizontal: 16.s(context), vertical: 12.s(context))
                : EdgeInsets.symmetric(horizontal: 4.s(context), vertical: 4.s(context)),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * (isUser ? 0.75 : 0.95),
            ),
            decoration: isUser ? (theme.currentThemeType == AppThemeType.oled 
                ? BoxDecoration(
                    color: theme.textColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16).copyWith(
                      bottomRight: const Radius.circular(4),
                    ),
                    border: Border.all(color: theme.textColor.withOpacity(0.15), width: 1),
                  )
                : BoxDecoration(
                    color: theme.accentColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(theme.borderRadius).copyWith(
                      bottomRight: const Radius.circular(4),
                    ),
                    border: Border.all(color: theme.accentColor.withOpacity(0.5), width: 1),
                  )) : null,
            child: isUser 
                ? Text(
                    message.text,
                    style: DefaultTextStyle.of(context).style.copyWith(
                      color: theme.textColor,
                      fontSize: 16,
                      height: 1.4,
                      letterSpacing: 0.0,
                    ),
                  )
                : _buildMarkdown(context, theme, message.text + (isStreaming ? ' █' : '')),
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

  Widget _buildMarkdown(BuildContext context, ThemeManager theme, String text) {
    return MarkdownBody(
      data: text,
      selectable: true,
      styleSheet: MarkdownStyleSheet(
        h1: TextStyle(color: theme.textColor, fontSize: 32, fontWeight: FontWeight.bold),
        h2: TextStyle(color: theme.textColor, fontSize: 26, fontWeight: FontWeight.bold),
        h3: TextStyle(color: theme.textColor, fontSize: 20, fontWeight: FontWeight.bold),
        p: TextStyle(color: theme.textColor, fontSize: 16, height: 1.6),
        listBullet: TextStyle(color: theme.textColor, fontSize: 16),
        code: TextStyle(
          color: theme.accentColor,
          backgroundColor: Colors.transparent,
          fontFamily: 'monospace',
          fontSize: 14,
        ),
        codeblockDecoration: const BoxDecoration(
          color: Colors.transparent,
        ),
        blockquoteDecoration: BoxDecoration(
          border: Border(left: BorderSide(color: theme.accentColor, width: 4)),
          color: theme.textColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(4),
        ),
        blockquote: TextStyle(color: theme.textColor.withOpacity(0.8), fontStyle: FontStyle.italic),
        tableBorder: TableBorder.all(color: theme.textColor.withOpacity(0.1), width: 1, borderRadius: BorderRadius.circular(8)),
        tableBody: TextStyle(color: theme.textColor),
        tableHead: TextStyle(color: theme.textColor, fontWeight: FontWeight.bold),
      ),
      builders: {
        'code': CodeElementBuilder(theme: theme),
      },
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
              currentLine = '\${word.substring(i)} ';
            }
          }
        } else {
          currentLine = '$word ';
        }
      } else {
        currentLine += '$word ';
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

class CodeElementBuilder extends MarkdownElementBuilder {
  final ThemeManager theme;
  CodeElementBuilder({required this.theme});

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final String textContent = element.textContent;
    String language = 'plaintext';

    if (element.attributes['class'] != null) {
      String lg = element.attributes['class'] as String;
      if (lg.startsWith('language-')) {
        language = lg.substring(9);
      }
    }

    if (!textContent.contains('\n')) {
      // Inline code
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: theme.textColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          textContent,
          style: TextStyle(
            color: theme.accentColor,
            fontFamily: 'monospace',
            fontSize: 14,
          ),
        ),
      );
    }

    // Fenced Code Block
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF282C34), // atom one dark bg
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.textColor.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  language.toUpperCase(),
                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12, fontFamily: 'monospace', fontWeight: FontWeight.bold),
                ),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: textContent));
                    HapticFeedback.lightImpact();
                  },
                  child: Row(
                    children: [
                      Icon(Icons.copy, size: 14, color: Colors.white.withOpacity(0.5)),
                      const SizedBox(width: 4),
                      Text('Copy', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ClipRRect(
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(16),
              child: HighlightView(
                textContent,
                language: language,
                theme: atomOneDarkTheme,
                textStyle: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
