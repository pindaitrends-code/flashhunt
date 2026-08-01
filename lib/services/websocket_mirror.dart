import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';
import 'dart:async';

class WebSocketMirrorService {
  static WebSocketChannel? _channel;
  static bool _isConnected = false;
  static final List<Function(Map<String, dynamic>)> _listeners = [];

  static const String WS_URL = 'wss://echo.websocket.org';

  static Future<void> initialize() async {
    await connect();
  }

  static Future<void> connect() async {
    try {
      _channel = WebSocketChannel.connect(Uri.parse(WS_URL));
      _channel!.stream.listen(
        (message) {
          _isConnected = true;
          final data = json.decode(message);
          for (final listener in _listeners) {
            listener(data);
          }
        },
        onDone: () {
          _isConnected = false;
        },
        onError: (error) {
          print('WebSocket error: $error');
        },
      );
    } catch (e) {
      print('WebSocket connection failed: $e');
    }
  }

  static Future<void> sendMessage(Map<String, dynamic> message) async {
    if (_isConnected && _channel != null) {
      try {
        _channel!.sink.add(json.encode(message));
      } catch (e) {
        print('Send error: $e');
      }
    }
  }

  static void addListener(Function(Map<String, dynamic>) listener) {
    _listeners.add(listener);
  }

  static void removeListener(Function(Map<String, dynamic>) listener) {
    _listeners.remove(listener);
  }

  static void disconnect() {
    if (_channel != null) {
      _channel!.sink.close();
      _channel = null;
      _isConnected = false;
    }
  }

  static bool get isConnected => _isConnected;
}