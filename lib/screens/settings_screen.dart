import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _enableNotification = true;
  String _webhookUrl = '';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _enableNotification = prefs.getBool('enable_notification') ?? true;
      _webhookUrl = prefs.getString('webhook_url') ?? '';
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('enable_notification', _enableNotification);
    await prefs.setString('webhook_url', _webhookUrl);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pengaturan disimpan!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SwitchListTile(
              title: const Text('Aktifkan Notifikasi'),
              subtitle: const Text('Deteksi notifikasi flash sale otomatis'),
              value: _enableNotification,
              onChanged: (value) {
                setState(() {
                  _enableNotification = value;
                });
              },
            ),
            const SizedBox(height: 20),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Webhook URL',
                hintText: 'https://api.apify.com/...',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                _webhookUrl = value;
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveSettings,
              child: const Text('Simpan Pengaturan'),
            ),
          ],
        ),
      ),
    );
  }
}