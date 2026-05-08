import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'base_connection_provider.dart';
import '../models/telemetry_model.dart';

class TelemetryService extends ChangeNotifier {
  final BaseConnectionProvider _baseProvider;
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;

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
      final wsUrl = 'ws://${_baseProvider.hostIP}:8000/ws/stats';
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      
      _channel?.ready.catchError((error) {
        _handleDisconnect();
      });

      _subscription = _channel?.stream.listen(
        (message) {
          _isWsConnected = true;
          _resetHeartbeat();
          
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

  void _resetHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer(const Duration(seconds: 3), () {
      if (_isWsConnected) {
        _isWsConnected = false;
        _currentData = TelemetryData(); // Clear metrics
        notifyListeners();
      }
    });
  }

  void _handleDisconnect() {
    if (_isWsConnected) {
      _isWsConnected = false;
      _currentData = TelemetryData(); // Clear metrics
      notifyListeners();
    }
    
    _heartbeatTimer?.cancel();
    
    // Auto-Reconnect
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 4), () {
      _connect();
    });
  }

  void _disconnect() {
    _reconnectTimer?.cancel();
    _heartbeatTimer?.cancel();
    _subscription?.cancel();
    _channel?.sink.close(status.goingAway);
    _isWsConnected = false;
    _currentData = TelemetryData();
    notifyListeners();
  }

  @override
  void dispose() {
    _baseProvider.removeListener(_onProviderChange);
    _disconnect();
    super.dispose();
  }
}
