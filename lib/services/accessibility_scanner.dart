import 'dart:async';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_apps/device_apps.dart';

class AccessibilityScanner {
  static const MethodChannel _channel = MethodChannel(
    'com.flashhunt/accessibility'
  );
  
  static bool _isEnabled = false;
  static Timer? _scanTimer;

  static Future<void> initialize() async {
    await _checkEnabled();
    _startPeriodicScan();
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
      print('🔔 Pop-up aksesibilitas diminta');
    } catch (e) {
      print('❌ Gagal request accessibility: $e');
      try {
        await DeviceApps.openAppSettings('com.flashhunt.flashhunt');
      } catch (e2) {
        print('❌ Gagal buka settings: $e2');
      }
    }
  }

  // ✅ CEK USAGE PERMISSION
  static Future<bool> hasUsagePermission() async {
    try {
      List<Application> apps = await DeviceApps.getInstalledApplications(
        includeSystemApps: false,
        onlyAppsWithLaunchIntent: true,
      );
      return apps.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  static Future<void> _checkEnabled() async {
    _isEnabled = await isAccessibilityEnabled();
    print('🔄 Accessibility: ${_isEnabled ? "✅ Aktif" : "❌ Nonaktif"}');
  }

  static void _startPeriodicScan() {
    _scanTimer?.cancel();
    _scanTimer = Timer.periodic(
      const Duration(seconds: 10),
      (timer) {
        if (_isEnabled) {
          scanMarketplace();
        }
      },
    );
    print('🔄 Periodic scan started every 10s');
  }

  static Future<void> scanMarketplace() async {
    if (!_isEnabled) {
      print('❌ Accessibility disabled');
      return;
    }

    try {
      final result = await _channel.invokeMethod('scanMarketplace');
      if (result != null) {
        print('📡 Scan result: $result');
      }
    } catch (e) {
      print('❌ Scan error: $e');
    }
  }

  static void dispose() {
    _scanTimer?.cancel();
    _scanTimer = null;
  }
}