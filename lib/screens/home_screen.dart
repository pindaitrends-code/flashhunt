import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/websocket_mirror.dart';
import '../services/accessibility_scanner.dart';
import '../widgets/flash_sale_card.dart';
import '../models/flash_sale_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<FlashSaleModel> _flashSales = [];
  bool _isMonitoring = true;
  int _totalDetected = 0;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _setupWebSocketListener();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList('flash_sale_history') ?? [];

    setState(() {
      _flashSales = history.map((item) {
        final data = json.decode(item);
        return FlashSaleModel.fromJson(data);
      }).toList();
      _totalDetected = _flashSales.length;
    });
  }

  void _setupWebSocketListener() {
    WebSocketMirrorService.addListener((data) {
      if (data['type'] == 'flash_sale_detected') {
        setState(() {
          _flashSales.insert(0, FlashSaleModel.fromJson(data['data']));
          _totalDetected++;
        });
        _showSnackbar(data['data']['title']);
      }
    });
  }

  void _showSnackbar(String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🔥 Flash Sale: $title'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FlashHunt'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.red, Colors.red.shade800],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Total Deteksi', _totalDetected.toString()),
                _buildStatItem('Status', _isMonitoring ? '🟢 Aktif' : '🔴 Nonaktif'),
              ],
            ),
          ),
          Expanded(
            child: _flashSales.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_off, size: 80, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text(
                          'Belum ada flash sale terdeteksi',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Pantau notifikasi marketplace Anda',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _flashSales.length,
                    itemBuilder: (context, index) {
                      return FlashSaleCard(
                        flashSale: _flashSales[index],
                        isNew: index == 0,
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _isMonitoring = !_isMonitoring;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_isMonitoring ? 'Monitoring Aktif' : 'Monitoring Berhenti'),
            ),
          );
        },
        child: Icon(_isMonitoring ? Icons.pause : Icons.play_arrow),
        backgroundColor: _isMonitoring ? Colors.red : Colors.green,
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}