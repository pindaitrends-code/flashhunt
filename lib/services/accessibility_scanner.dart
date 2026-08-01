import 'dart:async';
import 'package:flutter/services.dart';

class AccessibilityScanner {
  static const MethodChannel _channel = MethodChannel(
    'com.flashhunt/accessibility'
  );
  
  static bool _isEnabled = false;

  static Future<void> initialize() async {
    await _checkEnabled();
  }

  static Future<bool> isAccessibilityEnabled() async {
    try {
      final result = await _channel.invokeMethod('isAccessibilityEnabled');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  static Future<void> requestAccessibility() async {
    try {
      await _channel.invokeMethod('requestAccessibility');
    } catch (e) {
      print('Gagal request accessibility: $e');
    }
  }

  static Future<void> _checkEnabled() async {
    _isEnabled = await isAccessibilityEnabled();
    print('Accessibility: ${_isEnabled ? "Aktif" : "Nonaktif"}');
  }

  static Future<void> scanMarketplace() async {
    if (!_isEnabled) return;

    try {
      final result = await _channel.invokeMethod('scanMarketplace');
      if (result != null) {
        print('Scan result: $result');
      }
    } catch (e) {
      print('Scan error: $e');
    }
  }
}