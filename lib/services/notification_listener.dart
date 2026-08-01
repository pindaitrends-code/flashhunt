  static Future<void> processNotification(NotificationModel notification) async {
    final bool isFlashSale = WebhookService.detectFlashSale(notification);

    if (isFlashSale) {
      // 📤 KIRIM WEBHOOK
      await WebhookService.sendWebhookSignal(notification);
      
      // 🔔 NOTIFIKASI LOKAL
      await _showLocalNotification(notification);
      
      // 📡 WEBSOCKET
      await WebSocketMirrorService.sendMessage({
        'type': 'flash_sale_detected',
        'data': notification.toJson(),
      });
      
      // 💾 SIMPAN HISTORY
      await _saveToHistory(notification);
    }
  }