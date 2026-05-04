import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'base_connection_provider.dart';

class TelemetryData {
  final double cpu;
  final double ram;
  final double gpu;
  final double temp;
  final double disk;
  final double fanSpeed;
  final String topRamApp;
  final String topCpuApp;

  TelemetryData({
    this.cpu = 0,
    this.ram = 0,
    this.gpu = 0,
    this.temp = 0,
    this.disk = 0,
    this.fanSpeed = 0,
    this.topRamApp = "N/A",
    this.topCpuApp = "N/A",
  });

  factory TelemetryData.fromJson(Map<String, dynamic> json) {
    return TelemetryData(
      cpu: (json['cpu'] ?? 0).toDouble(),
      ram: (json['ram'] ?? 0).toDouble(),
      gpu: (json['gpu'] ?? 0).toDouble(),
      temp: (json['temp'] ?? 0).toDouble(),
      disk: (json['disk'] ?? 0).toDouble(),
      fanSpeed: (json['fanSpeed'] ?? 0).toDouble(),
      topRamApp: json['topRamApp'] ?? "N/A",
      topCpuApp: json['topCpuApp'] ?? "N/A",
    );
  }
}

class TelemetryService extends ChangeNotifier {
  final BaseConnectionProvider _baseProvider;
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _reconnectTimer;

  bool _isWsConnected = false;
  TelemetryData _currentData = TelemetryData();
  final List<TelemetryData> _history = [];

  bool get isWsConnected => _isWsConnected;
  TelemetryData get currentData => _currentData;
  List<TelemetryData> get history => List.unmodifiable(_history);

  TelemetryService(this._baseProvider) {
    _baseProvider.addListener(_onProviderChange);
    _connect();
  }

  void _onProviderChange() {
    _disconnect();
    _connect();
  }

  void _connect() {
    if (_isWsConnected) return;

    try {
      _channel = WebSocketChannel.connect(Uri.parse(_baseProvider.telemetryWsUrl));
      
      _channel?.ready.catchError((error) {
        _handleDisconnect();
      });

      _subscription = _channel?.stream.listen(
        (message) {
          if (!_isWsConnected) {
            _isWsConnected = true;
            notifyListeners();
          }
          final decoded = jsonDecode(message);
          _currentData = TelemetryData.fromJson(decoded);
          
          _history.add(_currentData);
          if (_history.length > 60) {
            _history.removeAt(0);
          }
          
          notifyListeners();
        },
        onError: (error) {
          _handleDisconnect();
        },
        onDone: () {
          _handleDisconnect();
        },
      );
    } catch (e) {
      _handleDisconnect();
    }
  }

  void _handleDisconnect() {
    if (_isWsConnected) {
      _isWsConnected = false;
      notifyListeners();
    }
    
    // Graceful Failure & Auto-Reconnect
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 4), () {
      _connect();
    });
  }

  void _disconnect() {
    _reconnectTimer?.cancel();
    _subscription?.cancel();
    _channel?.sink.close(status.goingAway);
    _isWsConnected = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _baseProvider.removeListener(_onProviderChange);
    _disconnect();
    super.dispose();
  }
}
