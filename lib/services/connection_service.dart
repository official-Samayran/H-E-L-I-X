import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'base_connection_provider.dart';
import '../models/chat_message.dart';

class ConnectionService extends ChangeNotifier {
  final BaseConnectionProvider _baseProvider;
  
  bool _isLocalAvailable = false;
  bool _isCloudFallbackActive = true;
  bool _isTyping = false;
  final String _geminiApiKey = 'AIzaSyCrzv-CDamln-NEAsnOnchyo-UnZbAPUgA';
  
  final _storage = const FlutterSecureStorage();
  final List<ChatMessage> _messages = [];
  Timer? _pollingTimer;

  bool get isLocalAvailable => _isLocalAvailable;
  bool get isCloudFallbackActive => _isCloudFallbackActive;
  bool get isTyping => _isTyping;
  List<ChatMessage> get messages => List.unmodifiable(_messages);

  ConnectionService(this._baseProvider) {
    _initStorage();
    _startPolling();
  }

  Future<void> _initStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMessages = prefs.getStringList('chat_history') ?? [];
    
    if (savedMessages.isNotEmpty) {
      _messages.addAll(savedMessages.map((msg) => ChatMessage.fromJson(jsonDecode(msg))));
      notifyListeners();
    }
  }

  Future<void> _saveMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final serializedMessages = _messages.map((msg) => jsonEncode(msg.toJson())).toList();
    await prefs.setStringList('chat_history', serializedMessages);
  }

  Future<void> setGeminiApiKey(String key) async {
    // Legacy mapping: Not used, API key hardcoded
  }

  void _startPolling() {
    _checkConnections();
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _checkConnections();
    });
  }

  Future<bool> _isTailscaleActive() async {
    try {
      final interfaces = await NetworkInterface.list();
      for (var interface in interfaces) {
        if (interface.name.toLowerCase().contains('tailscale') || 
            interface.name.toLowerCase().contains('tun')) {
          return true;
        }
        for (var addr in interface.addresses) {
          if (addr.address.startsWith('100.')) {
            return true;
          }
        }
      }
    } catch (_) {}
    return false;
  }

  Future<void> _checkConnections() async {
    final ip = _baseProvider.hostIP;
    
    if (ip.startsWith('100.')) {
      if (!(await _isTailscaleActive())) {
        _handleStateChange(false);
        return;
      }
    }

    bool ollamaAvailable = await _pingPort(ip, 8080);
    bool helixAvailable = await _pingPort(ip, 8000);

    bool isNowAvailable = ollamaAvailable || helixAvailable;
    _handleStateChange(isNowAvailable);
  }

  void _handleStateChange(bool isNowAvailable) {
    bool wasLocalAvailable = _isLocalAvailable;
    _isLocalAvailable = isNowAvailable;
    _isCloudFallbackActive = !_isLocalAvailable;

    if (_isLocalAvailable != wasLocalAvailable) {
      if (_isLocalAvailable) {
        _syncContextToLocal();
      }
      notifyListeners();
    }
  }

  Future<bool> _pingPort(String host, int port) async {
    try {
      final socket = await Socket.connect(host, port, timeout: const Duration(seconds: 4));
      socket.destroy();
      return true;
    } catch (_) {
      return false;
    }
  }

  void addSystemMessage(String text) {
    _messages.add(ChatMessage(text: text, role: MessageRole.system, timestamp: DateTime.now()));
    _saveMessages();
    notifyListeners();
  }

  Future<void> sendMessage(String text) async {
    if (text.isEmpty) return;

    final userMessage = ChatMessage(
      text: text, 
      role: MessageRole.user, 
      timestamp: DateTime.now(),
      isOfflineContext: _isCloudFallbackActive,
    );
    _messages.add(userMessage);
    _saveMessages();
    notifyListeners();

    if (_isLocalAvailable) {
      await _sendToOllama(text);
    } else {
      await _sendToGemini(text);
    }
  }

  Future<void> _sendToOllama(String text) async {
    _isTyping = true;
    notifyListeners();
    try {
      final response = await http.post(
        Uri.parse(_baseProvider.ollamaUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'model': 'llama3',
          'prompt': text,
          'stream': false,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final aiText = data['response'] ?? '';
        _messages.add(ChatMessage(text: aiText, role: MessageRole.ai, timestamp: DateTime.now()));
        _saveMessages();
        notifyListeners();
      } else {
        addSystemMessage("Error: Ollama returned ${response.statusCode}");
      }
    } catch (e) {
      addSystemMessage("Connection Error: Could not reach Ollama.");
    } finally {
      _isTyping = false;
      notifyListeners();
    }
  }

  Future<void> _sendToGemini(String text) async {
    if (_geminiApiKey.isEmpty) {
      addSystemMessage("Error: Gemini API Key missing.");
      return;
    }

    _isTyping = true;
    notifyListeners();

    try {
      final uri = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${_geminiApiKey.trim()}');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [{'parts': [{'text': text}]}]
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('Gemini API Response: ${response.body}');
        final data = jsonDecode(response.body);
        final aiText = data['candidates'][0]['content']['parts'][0]['text'];
        _messages.add(ChatMessage(text: aiText, role: MessageRole.ai, timestamp: DateTime.now()));
        _saveMessages();
        notifyListeners();
      } else {
         addSystemMessage("Gemini Error: ${response.statusCode}");
      }
    } catch (e) {
       debugPrint('Gemini Exception: $e');
       addSystemMessage("Gemini Error: Could not connect to API.");
    } finally {
       _isTyping = false;
       notifyListeners();
    }
  }

  Future<void> _syncContextToLocal() async {
    final offlineMessages = _messages.where((m) => m.isOfflineContext && m.role == MessageRole.user).toList();
    
    if (offlineMessages.isEmpty) return;

    String combinedContext = offlineMessages.map((m) => m.text).join("\n");
    
    try {
      final response = await http.post(
        Uri.parse(_baseProvider.ollamaUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'model': 'llama3',
          'prompt': 'Context Sync - Received while Offline:\n$combinedContext',
          'stream': false,
        }),
      );
      
      if (response.statusCode == 200) {
        // Mark as synced, but modifying unmodifiable states means we just update memory and save
        for (var i = 0; i < _messages.length; i++) {
          if (_messages[i].isOfflineContext) {
            _messages[i] = ChatMessage(
              text: _messages[i].text,
              role: _messages[i].role,
              timestamp: _messages[i].timestamp,
              isOfflineContext: false,
            );
          }
        }
        _saveMessages();
      }
    } catch (e) {
      debugPrint('Context Sync Error: $e');
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }
}
