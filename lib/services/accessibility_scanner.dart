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

  // ✅ DETEKSI APLIKASI FOREGROUND VIA AKSESIBILITAS
  static Future<String?> getForegroundApp() async {
    try {
      final result = await _channel.invokeMethod('getForegroundApp');
      return result as String?;
    } catch (e) {
      print('❌ Error get foreground app: $e');
      return null;
    }
  }

  // ✅ SCAN MARKETPLACE
  static Future<void> scanMarketplace() async {
    if (!_isEnabled) {
      print('❌ Accessibility disabled');
      return;
    }

    try {
      final result = await _channel.invokeMethod('scanMarketplace');
      if (result != null) {
        print('📡 Scan result: $result');
        
        // ✅ DETEKSI FLASH SALE DARI SCAN
        final Map<String, dynamic> data = result as Map<String, dynamic>;
        if (data.containsKey('isFlashSale') && data['isFlashSale'] == true) {
          print('🔥 FLASH SALE DETECTED via Accessibility!');
          // Kirim notifikasi ke user
          // Kirim ke WebSocket
          // Kirim ke Webhook
        }
      }
    } catch (e) {
      print('❌ Scan error: $e');
    }
  }

  // ✅ CEK APAKAH MARKETPLACE TERBUKA
  static Future<bool> isMarketplaceOpen() async {
    final String? foregroundApp = await getForegroundApp();
    if (foregroundApp == null) return false;
    
    final List<String> marketplaces = [
      'com.shopee',
      'com.tokopedia',
      'com.lazada',
      'com.blibli',
      'com.tiktok',
      'com.amazon',
    ];
    
    return marketplaces.any((pkg) => foregroundApp.contains(pkg));
  }

  static Future<void> _checkEnabled() async {
    _isEnabled = await isAccessibilityEnabled();
    print('🔄 Accessibility: ${_isEnabled ? "✅ Aktif" : "❌ Nonaktif"}');
  }

  static void _startPeriodicScan() {
    _scanTimer?.cancel();
    _scanTimer = Timer.periodic(
      const Duration(seconds: 10),
      (timer) async {
        if (_isEnabled) {
          // Cek apakah marketplace terbuka
          bool isOpen = await isMarketplaceOpen();
          if (isOpen) {
            print('🛒 Marketplace sedang terbuka, scanning...');
            await scanMarketplace();
          }
        }
      },
    );
    print('🔄 Periodic scan started every 10s');
  }

  static void dispose() {
    _scanTimer?.cancel();
    _scanTimer = null;
  }
}