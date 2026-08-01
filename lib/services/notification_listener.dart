import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/notification_model.dart';
import 'websocket_mirror.dart';

class NotificationListenerService {
  static FlutterLocalNotificationsPlugin? _notifications;

  static final List<String> KEYWORDS = [
    'flash sale', 'diskon', 'promo', 'murah', 'obral', 'gratis',
    'potongan', 'sale', 'discount'
  ];

  static final Map<String, String> PLATFORM_MAP = {
    'com.shopee': 'Shopee',
    'com.tokopedia': 'Tokopedia',
    'com.lazada': 'Lazada',
    'com.blibli': 'Blibli',
    'com.tiktok': 'TikTok',
    'com.amazon': 'Amazon',
  };

  static Future<void> initialize() async {
    _notifications = FlutterLocalNotificationsPlugin();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(android: androidInit, iOS: iosInit);
    await _notifications!.initialize(initSettings);
  }

  static Future<void> processNotification(NotificationModel notification) async {
    final bool isFlashSale = detectFlashSale(notification);

    if (isFlashSale) {
      await _showLocalNotification(notification);
      await WebSocketMirrorService.sendMessage({
        'type': 'flash_sale_detected',
        'data': notification.toJson(),
      });
      await _saveToHistory(notification);
    }
  }

  static bool detectFlashSale(NotificationModel notification) {
    final String text = '${notification.title} ${notification.content}'.toLowerCase();
    for (final keyword in KEYWORDS) {
      if (text.contains(keyword)) return true;
    }
    return false;
  }

  static Future<void> _showLocalNotification(NotificationModel notification) async {
    const androidDetails = AndroidNotificationDetails(
      'flash_sale_channel',
      'FlashHunt Detector',
      channelDescription: 'Notifikasi flash sale terdeteksi',
      importance: Importance.max,
      priority: Priority.high,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);
    final platform = PLATFORM_MAP[notification.packageName] ?? 'Marketplace';

    await _notifications!.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      '🔥 Flash Sale di $platform!',
      notification.content,
      details,
    );
  }

  static Future<void> _saveToHistory(NotificationModel notification) async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList('flash_sale_history') ?? [];

    history.add(json.encode({
      'title': notification.title,
      'content': notification.content,
      'platform': PLATFORM_MAP[notification.packageName] ?? 'Unknown',
      'timestamp': notification.timestamp.toIso8601String(),
    }));

    await prefs.setStringList('flash_sale_history', history);
  }
}