import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

class WebSocketMirrorService {
  static WebSocketChannel? _channel;
  static bool _isConnected = false;
  static Timer? _reconnectTimer;
  static final List<Function(Map<String, dynamic>)> _listeners = [];
  static int _reconnectAttempts = 0;
  static const int MAX_RECONNECT_ATTEMPTS = 10;
  
  static String _wsUrl = 'wss://echo.websocket.org';
  static bool _isEnabled = false;
  static bool _isMirrorMode = false;
  static const String DEFAULT_WS_URL = 'wss://echo.websocket.org';

  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _isEnabled = prefs.getBool('enable_websocket') ?? false;
    _isMirrorMode = prefs.getBool('enable_mirror_mode') ?? false;
    _wsUrl = prefs.getString('websocket_url') ?? DEFAULT_WS_URL;
    
    if (_isEnabled) {
      await connect();
    }
  }

  static Future<void> connect() async {
    if (_isConnected || !_isEnabled) return;
    
    try {
      print('🔄 Connecting to WebSocket: $_wsUrl');
      _channel = WebSocketChannel.connect(Uri.parse(_wsUrl));
      
      _channel!.stream.listen(
        (message) {
          _isConnected = true;
          _reconnectAttempts = 0;
          print('✅ WebSocket connected');
          
          final data = json.decode(message);
          if (!_isMirrorMode) {
            _handleIncomingMessage(data);
          }
        },
        onDone: () {
          _isConnected = false;
          print('⚠️ WebSocket disconnected');
          _scheduleReconnect();
        },
        onError: (error) {
          print('❌ WebSocket error: $error');
          _handleDisconnect();
        },
      );
    } catch (e) {
      print('❌ WebSocket connection failed: $e');
      _scheduleReconnect();
    }
  }

  static void _handleIncomingMessage(Map<String, dynamic> data) {
    print('📩 Server message: $data');
    for (final listener in _listeners) {
      listener(data);
    }
  }

  static void _handleDisconnect() {
    _isConnected = false;
    _scheduleReconnect();
  }

  static void _scheduleReconnect() {
    if (_reconnectAttempts >= MAX_RECONNECT_ATTEMPTS || !_isEnabled) {
      print('❌ Max reconnect attempts reached');
      return;
    }
    
    _reconnectAttempts++;
    final delay = Duration(seconds: _reconnectAttempts * 2);
    print('🔄 Reconnecting in ${delay.inSeconds}s...');
    
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () {
      connect();
    });
  }

  static Future<void> reconnect() async {
    disconnect();
    final prefs = await SharedPreferences.getInstance();
    _isEnabled = prefs.getBool('enable_websocket') ?? false;
    _isMirrorMode = prefs.getBool('enable_mirror_mode') ?? false;
    _wsUrl = prefs.getString('websocket_url') ?? DEFAULT_WS_URL;
    
    if (_isEnabled) {
      await connect();
    }
  }

  static Future<void> sendMessage(Map<String, dynamic> message) async {
    if (!_isEnabled) {
      print('⚠️ WebSocket disabled');
      return;
    }
    
    if (_isConnected && _channel != null) {
      try {
        _channel!.sink.add(json.encode(message));
        print('📤 Message sent');
      } catch (e) {
        print('⚠️ Send error: $e');
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
    _reconnectTimer?.cancel();
    if (_channel != null) {
      try {
        _channel!.sink.close();
      } catch (e) {
        print('⚠️ Disconnect error: $e');
      }
      _channel = null;
      _isConnected = false;
    }
  }

  static bool get isConnected => _isConnected && _isEnabled;
}