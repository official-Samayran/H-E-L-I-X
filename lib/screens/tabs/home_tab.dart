import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../services/notification_service.dart';

import '../../theme/theme_manager.dart';
import '../../widgets/animated_aura.dart';
import '../../services/connection_service.dart';
import '../../services/intent_router.dart';
import '../../models/chat_message.dart';
import '../../services/task_service.dart';
import '../../models/task_item.dart';
import '../../widgets/chat_bubble.dart';
import '../search_results_screen.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> with TickerProviderStateMixin {
  int _currentSection = 0; // 0 for Productivity, 1 for Control Center
  final PageController _pageController = PageController();

  // Chat Bar State
  bool _isChatExpanded = false;
  bool _isUtilityExpanded = false;

  String? _pendingAttachmentPath;
  bool _pendingAttachmentIsImage = false;
  String? _pendingAttachmentName;

  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late stt.SpeechToText _speech;
  bool _isListening = false;

  double _lastHapticOffset = 0.0;
  bool _showScrollToBottom = false;
  static const MethodChannel _hapticChannel = MethodChannel(
    'com.example.helix/haptics',
  );
  static const MethodChannel _screenShareChannel = MethodChannel(
    'com.example.helix/screenshare',
  );

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if ((_scrollController.offset - _lastHapticOffset).abs() > 50) {
      _lastHapticOffset = _scrollController.offset;
      try {
        _hapticChannel.invokeMethod('vibrateWaveform');
      } catch (e) {
        Provider.of<ThemeManager>(context, listen: false).triggerHaptic();
      }
    }

    if (_scrollController.hasClients) {
      final isNearBottom =
          _scrollController.position.maxScrollExtent -
              _scrollController.offset <=
          100;
      if (_showScrollToBottom == isNearBottom) {
        setState(() {
          _showScrollToBottom = !isNearBottom;
        });
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _chatController.dispose();
    _scrollController.removeListener(_onScroll);
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
    final rawText = overrideText ?? _chatController.text;
    final text = rawText.trim();
    if (text.isEmpty && _pendingAttachmentPath == null) return;

    // Clear immediately to prevent rapid duplicate submissions
    setState(() {
      _chatController.clear();
      if (!_isChatExpanded) _isChatExpanded = true;
    });

    final connectionService = Provider.of<ConnectionService>(
      context,
      listen: false,
    );

    if (text.isNotEmpty) {
      // Lumos/Nox intercept (mock hardware)
      if (text.toLowerCase().contains('helix, lumos') ||
          text.toLowerCase().contains('helix, nox')) {
        connectionService.addSystemMessage(
          "Hardware: Executed Flashlight Command -> ${text.split(',').last.trim()}",
        );
        setState(() {
          _pendingAttachmentPath = null;
          _pendingAttachmentName = null;
        });
        return;
      }

      final router = Provider.of<IntentRouter>(context, listen: false);

      // Coding Agent Wake-up Logic
      if (router.isCodingIntent(text)) {
        try {
          await connectionService.sendPCCommand('START_CODING_AGENT');
          if (mounted) {
            final notificationService =
                Provider.of<NotificationService>(context, listen: false);
            notificationService.showLocalNotification(
              title: "🧬 HELIX Coding Agent",
              body: "Project Sandbox initialized at E:\\Helix_Projects",
            );
          }
        } catch (e) {
          debugPrint("Agent launch failed: $e");
        }
      }
      final intent = await router.routeInput(
        text,
        connectionService.isLocalAvailable,
      );

      if (intent == IntentType.systemCommand) {
        connectionService.addSystemMessage("Executed system command: $text");
        setState(() {
          _pendingAttachmentPath = null;
          _pendingAttachmentName = null;
        });
        return;
      }

      if (intent == IntentType.taskExtraction) {
        connectionService.addSystemMessage(
          "AI automatically extracted and saved your task.",
        );
      }
    }

    final attachmentPath = _pendingAttachmentPath;
    final isImage = _pendingAttachmentIsImage;

    setState(() {
      _pendingAttachmentPath = null;
      _pendingAttachmentName = null;
    });

    // Do not await sendMessage so we can scroll immediately
    connectionService.sendMessage(
      text,
      attachmentPath: attachmentPath,
      isImage: isImage,
    );

    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: source);
    if (file != null) {
      setState(() {
        _pendingAttachmentPath = file.path;
        _pendingAttachmentIsImage = true;
        _pendingAttachmentName = file.name;
        _isUtilityExpanded = false;
      });
      if (!_isChatExpanded) setState(() => _isChatExpanded = true);
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.pickFiles();
    if (result != null && result.files.isNotEmpty) {
      final filePath = result.files.first.path;
      if (filePath != null) {
        setState(() {
          _pendingAttachmentPath = filePath;
          _pendingAttachmentIsImage = false;
          _pendingAttachmentName = result.files.first.name;
          _isUtilityExpanded = false;
        });
        if (!_isChatExpanded) setState(() => _isChatExpanded = true);
      }
    }
  }

  Future<void> _startScreenShare() async {
    try {
      await _screenShareChannel.invokeMethod('startScreenShare');
      if (!_isChatExpanded) setState(() => _isChatExpanded = true);
      final connectionService = Provider.of<ConnectionService>(
        context,
        listen: false,
      );
      connectionService.addSystemMessage("Screen sharing session initiated.");
    } catch (e) {
      final connectionService = Provider.of<ConnectionService>(
        context,
        listen: false,
      );
      connectionService.addSystemMessage("Failed to start screen share: $e");
    }
  }

  Widget _buildGlassCard({
    required Widget child,
    required ThemeManager themeManager,
    double? height,
    double? width,
    EdgeInsetsGeometry? padding,
  }) {
    return Container(
      height: height,
      width: width,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeManager.currentThemeType == AppThemeType.oled
            ? Colors.black
            : themeManager.chatBackgroundColor.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: themeManager.textColor.withValues(alpha: 0.05),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: child,
        ),
      ),
    );
  }

  Widget _buildProductivitySection(ThemeManager themeManager) {
    final taskService = Provider.of<TaskService>(context);

    Widget buildTaskList(List<TaskItem> items, String emptyMessage) {
      if (items.isEmpty) {
        return Center(
          child: Text(
            emptyMessage,
            style: TextStyle(
              color: themeManager.textColor.withValues(alpha: 0.4),
              fontSize: 12,
            ),
          ),
        );
      }
      return ListView.builder(
        shrinkWrap: true,
        physics: const BouncingScrollPhysics(),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final task = items[index];
          return ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: IconButton(
              icon: Icon(
                task.isCompleted ? Icons.check_circle : Icons.circle_outlined,
                color: task.isCompleted
                    ? themeManager.accentColor.withValues(alpha: 0.5)
                    : themeManager.accentColor,
                size: 20,
              ),
              onPressed: () => taskService.toggleTaskCompletion(task.id),
            ),
            title: Text(
              task.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: themeManager.textColor.withValues(
                  alpha: task.isCompleted ? 0.5 : 1.0,
                ),
                decoration: task.isCompleted
                    ? TextDecoration.lineThrough
                    : null,
                fontSize: 14,
              ),
            ),
            trailing: IconButton(
              icon: Icon(
                Icons.close,
                size: 16,
                color: themeManager.textColor.withValues(alpha: 0.3),
              ),
              onPressed: () => taskService.removeTask(task.id),
            ),
          );
        },
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildGlassCard(
                themeManager: themeManager,
                height: 220,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_month,
                          color: themeManager.accentColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Reminders',
                          style: TextStyle(
                            color: themeManager.textColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: buildTaskList(
                        taskService.reminders,
                        'No reminders',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildGlassCard(
                themeManager: themeManager,
                height: 220,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          color: themeManager.accentColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'To-Do List',
                          style: TextStyle(
                            color: themeManager.textColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: buildTaskList(taskService.todos, 'All caught up'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildGlassCard(
          themeManager: themeManager,
          height: 260,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.notes, color: themeManager.accentColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Quick Notes',
                    style: TextStyle(
                      color: themeManager.textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: buildTaskList(taskService.notes, 'Jot something down'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildControlCenterSection(ThemeManager themeManager) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      children: [
        _buildGlassCard(
          themeManager: themeManager,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.memory, color: themeManager.accentColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'PC Status',
                    style: TextStyle(
                      color: themeManager.textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.greenAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'ONLINE',
                      style: TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStat(themeManager, 'CPU', '34%'),
                  _buildStat(themeManager, 'RAM', '12GB'),
                  _buildStat(themeManager, 'GPU', '45°C'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildGlassCard(
                themeManager: themeManager,
                height: 120,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.rocket_launch,
                      color: themeManager.accentColor,
                      size: 24,
                    ),
                    const Spacer(),
                    Text(
                      'Quick Launch',
                      style: TextStyle(
                        color: themeManager.textColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Ready',
                      style: TextStyle(
                        color: themeManager.textColor.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildGlassCard(
                themeManager: themeManager,
                height: 120,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.smart_toy,
                      color: themeManager.accentColor,
                      size: 24,
                    ),
                    const Spacer(),
                    Text(
                      'AI Provider',
                      style: TextStyle(
                        color: themeManager.textColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Gemini Flash',
                      style: TextStyle(
                        color: themeManager.textColor.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildGlassCard(
          themeManager: themeManager,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Media Controls',
                style: TextStyle(
                  color: themeManager.textColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () {},
                    icon: Icon(
                      Icons.skip_previous,
                      color: themeManager.textColor,
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: themeManager.accentColor.withValues(alpha: 0.2),
                    ),
                    child: IconButton(
                      onPressed: () {},
                      icon: Icon(
                        Icons.play_arrow,
                        color: themeManager.accentColor,
                        size: 32,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: Icon(Icons.skip_next, color: themeManager.textColor),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStat(ThemeManager themeManager, String label, String val) {
    return Column(
      children: [
        Text(
          val,
          style: TextStyle(
            color: themeManager.textColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: themeManager.textColor.withValues(alpha: 0.5),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildSegmentedControl(ThemeManager themeManager) {
    return Row(
      children: [
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(
              left: 16,
              right: 8,
              top: 8,
              bottom: 8,
            ),
            height: 44,
            decoration: BoxDecoration(
              color: themeManager.currentThemeType == AppThemeType.oled
                  ? Colors.black
                  : themeManager.chatBackgroundColor.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: themeManager.textColor.withValues(alpha: 0.1),
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      left: _currentSection == 0 ? 0 : constraints.maxWidth / 2,
                      width: constraints.maxWidth / 2,
                      height: 42,
                      child: Container(
                        decoration: BoxDecoration(
                          color: themeManager.textColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(21),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              setState(() => _currentSection = 0);
                              _pageController.animateToPage(
                                0,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOutCubic,
                              );
                            },
                            child: Center(
                              child: Text(
                                'Productivity',
                                style: TextStyle(
                                  color: _currentSection == 0
                                      ? themeManager.textColor
                                      : themeManager.textColor.withValues(alpha: 0.5),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              setState(() => _currentSection = 1);
                              _pageController.animateToPage(
                                1,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOutCubic,
                              );
                            },
                            child: Center(
                              child: Text(
                                'Control',
                                style: TextStyle(
                                  color: _currentSection == 1
                                      ? themeManager.textColor
                                      : themeManager.textColor.withValues(alpha: 0.5),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
          height: 44,
          width: 44,
          decoration: BoxDecoration(
            color: themeManager.currentThemeType == AppThemeType.oled
                ? Colors.black
                : themeManager.chatBackgroundColor.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: themeManager.textColor.withValues(alpha: 0.1)),
          ),
          child: IconButton(
            icon: Icon(Icons.search, size: 20, color: themeManager.textColor),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SearchResultsScreen()),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildChatBar(ThemeManager themeManager) {
    return Positioned(
      bottom: 24,
      left: 16,
      right: 16,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.elasticOut,
        constraints: const BoxConstraints(minHeight: 60),
        decoration: BoxDecoration(
          color: themeManager.currentThemeType == AppThemeType.oled
              ? Colors.black.withValues(alpha: 0.8)
              : themeManager.backgroundColor.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: themeManager.accentColor.withValues(alpha: 0.1),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
          border: Border.all(color: themeManager.textColor.withValues(alpha: 0.1)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(scale: animation, child: child),
                );
              },
              child: _isUtilityExpanded
                  ? _buildUtilityDock(themeManager)
                  : _buildDefaultInput(themeManager),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultInput(ThemeManager themeManager) {
    return Column(
      key: const ValueKey('default_input'),
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_pendingAttachmentPath != null)
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 12),
            child: Row(
              children: [
                _pendingAttachmentIsImage
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.file(
                          File(_pendingAttachmentPath!),
                          height: 40,
                          width: 40,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Icon(
                        Icons.insert_drive_file,
                        color: themeManager.accentColor,
                      ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _pendingAttachmentName ?? '',
                    style: TextStyle(
                      color: themeManager.textColor,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.close,
                    color: themeManager.textColor.withValues(alpha: 0.5),
                    size: 16,
                  ),
                  onPressed: () => setState(() {
                    _pendingAttachmentPath = null;
                    _pendingAttachmentName = null;
                  }),
                ),
              ],
            ),
          ),
        Row(
          children: [
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(
                Icons.add_rounded,
                color: themeManager.textColor.withValues(alpha: 0.7),
              ),
              onPressed: () {
                setState(() {
                  _isUtilityExpanded = true;
                });
                Provider.of<ThemeManager>(
                  context,
                  listen: false,
                ).triggerHaptic();
              },
            ),
            Expanded(
              child: TextField(
                controller: _chatController,
                style: TextStyle(color: themeManager.textColor),
                decoration: InputDecoration(
                  hintText: 'Message Helix...',
                  hintStyle: TextStyle(
                    color: themeManager.textColor.withValues(alpha: 0.4),
                  ),
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _handleInput(),
                onTap: () {
                  if (!_isChatExpanded) {
                    setState(() {
                      _isChatExpanded = true;
                    });
                  }
                },
              ),
            ),
            IconButton(
              icon: Icon(
                _isListening ? Icons.mic : Icons.mic_none,
                color: _isListening
                    ? Colors.redAccent
                    : themeManager.textColor.withValues(alpha: 0.7),
              ),
              onPressed: _listen,
            ),
            Container(
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: themeManager.accentColor,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(
                  Icons.arrow_upward,
                  color: themeManager.backgroundColor,
                  size: 20,
                ),
                onPressed: _handleInput,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUtilityDock(ThemeManager themeManager) {
    return Row(
      key: const ValueKey('utility_dock'),
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          icon: Icon(
            Icons.close,
            color: themeManager.textColor.withValues(alpha: 0.5),
          ),
          onPressed: () {
            setState(() {
              _isUtilityExpanded = false;
            });
            Provider.of<ThemeManager>(context, listen: false).triggerHaptic();
          },
        ),
        IconButton(
          icon: Icon(Icons.camera_alt_outlined, color: themeManager.textColor),
          onPressed: () => _pickImage(ImageSource.camera),
        ),
        IconButton(
          icon: Icon(
            Icons.photo_library_outlined,
            color: themeManager.textColor,
          ),
          onPressed: () => _pickImage(ImageSource.gallery),
        ),
        IconButton(
          icon: Icon(Icons.folder_open, color: themeManager.textColor),
          onPressed: _pickFile,
        ),
        IconButton(
          icon: Icon(
            Icons.screen_share_outlined,
            color: themeManager.textColor,
          ),
          onPressed: _startScreenShare,
        ),
      ],
    );
  }

  Widget _buildExpandedChat(
    ThemeManager themeManager,
    ConnectionService connectionService,
  ) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutQuint,
      top: _isChatExpanded ? 0 : MediaQuery.of(context).size.height,
      bottom: 0,
      left: 0,
      right: 0,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            color: themeManager.currentThemeType == AppThemeType.oled
                ? Colors.black.withValues(alpha: 0.8)
                : themeManager.chatBackgroundColor.withValues(alpha: 0.9),
            child: Column(
              children: [
                // Chat Header
                SafeArea(
                  bottom: false,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: themeManager.accentColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: themeManager.accentColor.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                connectionService.masterModelMode == MasterModelMode.automatic 
                                    ? Icons.auto_awesome 
                                    : connectionService.masterModelMode == MasterModelMode.local 
                                        ? Icons.lan 
                                        : Icons.cloud,
                                size: 14,
                                color: themeManager.accentColor,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                connectionService.masterModelMode.name.toUpperCase(),
                                style: TextStyle(
                                  color: themeManager.accentColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 48), // Placeholder for floating button area
                      ],
                    ),
                  ),
                ),
                // Messages
                Expanded(
                  child: Stack(
                    children: [
                      ListView.builder(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        padding: const EdgeInsets.all(16),
                        itemCount: connectionService.messages.length,
                        itemBuilder: (context, index) {
                          final message = connectionService.messages[index];
                          final isLast =
                              index == connectionService.messages.length - 1;
                          final isStreaming =
                              connectionService.isTyping &&
                              isLast &&
                              message.role == MessageRole.ai;
                          return ChatBubble(
                            message: message,
                            isStreaming: isStreaming,
                          );
                        },
                      ),
                      Positioned(
                        top: 0,
                        right: 16,
                        child: FloatingActionButton(
                          mini: true,
                          backgroundColor: themeManager.accentColor.withValues(alpha: 0.9),
                          elevation: 8,
                          onPressed: () {
                            setState(() {
                              _isChatExpanded = false;
                              FocusScope.of(context).unfocus();
                            });
                            Provider.of<ThemeManager>(context, listen: false).triggerHaptic();
                          },
                          child: Icon(Icons.close, color: themeManager.backgroundColor, size: 20),
                        ),
                      ),
                      Positioned(
                        bottom: 16,
                        right: 16,
                        child: AnimatedScale(
                          scale: _showScrollToBottom ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOutBack,
                          child: FloatingActionButton(
                            mini: true,
                            heroTag: 'scrollToBottom',
                            backgroundColor: themeManager.accentColor
                                .withValues(alpha: 0.8),
                            elevation: 4,
                            onPressed: _scrollToBottom,
                            child: Icon(
                              Icons.keyboard_arrow_down,
                              color: themeManager.backgroundColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Chat Input for Expanded Mode
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  decoration: BoxDecoration(
                    color: themeManager.chatBackgroundColor,
                    border: Border(
                      top: BorderSide(
                        color: themeManager.textColor.withValues(alpha: 0.05),
                      ),
                    ),
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(scale: animation, child: child),
                      );
                    },
                    child: _isUtilityExpanded
                        ? _buildUtilityDock(themeManager)
                        : _buildDefaultInput(themeManager),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);
    final connectionService = Provider.of<ConnectionService>(context);

    // Auto-scroll when AI is typing if we're near the bottom
    if (connectionService.isTyping) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          final maxScroll = _scrollController.position.maxScrollExtent;
          if (maxScroll - _scrollController.offset <= 150) {
            _scrollController.jumpTo(maxScroll);
          }
        }
      });
    }

    return Stack(
      children: [
        // Background Aura
        if (themeManager.currentThemeType != AppThemeType.oled)
          Center(child: AnimatedAura(color: themeManager.auraColor)),

        // Main Content
        Column(
          children: [
            _buildSegmentedControl(themeManager),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) =>
                    setState(() => _currentSection = index),
                children: [
                  _buildProductivitySection(themeManager),
                  _buildControlCenterSection(themeManager),
                ],
              ),
            ),
          ],
        ),

        // Toast Chat Bar
        if (!_isChatExpanded) _buildChatBar(themeManager),

        // Expanded Chat Overlay
        _buildExpandedChat(themeManager, connectionService),
      ],
    );
  }
}
