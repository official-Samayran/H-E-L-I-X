import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../theme/theme_manager.dart';
import '../../theme/app_theme.dart';
import '../../widgets/animated_aura.dart';
import '../../services/connection_service.dart';
import '../../services/intent_router.dart';
import '../../widgets/chat_bubble.dart';

class ChatTab extends StatefulWidget {
  const ChatTab({super.key});

  @override
  State<ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends State<ChatTab> {
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late stt.SpeechToText _speech;
  bool _isListening = false;
  
  final List<String> _smartReplies = [
    "System Status?",
    "HELIX, Lumos",
    "Summarize clipboard",
    "HELIX, wipe memory"
  ];

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  @override
  void dispose() {
    _chatController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) {
          if (val == 'done' || val == 'notListening') {
            setState(() => _isListening = false);
          }
        },
        onError: (val) => setState(() => _isListening = false),
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) => setState(() {
            _chatController.text = val.recognizedWords;
          }),
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
      if (_chatController.text.isNotEmpty) {
        _handleInput();
      }
    }
  }

  void _handleInput([String? overrideText]) async {
    final text = overrideText ?? _chatController.text;
    if (text.isEmpty) return;

    _chatController.clear();
    
    final connectionService = Provider.of<ConnectionService>(context, listen: false);

    // Secure Wipe intercept
    if (text.toLowerCase().trim() == 'helix, wipe memory') {
      _initiateSecureWipe(connectionService);
      return;
    }

    // Lumos/Nox intercept (mock hardware)
    if (text.toLowerCase().contains('helix, lumos') || text.toLowerCase().contains('helix, nox')) {
      connectionService.addSystemMessage("Hardware: Executed Flashlight Command -> ${text.split(',').last.trim()}");
      return;
    }

    final router = Provider.of<IntentRouter>(context, listen: false);
    final intent = await router.routeInput(text, connectionService.isLocalAvailable);
    
    if (intent == IntentType.systemCommand) {
      connectionService.addSystemMessage("Executed system command: $text");
    } else {
      await connectionService.sendMessage(text);
    }

    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
  }

  void _initiateSecureWipe(ConnectionService connectionService) {
    // Generate 6 digit OTP
    final String otp = (100000 + Random().nextInt(900000)).toString();
    connectionService.addSystemMessage("SECURITY ALERT: Memory wipe requested. OTP sent to samayran73@gmail.com (Mocked). Enter OTP to confirm.");
    // In a real app, use mailer here:
    // _sendEmailOTP("samayran73@gmail.com", otp);
    
    // We would store this OTP in state to verify the next message
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);
    final connectionService = Provider.of<ConnectionService>(context);
    final messages = connectionService.messages;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && _scrollController.position.pixels < _scrollController.position.maxScrollExtent) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });

    return Stack(
      children: [
        // Central Animated Aura
        if (themeManager.currentThemeType != AppThemeType.oled)
          Center(
            child: AnimatedAura(color: themeManager.auraColor),
          ),
        
        // UI Overlay
        RefreshIndicator(
          onRefresh: () async {
            // Re-sync logic
            await Future.delayed(const Duration(seconds: 1));
          },
          color: themeManager.accentColor,
          backgroundColor: themeManager.chatBackgroundColor,
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length + (connectionService.isTyping ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == messages.length) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: themeManager.accentColor)),
                              const SizedBox(width: 8),
                              Text('Helix is processing...', style: TextStyle(color: themeManager.textColor.withOpacity(0.5), fontSize: 12)),
                            ],
                          )
                        ),
                      );
                    }
                    return ChatBubble(message: messages[index]);
                  },
                ),
              ),
              
              // Smart Reply Chips
              Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _smartReplies.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        label: Text(_smartReplies[index], style: TextStyle(color: themeManager.textColor, fontSize: 12)),
                        backgroundColor: themeManager.chatBackgroundColor,
                        side: BorderSide(color: themeManager.accentColor.withOpacity(0.5)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        onPressed: () => _handleInput(_smartReplies[index]),
                      ),
                    );
                  },
                ),
              ),
              
              // Bottom Chat Interface
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: themeManager.currentThemeType == AppThemeType.oled ? null : BoxDecoration(
                  color: themeManager.chatBackgroundColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Mic Button
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: _isListening ? Colors.redAccent : themeManager.chatBackgroundColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: themeManager.textColor.withOpacity(0.1)),
                      ),
                      child: IconButton(
                        icon: Icon(
                          _isListening ? Icons.mic : Icons.mic_none,
                          color: _isListening ? Colors.white : themeManager.textColor,
                        ),
                        onPressed: _listen,
                      ),
                    ),
                    Expanded(
                      child: Container(
                        decoration: themeManager.currentThemeType == AppThemeType.oled 
                            ? BoxDecoration(
                                color: themeManager.textColor.withOpacity(0.03),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: themeManager.textColor.withOpacity(0.15),
                                  width: 1,
                                ),
                              )
                            : BoxDecoration(
                                color: themeManager.backgroundColor.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: themeManager.accentColor.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                        child: TextField(
                          controller: _chatController,
                          style: TextStyle(color: themeManager.textColor),
                          onSubmitted: (_) => _handleInput(),
                          decoration: InputDecoration(
                            hintText: 'Message Helix...',
                            hintStyle: TextStyle(
                              color: themeManager.textColor.withOpacity(0.5),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 14,
                            ),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      decoration: themeManager.currentThemeType == AppThemeType.oled ? null : BoxDecoration(
                        color: themeManager.accentColor,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.send_rounded,
                          color: themeManager.currentThemeType == AppThemeType.oled
                              ? themeManager.accentColor
                              : themeManager.backgroundColor,
                        ),
                        onPressed: _handleInput,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
