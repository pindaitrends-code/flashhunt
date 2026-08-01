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