import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'services/storage_service.dart';
import 'services/websocket_mirror.dart';
import 'services/notification_listener.dart';
import 'services/accessibility_scanner.dart';
import 'services/webhook_service.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await _requestAllPermissions();
  
  await StorageService.initialize();
  await NotificationListenerService.initialize();
  await AccessibilityScanner.initialize();
  await WebSocketMirrorService.initialize();
  
  runApp(const MyApp());
}

Future<void> _requestAllPermissions() async {
  // 1️⃣ NOTIFIKASI
  await Permission.notification.request();
  
  // 2️⃣ SYSTEM ALERT WINDOW
  if (await Permission.systemAlertWindow.isDenied) {
    await Permission.systemAlertWindow.request();
  }
  
  // 3️⃣ SCHEDULE EXACT ALARM
  await Permission.scheduleExactAlarm.request();
  
  // 4️⃣ AKSESIBILITAS - LANGSUNG POP-UP!
  try {
    final bool isEnabled = await AccessibilityScanner.isAccessibilityEnabled();
    if (!isEnabled) {
      print('🔔 Meminta izin aksesibilitas...');
      await AccessibilityScanner.requestAccessibility();
    } else {
      print('✅ Aksesibilitas sudah aktif');
    }
  } catch (e) {
    print('❌ Gagal request aksesibilitas: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FlashHunt',
      theme: ThemeData(
        primarySwatch: Colors.red,
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
      routes: {
        '/settings': (context) => const SettingsScreen(),
      },
    );
  }
}