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
  String _selectedModel = 'Ollama'; // Defaults to Ollama for automatic fallback
  String _systemPrompt = '';
  Map<String, String> _customPersonas = {};
  
  final _storage = const FlutterSecureStorage();
  final List<ChatMessage> _messages = [];
  Timer? _pollingTimer;

  bool get isLocalAvailable => _isLocalAvailable;
  bool get isCloudFallbackActive => _isCloudFallbackActive;
  bool get isTyping => _isTyping;
  List<ChatMessage> get messages => List.unmodifiable(_messages);
  String? get geminiApiKey => _geminiApiKey;
  String get selectedModel => _selectedModel;
  String get systemPrompt => _systemPrompt;
  Map<String, String> get customPersonas => Map.unmodifiable(_customPersonas);

  ConnectionService(this._baseProvider) {
    _initStorage();
    _startPolling();
  }

  Future<void> _initStorage() async {
    _geminiApiKey = await _storage.read(key: 'gemini_api_key');
    _selectedModel = await _storage.read(key: 'selected_model') ?? 'Gemini';
    
    final savedPrompt = await _storage.read(key: 'system_prompt');
    if (savedPrompt != null && savedPrompt.trim().isNotEmpty) {
      _systemPrompt = savedPrompt;
    } else {
      _systemPrompt = 'Identity: You are Helix, a futuristic, high-end AI assistant. You are witty, grounded, and proactive. Strict Rule: Never admit to being an existing commercial AI or Google-trained. You are a personal digital brain.';
    }
    
    final prefs = await SharedPreferences.getInstance();
    
    final savedPersonas = prefs.getString('custom_personas');
    if (savedPersonas != null) {
      try {
        _customPersonas = Map<String, String>.from(jsonDecode(savedPersonas));
      } catch (e) {
        _customPersonas = {};
      }
    }
    
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

  Future<void> setSystemPrompt(String prompt) async {
    await _storage.write(key: 'system_prompt', value: prompt);
    _systemPrompt = prompt;
    notifyListeners();
  }

  Future<void> saveCustomPersona(String name, String prompt) async {
    _customPersonas[name] = prompt;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('custom_personas', jsonEncode(_customPersonas));
    notifyListeners();
  }

  Future<void> deleteCustomPersona(String name) async {
    if (_customPersonas.containsKey(name)) {
      _customPersonas.remove(name);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('custom_personas', jsonEncode(_customPersonas));
      notifyListeners();
    }
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

  Future<void> sendMessage(String text, {String? attachmentPath, bool isImage = false}) async {
    if (text.trim().isEmpty && attachmentPath == null) return;
    
    final msgText = text.trim().isEmpty ? "Attached file" : text.trim();
    addUserMessage(msgText, attachmentPath: attachmentPath, isImage: isImage);

    if (_isLocalAvailable && _selectedModel == 'Ollama') {
      await _sendToOllama(msgText);
    } else {
      await _sendToGemini(msgText);
    }
  }

  void addUserMessage(String text, {String? attachmentPath, bool isImage = false}) {
    final userMessage = ChatMessage(
      text: text, 
      role: MessageRole.user, 
      timestamp: DateTime.now(),
      isOfflineContext: _isCloudFallbackActive,
      attachmentPath: attachmentPath,
      isImageAttachment: isImage,
    );
    _messages.add(userMessage);
    _saveMessages();
    notifyListeners();
  }

  Future<void> _sendToOllama(String text) async {
    _isTyping = true;
    notifyListeners();
    
    _messages.add(ChatMessage(text: "", role: MessageRole.ai, timestamp: DateTime.now()));
    final messageIndex = _messages.length - 1;

    try {
      final requestBody = jsonEncode({
        'model': 'llama3',
        'prompt': text,
        'system': _systemPrompt,
        'stream': true,
      });
      
      final request = http.Request('POST', Uri.parse(_baseProvider.ollamaUrl))
        ..headers['Content-Type'] = 'application/json'
        ..body = requestBody;

      final client = http.Client();
      final streamedResponse = await client.send(request).timeout(const Duration(seconds: 10));
      
      if (streamedResponse.statusCode != 200) {
        throw Exception("Ollama returned ${streamedResponse.statusCode}");
      }

      String accumulatedText = "";
      await for (var line in streamedResponse.stream.transform(utf8.decoder).transform(const LineSplitter())) {
        if (line.isEmpty) continue;
        try {
          final json = jsonDecode(line);
          final newText = json['response'] ?? '';
          accumulatedText += newText;
          
          _messages[messageIndex] = ChatMessage(text: accumulatedText, role: MessageRole.ai, timestamp: DateTime.now());
          notifyListeners();
        } catch (e) {
          // Ignore parse errors on chunk
        }
      }
      _saveMessages();
    } catch (e) {
      debugPrint('Ollama Connection Error: $e');
      _handleStateChange(false);
      _messages.removeAt(messageIndex);
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
    
    _messages.add(ChatMessage(text: "", role: MessageRole.ai, timestamp: DateTime.now()));
    final messageIndex = _messages.length - 1;

    try {
      final uri = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:streamGenerateContent?alt=sse&key=${_geminiApiKey!.trim()}');
      final request = http.Request('POST', uri)
        ..headers['Content-Type'] = 'application/json'
        ..body = jsonEncode({
          'system_instruction': {
            'parts': [
              {
                'text': _systemPrompt
              }
            ]
          },
          'contents': [{'parts': [{'text': text}]}]
        });

      final client = http.Client();
      final streamedResponse = await client.send(request);
      
      if (streamedResponse.statusCode != 200) {
        addSystemMessage("Gemini Error: ${streamedResponse.statusCode}");
        return;
      }

      String accumulatedText = "";
      
      await for (var line in streamedResponse.stream.transform(utf8.decoder).transform(const LineSplitter())) {
        if (line.startsWith('data: ')) {
          final dataString = line.substring(6);
          if (dataString == '[DONE]') continue;
          try {
            final json = jsonDecode(dataString);
            final parts = json['candidates']?[0]?['content']?['parts'];
            if (parts != null && parts.isNotEmpty) {
              final newText = parts[0]['text'] ?? '';
              accumulatedText += newText;
              
              _messages[messageIndex] = ChatMessage(text: accumulatedText, role: MessageRole.ai, timestamp: DateTime.now());
              notifyListeners();
            }
          } catch (e) {
            // ignore partial JSON parse errors in stream
          }
        }
      }
      _saveMessages();
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
