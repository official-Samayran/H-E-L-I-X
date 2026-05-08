import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'base_connection_provider.dart';
import '../models/chat_message.dart';

enum MasterModelMode { automatic, local, cloud }

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
  String _selectedModel = 'Helix'; // Defaults to Helix for automatic fallback
  String _helixSystemPrompt = '';
  String _conodeSystemPrompt = '';
  Map<String, String> _customPersonas = {};
  MasterModelMode _masterModelMode = MasterModelMode.automatic;
  
  final _storage = const FlutterSecureStorage();
  final List<ChatMessage> _messages = [];
  Timer? _pollingTimer;

  bool get isLocalAvailable => _isLocalAvailable;
  bool get isCloudFallbackActive => _isCloudFallbackActive;
  bool get isTyping => _isTyping;
  List<ChatMessage> get messages => List.unmodifiable(_messages);
  String? get geminiApiKey => _geminiApiKey;
  String get selectedModel => _selectedModel;
  String get helixSystemPrompt => _helixSystemPrompt;
  String get conodeSystemPrompt => _conodeSystemPrompt;
  Map<String, String> get customPersonas => Map.unmodifiable(_customPersonas);
  MasterModelMode get masterModelMode => _masterModelMode;

  ConnectionService(this._baseProvider) {
    _initStorage();
    _startPolling();
  }

  Future<void> _initStorage() async {
    _geminiApiKey = await _storage.read(key: 'gemini_api_key');
    _selectedModel = await _storage.read(key: 'selected_model') ?? 'Conode';
    
    final savedModeIndex = await _storage.read(key: 'master_model_mode');
    if (savedModeIndex != null) {
      _masterModelMode = MasterModelMode.values[int.parse(savedModeIndex)];
    }
    
    final savedHelixPrompt = await _storage.read(key: 'helix_system_prompt');
    if (savedHelixPrompt != null && savedHelixPrompt.trim().isNotEmpty) {
      _helixSystemPrompt = savedHelixPrompt;
    } else {
      _helixSystemPrompt = 'Identity: You are H E L I X, a futuristic, high-end AI assistant. You are witty, grounded, and proactive. Strict Rule: Never admit to being an existing commercial AI or Google-trained. You are a personal digital brain. '
          'You are a Flutter Developer AI. To perform terminal actions, use this tag: [EXECUTE:command_here] Example: To install dependencies, use [EXECUTE:flutter pub get]. Always navigate to the correct project directory before running commands if needed. '
          'When asked to "Run" the app, use: [EXECUTE:flutter run -d windows]. '
          'You can also perform these actions:\n'
          '1. To write a file: [WRITE:path/to/file]CONTENT_HERE[/WRITE]\n'
          '2. To execute a command: [EXECUTE:command_here]\n'
          '3. To read a file: [READ:path/to/file]\n'
          '4. To delete a file: [DELETE:path]\n'
          '5. To list files in workspace: [LIST_FILES:path]. Use this to understand project structure before writing code.\n'
          'Your workspace is restricted to E:\\Helix_Projects. Always use full paths within this directory.';
    }

    final savedConodePrompt = await _storage.read(key: 'conode_system_prompt');
    if (savedConodePrompt != null && savedConodePrompt.trim().isNotEmpty) {
      _conodeSystemPrompt = savedConodePrompt;
    } else {
      _conodeSystemPrompt = 'Identity: You are CONODE, a powerful cloud-assisted AI helper. You are efficient, analytical, and supportive. '
          'You are a Flutter Developer AI. To perform terminal actions, use this tag: [EXECUTE:command_here] Example: To install dependencies, use [EXECUTE:flutter pub get]. Always navigate to the correct project directory before running commands if needed. '
          'When asked to "Run" the app, use: [EXECUTE:flutter run -d windows]. '
          'You can also perform these actions:\n'
          '1. To write a file: [WRITE:path/to/file]CONTENT_HERE[/WRITE]\n'
          '2. To execute a command: [EXECUTE:command_here]\n'
          '3. To read a file: [READ:path/to/file]\n'
          '4. To delete a file: [DELETE:path]\n'
          '5. To list files in workspace: [LIST_FILES:path]. Use this to understand project structure before writing code.\n'
          'Your workspace is restricted to E:\\Helix_Projects. Always use full paths within this directory.';
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

  Future<void> setMasterModelMode(MasterModelMode mode) async {
    await _storage.write(key: 'master_model_mode', value: mode.index.toString());
    _masterModelMode = mode;
    notifyListeners();
  }

  Future<void> setHelixSystemPrompt(String prompt) async {
    await _storage.write(key: 'helix_system_prompt', value: prompt);
    _helixSystemPrompt = prompt;
    notifyListeners();
  }

  Future<void> setConodeSystemPrompt(String prompt) async {
    await _storage.write(key: 'conode_system_prompt', value: prompt);
    _conodeSystemPrompt = prompt;
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

    bool helixPortAvailable = await _pingPort(ip, 11434);
    bool agentAvailable = await _pingPort(ip, 8000);

    bool isNowAvailable = helixPortAvailable || agentAvailable;
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

  Future<bool> sendPCCommand(String commandString) async {
    try {
      final response = await http.post(
        Uri.parse(_baseProvider.executeUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'command': commandString,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("PC Command failed: $e");
      return false;
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

  void addHiddenSystemMessage(String text) {
    _messages.add(ChatMessage(
      text: text, 
      role: MessageRole.system, 
      timestamp: DateTime.now(),
      isHidden: true,
    ));
    _saveMessages();
    notifyListeners();
  }

  Future<void> sendMessage(String text, {String? attachmentPath, bool isImage = false}) async {
    if (text.trim().isEmpty && attachmentPath == null) return;
    
    final msgText = text.trim().isEmpty ? "Attached file" : text.trim();
    addUserMessage(msgText, attachmentPath: attachmentPath, isImage: isImage);

    switch (_masterModelMode) {
      case MasterModelMode.automatic:
        if (_isLocalAvailable) {
          await _sendToHelix(msgText);
        } else {
          await _sendToConode(msgText);
        }
        break;
      case MasterModelMode.local:
        if (_isLocalAvailable) {
          await _sendToHelix(msgText);
        } else {
          addSystemMessage("H E L I X is currently offline.");
          // No fallback
        }
        break;
      case MasterModelMode.cloud:
        await _sendToConode(msgText);
        break;
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

  Future<void> _sendToHelix(String text) async {
    _isTyping = true;
    notifyListeners();
    
    _messages.add(ChatMessage(text: "", role: MessageRole.ai, timestamp: DateTime.now(), modelName: "H E L I X"));
    final messageIndex = _messages.length - 1;

    try {
      final requestBody = jsonEncode({
        'model': 'llama3',
        'prompt': text,
        'system': _helixSystemPrompt,
        'stream': true,
      });
      
      final request = http.Request('POST', Uri.parse(_baseProvider.ollamaUrl))
        ..headers['Content-Type'] = 'application/json'
        ..body = requestBody;

      final client = http.Client();
      final streamedResponse = await client.send(request).timeout(const Duration(seconds: 10));
      
      if (streamedResponse.statusCode != 200) {
        throw Exception("H E L I X returned ${streamedResponse.statusCode}");
      }

      String accumulatedText = "";
      await for (var line in streamedResponse.stream.transform(utf8.decoder).transform(const LineSplitter())) {
        if (line.isEmpty) continue;
        try {
          final json = jsonDecode(line);
          final newText = json['response'] ?? '';
          accumulatedText += newText;
          
          _messages[messageIndex] = ChatMessage(text: accumulatedText, role: MessageRole.ai, timestamp: DateTime.now(), modelName: "H E L I X");
          notifyListeners();
        } catch (e) {
          // Ignore parse errors on chunk
        }
      }
      _saveMessages();
      await _processAITags(accumulatedText);
    } catch (e) {
      debugPrint('H E L I X Connection Error: $e');
      _handleStateChange(false);
      _messages.removeAt(messageIndex);
      
      if (_masterModelMode == MasterModelMode.automatic) {
        addSystemMessage("H E L I X offline/timeout. Falling back to CONODE...");
        await _sendToConode(text); // Fallback
      } else {
        addSystemMessage("H E L I X is currently offline.");
      }
    } finally {
      _isTyping = false;
      notifyListeners();
    }
  }

  Future<void> _sendToConode(String text) async {
    if (_geminiApiKey == null || _geminiApiKey!.trim().isEmpty) {
      addSystemMessage("Error: CONODE API Key missing. Please update in Settings.");
      return;
    }

    _isTyping = true;
    notifyListeners();
    
    _messages.add(ChatMessage(text: "", role: MessageRole.ai, timestamp: DateTime.now(), modelName: "CONODE"));
    final messageIndex = _messages.length - 1;

    try {
      final uri = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:streamGenerateContent?alt=sse&key=${_geminiApiKey!.trim()}');
      final request = http.Request('POST', uri)
        ..headers['Content-Type'] = 'application/json'
        ..body = jsonEncode({
          'system_instruction': {
            'parts': [
              {
                'text': _conodeSystemPrompt
              }
            ]
          },
          'contents': [{'parts': [{'text': text}]}]
        });

      final client = http.Client();
      final streamedResponse = await client.send(request);
      
      if (streamedResponse.statusCode == 429) {
        addSystemMessage("CONODE API Rate Limit Exceeded (429). Please wait a moment before trying again.");
        _messages.removeAt(messageIndex);
        return;
      } else if (streamedResponse.statusCode != 200) {
        addSystemMessage("CONODE Error: ${streamedResponse.statusCode}");
        _messages.removeAt(messageIndex);
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
              
              _messages[messageIndex] = ChatMessage(text: accumulatedText, role: MessageRole.ai, timestamp: DateTime.now(), modelName: "CONODE");
              notifyListeners();
            }
          } catch (e) {
            // ignore partial JSON parse errors in stream
          }
        }
      }
      _saveMessages();
      await _processAITags(accumulatedText);
    } catch (e) {
       addSystemMessage("CONODE Error: Could not connect to API.");
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

  Future<void> _processAITags(String text) async {
    debugPrint("🔍 Starting AI Tag Processing...");
    
    final writeRegex = RegExp(r'\[WRITE:(.*?)\](.*?)\[/WRITE\]', dotAll: true);
    final executeRegex = RegExp(r'\[EXECUTE:(.*?)\]');
    final readRegex = RegExp(r'\[READ:(.*?)\]');
    final deleteRegex = RegExp(r'\[DELETE:(.*?)\]');
    final listRegex = RegExp(r'\[LIST_FILES:(.*?)\]');

    // Handle LIST_FILES tags
    final listMatches = listRegex.allMatches(text);
    for (var match in listMatches) {
      final path = match.group(1);
      if (path != null) {
        debugPrint("📂 Step: Found LIST_FILES tag for $path");
        await _handlePCAgentRequest('list', {'path': path}, isListRequest: true);
      }
    }

    // Handle READ tags
    final readMatches = readRegex.allMatches(text);
    for (var match in readMatches) {
      final path = match.group(1);
      if (path != null) {
        debugPrint("📁 Step: Found READ tag for $path");
        await _handlePCAgentRequest('read', {'path': path});
      }
    }

    // Handle WRITE tags
    final writeMatches = writeRegex.allMatches(text);
    for (var match in writeMatches) {
      final path = match.group(1);
      final content = match.group(2);
      if (path != null && content != null) {
        debugPrint("📝 Step: Found WRITE tag for $path");
        await _handlePCAgentRequest('write', {'path': path, 'content': content});
      }
    }

    // Handle DELETE tags
    final deleteMatches = deleteRegex.allMatches(text);
    for (var match in deleteMatches) {
      final path = match.group(1);
      if (path != null) {
        debugPrint("🗑️ Step: Found DELETE tag for $path");
        await _handlePCAgentRequest('delete', {'path': path});
      }
    }

    // Handle EXECUTE tags
    final executeMatches = executeRegex.allMatches(text);
    for (var match in executeMatches) {
      final command = match.group(1);
      if (command != null) {
        debugPrint("⚡ Step: Found EXECUTE tag: $command");
        await _handlePCAgentRequest('execute', {'command': command});
      }
    }
    
    debugPrint("🏁 Tag Processing Finished.");
  }

  Future<void> _handlePCAgentRequest(String endpoint, Map<String, dynamic> payload, {bool isListRequest = false}) async {
    final ip = _baseProvider.hostIP;
    
    // Task 2: IP Verification Logic
    if (ip.isEmpty || ip == '0.0.0.0') {
      addSystemMessage("⚠️ Error: PC IP not configured in settings.");
      debugPrint("⚠️ PC Agent Request Blocked: IP is null/empty.");
      return;
    }

    final url = 'http://$ip:8888/$endpoint';
    
    // Task 1.2: BEFORE sending
    if (endpoint == 'execute') {
      addSystemMessage("🛠️ H E L I X: Executing terminal command...");
    } else if (endpoint == 'delete') {
      addSystemMessage("🗑️ H E L I X: Deleting file...");
    } else if (isListRequest) {
      addSystemMessage("🔍 H E L I X: Mapping project structure...");
    } else {
      addSystemMessage("📡 Sending request to PC Agent ($endpoint)...");
    }
    
    debugPrint("📡 Step: Sending HTTP POST to $url");

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 10));

      // Task 1.2: IF SUCCESS (200 OK)
      if (response.statusCode == 200) {
        if (isListRequest) {
          addHiddenSystemMessage("📁 Workspace Structure for ${payload['path']}:\n${response.body}");
          addSystemMessage("✅ H E L I X has indexed the directory: ${payload['path']}");
        } else {
          addSystemMessage("✅ H E L I X: Operation completed successfully.");
        }
        debugPrint("✅ Step: 200 OK from PC Agent.");
      } else {
        // Task 1.2: IF FAIL (Error code)
        addSystemMessage("❌ H E L I X Error: PC Agent returned ${response.statusCode}");
        debugPrint("❌ Step: Error ${response.statusCode} from PC Agent.");
      }
    } catch (e) {
      // Task 1.2: IF TIMEOUT/CONNECTION REFUSED
      addSystemMessage("🚫 H E L I X Error: Connection to PC Agent failed.");
      debugPrint("🚫 Step: Connection Failed - $e");
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }
}
