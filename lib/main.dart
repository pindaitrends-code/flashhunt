import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Permission.notification.request();
  await Permission.systemAlertWindow.request();
  await Permission.scheduleExactAlarm.request();
  
  runApp(const MyApp());
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