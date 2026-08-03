import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_apps/device_apps.dart';
import '../services/websocket_mirror.dart';
import '../services/webhook_service.dart';
import '../services/accessibility_scanner.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _enableNotification = true;
  bool _enableWebSocket = false;
  bool _enableMirrorMode = false;
  String _wsUrl = 'wss://echo.websocket.org';
  String _apifyToken = '';
  Map<String, String> _marketplaceAffiliates = {};
  List<String> _marketplacePackages = [];
  Map<String, bool> _marketplaceEnabled = {};
  Map<String, bool> _marketplaceInstalled = {};
  bool _isScanning = false;
  String _newMarketplacePackage = '';
  String _newMarketplaceName = '';

  final Map<String, String> _defaultMarketplaces = {
    'com.shopee': 'Shopee',
    'com.tokopedia': 'Tokopedia',
    'com.lazada': 'Lazada',
    'com.blibli': 'Blibli',
    'com.tiktok': 'TikTok',
    'com.amazon': 'Amazon',
    'com.bukalapak': 'Bukalapak',
    'com.olx': 'OLX',
  };

  final Map<String, IconData> _marketplaceIcons = {
    'com.shopee': Icons.shopping_bag,
    'com.tokopedia': Icons.storefront,
    'com.lazada': Icons.shopping_cart,
    'com.blibli': Icons.store,
    'com.tiktok': Icons.music_note,
    'com.amazon': Icons.shopping_cart,
    'com.bukalapak': Icons.shop,
    'com.olx': Icons.sell,
  };

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _scanInstalledApps();
  }

  // ✅ SCAN APPS TERINSTAL
  Future<void> _scanInstalledApps() async {
    setState(() => _isScanning = true);
    try {
      List<Application> apps = await DeviceApps.getInstalledApplications(
        includeSystemApps: false,
        onlyAppsWithLaunchIntent: true,
      );
      for (var pkg in _defaultMarketplaces.keys) {
        bool isInstalled = apps.any((app) => app.packageName == pkg);
        setState(() {
          _marketplaceInstalled[pkg] = isInstalled;
          if (isInstalled && !_marketplacePackages.contains(pkg)) {
            _marketplacePackages.add(pkg);
            _marketplaceEnabled[pkg] = true;
          }
        });
      }
      print('✅ Auto-scan selesai!');
    } catch (e) {
      print('❌ Auto-scan error: $e');
    }
    setState(() => _isScanning = false);
  }

  // ✅ LOAD SETTINGS
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _enableNotification = prefs.getBool('enable_notification') ?? true;
      _enableWebSocket = prefs.getBool('enable_websocket') ?? false;
      _enableMirrorMode = prefs.getBool('enable_mirror_mode') ?? false;
      _wsUrl = prefs.getString('websocket_url') ?? 'wss://echo.websocket.org';
      _apifyToken = prefs.getString('apify_token') ?? '';
      _marketplacePackages = prefs.getStringList('marketplace_packages') ?? [];
      for (var pkg in _marketplacePackages) {
        _marketplaceEnabled[pkg] = prefs.getBool('enabled_$pkg') ?? true;
        _marketplaceAffiliates[pkg] = prefs.getString('affiliate_$pkg') ?? '';
      }
    });
  }

  // ✅ SAVE SETTINGS
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('enable_notification', _enableNotification);
    await prefs.setBool('enable_websocket', _enableWebSocket);
    await prefs.setBool('enable_mirror_mode', _enableMirrorMode);
    await prefs.setString('websocket_url', _wsUrl);
    await prefs.setString('apify_token', _apifyToken);
    await prefs.setStringList('marketplace_packages', _marketplacePackages);
    for (var pkg in _marketplacePackages) {
      await prefs.setBool('enabled_$pkg', _marketplaceEnabled[pkg] ?? true);
      await prefs.setString('affiliate_$pkg', _marketplaceAffiliates[pkg] ?? '');
    }
    WebhookService.updateToken(_apifyToken);
    WebhookService.updateMarketplaces(_marketplacePackages, _marketplaceAffiliates);
    await WebSocketMirrorService.reconnect();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Pengaturan disimpan!')));
  }

  // ✅ TAMBAH MARKETPLACE
  void _addNewMarketplace() {
    if (_newMarketplacePackage.isNotEmpty && _newMarketplaceName.isNotEmpty) {
      setState(() {
        _marketplacePackages.add(_newMarketplacePackage);
        _marketplaceAffiliates[_newMarketplacePackage] = '';
        _marketplaceEnabled[_newMarketplacePackage] = true;
        _marketplaceInstalled[_newMarketplacePackage] = false;
        _newMarketplacePackage = '';
        _newMarketplaceName = '';
      });
    }
  }

  // ✅ HAPUS MARKETPLACE
  void _removeMarketplace(String package) {
    if (_defaultMarketplaces.containsKey(package)) {
      setState(() {
        _marketplaceEnabled[package] = false;
        _marketplaceAffiliates[package] = '';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Marketplace dinonaktifkan'), backgroundColor: Colors.orange),
      );
      return;
    }
    setState(() {
      _marketplacePackages.remove(package);
      _marketplaceAffiliates.remove(package);
      _marketplaceEnabled.remove(package);
      _marketplaceInstalled.remove(package);
    });
  }

  // ✅ BUKA AKSESIBILITAS
  Future<void> _openAccessibilitySettings() async {
    try {
      await AccessibilityScanner.requestAccessibility();
    } catch (e) {
      print('❌ Error: $e');
    }
  }

  // ✅ BUKA SETTINGS + PANDUAN USAGE ACCESS
  Future<void> _openUsageAccessSettings() async {
    try {
      await DeviceApps.openAppSettings('com.flashhunt.flashhunt');
      _showUsageAccessGuide();
    } catch (e) {
      print('❌ Gagal buka settings: $e');
    }
  }

  // ✅ TAMPILKAN PANDUAN
  void _showUsageAccessGuide() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🔓 Cara Aktifkan Izin Penggunaan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('📌 Ikuti langkah berikut:'),
            SizedBox(height: 8),
            Text('1. Buka Settings HP'),
            Text('2. Cari "Izin Khusus" atau "Special App Access"'),
            Text('3. Pilih "Akses Penggunaan" atau "Usage Access"'),
            Text('4. Aktifkan FlashHunt'),
            SizedBox(height: 12),
            Text('⚡ Tips: Pakai fitur pencarian 🔍'),
            Text('   ketik "usage" atau "akses"'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('⚙️ Pengaturan'),
        actions: [
          if (_isScanning)
            const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            IconButton(icon: const Icon(Icons.refresh), onPressed: _scanInstalledApps),
          IconButton(icon: const Icon(Icons.save), onPressed: _saveSettings),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ♿ AKSESIBILITAS
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.green, width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.accessibility, color: Colors.green),
                        SizedBox(width: 8),
                        Text(
                          '♿ Izin Aksesibilitas (WAJIB!)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Aktifkan aksesibilitas agar FlashHunt bisa membaca layar, notifikasi, dan auto-click',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _openAccessibilitySettings,
                            icon: const Icon(Icons.settings),
                            label: const Text('Buka Aksesibilitas'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 🔓 IZIN PENGGUNAAN
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blue, width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.list_alt, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          '🔓 Izin Penggunaan (Usage Access)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Aktifkan izin ini agar FlashHunt bisa mendeteksi aplikasi marketplace yang terinstal di HP Anda',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _openUsageAccessSettings,
                            icon: const Icon(Icons.settings),
                            label: const Text('Buka Izin Penggunaan'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 🔑 TOKEN APIFY
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.orange, width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.key, color: Colors.orange),
                        SizedBox(width: 8),
                        Text(
                          '🔑 Token Apify',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      obscureText: true,
                      decoration: const InputDecoration(
                        hintText: 'Masukkan token Apify Anda',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.password),
                      ),
                      controller: TextEditingController(text: _apifyToken),
                      onChanged: (value) => _apifyToken = value,
                    ),
                    const Text('Token untuk semua koneksi ke Apify', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 🏪 MARKETPLACE
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      '🏪 Marketplace & Afiliasi',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Text(
                    '${_marketplacePackages.where((p) => _marketplaceEnabled[p] ?? false).length} aktif',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                '🔍 Otomatis deteksi marketplace terinstal.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),

              ..._marketplacePackages.map((pkg) {
                final name = _defaultMarketplaces[pkg] ?? pkg;
                final isInstalled = _marketplaceInstalled[pkg] ?? false;
                final isEnabled = _marketplaceEnabled[pkg] ?? true;
                final icon = _marketplaceIcons[pkg] ?? Icons.shopping_cart;
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  color: isEnabled ? Colors.grey.shade900 : Colors.grey.shade800,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Switch(
                          value: isEnabled,
                          onChanged: (value) => setState(() => _marketplaceEnabled[pkg] = value),
                          activeColor: Colors.green,
                        ),
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isEnabled ? Colors.grey.shade800 : Colors.grey.shade700,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(icon, color: isInstalled ? Colors.green : Colors.grey.shade500),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isEnabled ? Colors.white : Colors.grey.shade500,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (isInstalled)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        '✓ Terinstal',
                                        style: TextStyle(fontSize: 9, color: Colors.green, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                ],
                              ),
                              Text(
                                pkg,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isEnabled ? Colors.grey.shade500 : Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: TextField(
                            enabled: isEnabled,
                            decoration: InputDecoration(
                              hintText: isInstalled ? 'ID Afiliasi' : 'Tidak terinstal',
                              border: const OutlineInputBorder(),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              isDense: true,
                            ),
                            controller: TextEditingController(text: _marketplaceAffiliates[pkg] ?? ''),
                            onChanged: (value) => _marketplaceAffiliates[pkg] = value,
                          ),
                        ),
                        if (!_defaultMarketplaces.containsKey(pkg))
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: () => _removeMarketplace(pkg),
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),

              const SizedBox(height: 16),

              // ➕ TAMBAH MARKETPLACE
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('➕ Tambah Marketplace Manual', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(
                              labelText: 'Nama',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              isDense: true,
                            ),
                            onChanged: (v) => _newMarketplaceName = v,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(
                              labelText: 'Package',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              isDense: true,
                            ),
                            onChanged: (v) => _newMarketplacePackage = v,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _addNewMarketplace,
                          child: const Text('Tambah'),
                        ),
                      ],
                    ),
                    const Text(
                      '⚠️ Package harus sesuai dengan aplikasi di HP',
                      style: TextStyle(fontSize: 10, color: Colors.orange),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ✅ TOMBOL SCAN MANUAL
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.purple, width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.search, color: Colors.purple),
                        SizedBox(width: 8),
                        Text(
                          '🔍 Scan Marketplace',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Klik tombol di bawah untuk memindai ulang aplikasi marketplace yang terinstal',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          setState(() => _isScanning = true);
                          await _scanInstalledApps();
                          setState(() => _isScanning = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('✅ Scan selesai! Marketplace terdeteksi.')),
                          );
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Scan Marketplace Sekarang'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              const Divider(),

              // 📡 WEBSOCKET
              SwitchListTile(
                title: const Text('🌐 Aktifkan WebSocket'),
                subtitle: const Text('Kirim data flash sale ke server'),
                value: _enableWebSocket,
                onChanged: (v) => setState(() => _enableWebSocket = v),
              ),
              SwitchListTile(
                title: const Text('🔄 Mode Mirror'),
                subtitle: const Text('Kirim data satu arah (log saja)'),
                value: _enableMirrorMode,
                onChanged: (v) => setState(() => _enableMirrorMode = v),
              ),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'WebSocket URL',
                  hintText: 'wss://your-server.com/ws',
                  border: OutlineInputBorder(),
                ),
                controller: TextEditingController(text: _wsUrl),
                onChanged: (v) => _wsUrl = v,
              ),

              const SizedBox(height: 16),
              const Divider(),

              // 🔔 NOTIFIKASI
              SwitchListTile(
                title: const Text('🔔 Aktifkan Notifikasi'),
                subtitle: const Text('Deteksi notifikasi flash sale otomatis'),
                value: _enableNotification,
                onChanged: (v) => setState(() => _enableNotification = v),
              ),

              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveSettings,
                child: const Text('💾 Simpan Pengaturan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}