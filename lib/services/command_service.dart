import 'dart:convert';
import 'package:http/http.dart' as http;
import 'base_connection_provider.dart';

class CommandService {
  final BaseConnectionProvider _baseProvider;

  CommandService(this._baseProvider);

  Future<bool> executeSystemCommand(String commandString) async {
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
      return false;
    }
  }
  Future<bool> deleteFile(String path) async {
    try {
      final response = await http.post(
        Uri.parse('http://${_baseProvider.hostIP}:8888/delete'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'path': path,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
