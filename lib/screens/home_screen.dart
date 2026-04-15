import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/theme_manager.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_aura.dart';
import '../services/connection_service.dart';
import '../services/intent_router.dart';
import '../widgets/system_hud.dart';
import '../widgets/settings_modal.dart';
import '../widgets/chat_bubble.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

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

  void _handleInput() async {
    final text = _chatController.text;
    if (text.isEmpty) return;

    _chatController.clear();
    
    final router = Provider.of<IntentRouter>(context, listen: false);
    final connectionService = Provider.of<ConnectionService>(context, listen: false);
    
    final intent = await router.routeInput(text, connectionService.isLocalAvailable);
    
    if (intent == IntentType.systemCommand) {
      connectionService.addSystemMessage("Executed system command: $text");
    } else {
      await connectionService.sendMessage(text);
    }

    // Scroll to bottom after state updates
    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);
    final connectionService = Provider.of<ConnectionService>(context);
    final isLocal = connectionService.isLocalAvailable;

    final String statusText = isLocal ? 'Local' : 'Cloud';
    final Color statusColor = isLocal ? Colors.greenAccent : Colors.blueAccent;
    final messages = connectionService.messages;

    // Use post-frame callback to ensure scroll to bottom if new messages appeared
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && _scrollController.position.pixels < _scrollController.position.maxScrollExtent) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });

    return Scaffold(
      backgroundColor: themeManager.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.settings_outlined, color: themeManager.textColor),
          onPressed: () {
             showGeneralDialog(
               context: context,
               barrierDismissible: true,
               barrierLabel: 'Dismiss',
               pageBuilder: (context, anim1, anim2) {
                 return const Center(child: SettingsModal());
               },
             );
          },
        ),
        title: Column(
          children: [
            Text(
              'H E L I X',
              style: TextStyle(
                color: themeManager.textColor,
                letterSpacing: 8,
                fontWeight: FontWeight.w300,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: statusColor.withOpacity(0.5), blurRadius: 4),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'SYSTEMS READY: ${statusText.toUpperCase()}',
                  style: TextStyle(
                    color: themeManager.textColor.withOpacity(0.5),
                    fontSize: 10,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          PopupMenuButton<AppThemeType>(
            icon: Icon(Icons.palette_outlined, color: themeManager.textColor),
            color: themeManager.chatBackgroundColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            onSelected: (AppThemeType type) {
              themeManager.changeTheme(type);
            },
            itemBuilder: (context) {
              return AppThemes.themes.values.map((themeData) {
                return PopupMenuItem<AppThemeType>(
                  value: themeData.type,
                  child: Row(
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: themeData.auraColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        themeData.name,
                        style: TextStyle(color: themeManager.textColor),
                      ),
                    ],
                  ),
                );
              }).toList();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // Central Animated Aura
            Center(
              child: AnimatedAura(color: themeManager.auraColor),
            ),
            
            // UI Overlay
            Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      return ChatBubble(message: messages[index]);
                    },
                  ),
                ),
                
                // Realtime Telemetry HUD (conditionally active visually)
                if (isLocal) const SystemHud(),
                if (isLocal) const SizedBox(height: 16),
                
                // Bottom Chat Interface
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
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
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
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
                        decoration: BoxDecoration(
                          color: themeManager.accentColor,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.send_rounded,
                            color: themeManager.backgroundColor,
                          ),
                          onPressed: _handleInput,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
