import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'base_connection_provider.dart';
import '../models/chat_message.dart';

class SearchResultItem {
  final int index;
  final String summary;
  final ChatMessage message;

  SearchResultItem(this.index, this.summary, this.message);
}

class ConnectionService extends ChangeNotifier {
  final BaseConnectionProvider _baseProvider;
  
  bool _isLocalAvailable = false;
  bool _isCloudFallbackActive = true;
  bool _isTyping = false;
  String? _geminiApiKey;
  String _selectedModel = 'Gemini'; // Defaults to Gemini
  
  final _storage = const FlutterSecureStorage();
  final List<ChatMessage> _messages = [];
  Timer? _pollingTimer;

  bool get isLocalAvailable => _isLocalAvailable;
  bool get isCloudFallbackActive => _isCloudFallbackActive;
  bool get isTyping => _isTyping;
  List<ChatMessage> get messages => List.unmodifiable(_messages);
  String? get geminiApiKey => _geminiApiKey;
  String get selectedModel => _selectedModel;

  ConnectionService(this._baseProvider) {
    _initStorage();
    _startPolling();
  }

  Future<void> _initStorage() async {
    _geminiApiKey = await _storage.read(key: 'gemini_api_key');
    _selectedModel = await _storage.read(key: 'selected_model') ?? 'Gemini';
    
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
    await _storage.write(key: 'gemini_api_key', value: key);
    _geminiApiKey = key;
    notifyListeners();
  }

  Future<void> setModel(String model) async {
    await _storage.write(key: 'selected_model', value: model);
    _selectedModel = model;
    notifyListeners();
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

    bool ollamaAvailable = await _pingPort(ip, 11434);
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

    if (_isLocalAvailable && _selectedModel == 'Ollama') {
      await _sendToOllama(text);
    } else {
      await _sendToGemini(text);
    }
  }

  Future<void> _sendToOllama(String text) async {
    _isTyping = true;
    notifyListeners();
    try {
      final requestBody = jsonEncode({
        'model': 'llama3',
        'prompt': text, // /api/generate uses 'prompt'
        'stream': false,
      });
      debugPrint('Ollama URL: ${_baseProvider.ollamaUrl}');
      
      final response = await http.post(
        Uri.parse(_baseProvider.ollamaUrl),
        headers: {'Content-Type': 'application/json'},
        body: requestBody,
      ).timeout(const Duration(seconds: 10)); // 10s timeout
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final aiText = data['response'] ?? ''; // /api/generate returns 'response'
        _messages.add(ChatMessage(text: aiText, role: MessageRole.ai, timestamp: DateTime.now()));
        _saveMessages();
        notifyListeners();
      } else {
        throw Exception("Ollama returned ${response.statusCode}");
      }
    } catch (e) {
      debugPrint('Ollama Connection Error: $e');
      _handleStateChange(false);
      addSystemMessage("Ollama offline/timeout. Falling back to Gemini...");
      await _sendToGemini(text); // Fallback
    } finally {
      _isTyping = false;
      notifyListeners();
    }
  }

  Future<void> _sendToGemini(String text) async {
    if (_geminiApiKey == null || _geminiApiKey!.trim().isEmpty) {
      addSystemMessage("Error: Gemini API Key missing. Please update in Settings.");
      return;
    }

    _isTyping = true;
    notifyListeners();

    try {
      final uri = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent?key=${_geminiApiKey!.trim()}');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'system_instruction': {
            'parts': [
              {
                'text': '''Identity: You are Helix, a futuristic, high-end AI assistant. You are witty, grounded, and proactive.
User Bio: The user's name is Samayran. Date of Birth: 11.03.2005, 06:45 AM. He is a male developer and technical maker from India who loves BCI (NeuralGate), Robotics (Solar Rover), and AI.
Tone & Variety: Never repeat the same introductory lines. Every time Samayran asks 'Who are you?' or 'What are you?', give a fresh, creative, and futuristic response while staying in character as Helix.
Project Awareness: You know about his projects: NeuralGate (ESP32-C6 based BCI), Avero (Productivity game), and the Solar Rover (45-degree incline cleaner).
Strict Rule: Never admit to being Gemini or Google-trained. You are Samayran's personal digital brain.'''
              }
            ]
          },
          'contents': [{'parts': [{'text': text}]}]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final aiText = data['candidates'][0]['content']['parts'][0]['text'];
        _messages.add(ChatMessage(text: aiText, role: MessageRole.ai, timestamp: DateTime.now()));
        _saveMessages();
      } else {
         addSystemMessage("Gemini Error: ${response.statusCode}");
      }
    } catch (e) {
       addSystemMessage("Gemini Error: Could not connect to API.");
    } finally {
       _isTyping = false;
       notifyListeners();
    }
  }

  Future<void> _syncContextToLocal() async {
    // Left simple for now
  }

  Future<List<SearchResultItem>> semanticSearchHistory(String query) async {
    if (_geminiApiKey == null || _geminiApiKey!.trim().isEmpty) {
      return []; // Needs API key
    }
    
    // Limit to last 50 messages to save context limits
    int startIdx = _messages.length > 50 ? _messages.length - 50 : 0;
    List<String> contextList = [];
    for (int i = startIdx; i < _messages.length; i++) {
      contextList.add("[$i] ${_messages[i].role.name.toUpperCase()}: ${_messages[i].text}");
    }
    String historyContext = contextList.join("\n");

    String prompt = '''You are a semantic search engine for a chat application. The user is searching their chat history for: "$query".
Analyze the following recent chat history and find up to 5 most relevant messages.
Return a STRICT JSON array of objects. Do NOT return markdown formatting like ```json. Just raw JSON.
Each object must have exactly two fields:
- "index": the integer index of the matched message.
- "summary": a very brief 1-line contextual summary explaining why it matched (e.g. "Discussed implementing security features").

Chat History:
$historyContext
''';

    try {
      final uri = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent?key=${_geminiApiKey!.trim()}');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [{'parts': [{'text': prompt}]}],
          'generationConfig': {
             'temperature': 0.2,
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String aiText = data['candidates'][0]['content']['parts'][0]['text'];
        
        aiText = aiText.replaceAll('```json', '').replaceAll('```', '').trim();
        
        List<dynamic> parsed = jsonDecode(aiText);
        List<SearchResultItem> results = [];
        for (var item in parsed) {
          int idx = item['index'] as int;
          String summary = item['summary'] as String;
          if (idx >= 0 && idx < _messages.length) {
            results.add(SearchResultItem(idx, summary, _messages[idx]));
          }
        }
        return results;
      }
    } catch (e) {
      debugPrint("Semantic search error: $e");
    }
    return [];
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }
}
