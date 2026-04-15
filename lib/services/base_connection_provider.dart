import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class BaseConnectionProvider extends ChangeNotifier {
  final _storage = const FlutterSecureStorage();
  
  String _hostIP = '100.117.245.88';
  String _pcName = 'Helix-PC';
  String _macAddress = '';

  String get hostIP => _hostIP;
  String get pcName => _pcName;
  String get macAddress => _macAddress;

  BaseConnectionProvider() {
    _loadConfigs();
  }

  Future<void> _loadConfigs() async {
    _hostIP = await _storage.read(key: 'host_ip') ?? '100.117.245.88';
    _pcName = await _storage.read(key: 'pc_name') ?? 'Helix-PC';
    _macAddress = await _storage.read(key: 'mac_address') ?? '';
    notifyListeners();
  }

  Future<void> saveConfigs(String ip, String name, String mac) async {
    _hostIP = ip;
    _pcName = name;
    _macAddress = mac;
    await _storage.write(key: 'host_ip', value: ip);
    await _storage.write(key: 'pc_name', value: name);
    await _storage.write(key: 'mac_address', value: mac);
    notifyListeners();
  }

  // Dynamic URI Formats
  String get ollamaUrl => 'http://$_hostIP:8080/api/generate';
  String get executeUrl => 'http://$_hostIP:8000/execute';
  String get telemetryWsUrl => 'ws://$_hostIP:8000/ws/stats';
}
