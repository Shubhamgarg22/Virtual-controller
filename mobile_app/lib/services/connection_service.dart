import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ConnectionStatus {
  disconnected,
  connecting,
  connected,
  error,
}

class ConnectionService extends ChangeNotifier {
  WebSocketChannel? _channel;
  ConnectionStatus _status = ConnectionStatus.disconnected;
  String _errorMessage = '';
  String _lastIpAddress = '';
  Timer? _pingTimer;
  Timer? _reconnectTimer;

  ConnectionStatus get status => _status;
  String get errorMessage => _errorMessage;
  String get lastIpAddress => _lastIpAddress;
  bool get isConnected => _status == ConnectionStatus.connected;

  ConnectionService() {
    _loadLastIpAddress();
  }

  Future<void> _loadLastIpAddress() async {
    final prefs = await SharedPreferences.getInstance();
    _lastIpAddress = prefs.getString('last_ip_address') ?? '';
    notifyListeners();
  }

  Future<void> _saveLastIpAddress(String ip) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_ip_address', ip);
    _lastIpAddress = ip;
  }

  Future<void> connect(String ipAddress, {int port = 8765}) async {
    if (_status == ConnectionStatus.connecting) return;

    _status = ConnectionStatus.connecting;
    _errorMessage = '';
    notifyListeners();

    try {
      final uri = Uri.parse('ws://$ipAddress:$port');
      _channel = WebSocketChannel.connect(uri);

      // Wait for connection to be established
      await _channel!.ready;

      _status = ConnectionStatus.connected;
      _errorMessage = '';
      await _saveLastIpAddress(ipAddress);

      // Start ping timer to keep connection alive
      _startPingTimer();

      // Listen for messages
      _channel!.stream.listen(
        (message) {
          _handleMessage(message);
        },
        onError: (error) {
          _handleError('Connection error: $error');
        },
        onDone: () {
          _handleDisconnect();
        },
      );

      notifyListeners();
    } catch (e) {
      _status = ConnectionStatus.error;
      _errorMessage = 'Failed to connect: ${e.toString()}';
      notifyListeners();
    }
  }

  void _handleMessage(dynamic message) {
    try {
      final data = json.decode(message);
      if (data['type'] == 'pong') {
        // Connection is alive
      }
    } catch (e) {
      debugPrint('Error handling message: $e');
    }
  }

  void _handleError(String error) {
    _status = ConnectionStatus.error;
    _errorMessage = error;
    _stopPingTimer();
    notifyListeners();
  }

  void _handleDisconnect() {
    _status = ConnectionStatus.disconnected;
    _stopPingTimer();
    notifyListeners();
  }

  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      sendPing();
    });
  }

  void _stopPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = null;
  }

  void sendPing() {
    send({'type': 'ping'});
  }

  void disconnect() {
    _stopPingTimer();
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
    _status = ConnectionStatus.disconnected;
    notifyListeners();
  }

  void send(Map<String, dynamic> data) {
    if (_channel != null && _status == ConnectionStatus.connected) {
      try {
        _channel!.sink.add(json.encode(data));
      } catch (e) {
        debugPrint('Error sending message: $e');
      }
    }
  }

  // Mouse control methods
  void sendMouseMove(double dx, double dy) {
    send({
      'type': 'mouse_move',
      'dx': dx.round(),
      'dy': dy.round(),
    });
  }

  void sendMouseClick({String button = 'left', int clicks = 1}) {
    send({
      'type': 'mouse_click',
      'button': button,
      'clicks': clicks,
    });
  }

  void sendMouseScroll(double dx, double dy) {
    send({
      'type': 'mouse_scroll',
      'dx': dx.round(),
      'dy': dy.round(),
    });
  }

  void sendDragStart() {
    send({'type': 'mouse_drag_start'});
  }

  void sendDragEnd() {
    send({'type': 'mouse_drag_end'});
  }

  // Keyboard control methods
  void sendKeyPress(String key) {
    send({
      'type': 'key_press',
      'key': key,
    });
  }

  void sendKeyRelease(String key) {
    send({
      'type': 'key_release',
      'key': key,
    });
  }

  void sendKeyTap(String key) {
    send({
      'type': 'key_tap',
      'key': key,
    });
  }

  void sendTextInput(String text) {
    send({
      'type': 'text_input',
      'text': text,
    });
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}
