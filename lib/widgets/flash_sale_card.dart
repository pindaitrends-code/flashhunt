import 'package:flutter/material.dart';
import '../models/flash_sale_model.dart';

class FlashSaleCard extends StatelessWidget {
  final FlashSaleModel flashSale;
  final bool isNew;

  const FlashSaleCard({
    super.key,
    required this.flashSale,
    this.isNew = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: isNew ? Colors.red.shade900 : Colors.grey.shade900,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.notification_important, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    flashSale.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (isNew)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'NEW',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              flashSale.content,
              style: TextStyle(color: Colors.grey.shade300),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.store, size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(
                  flashSale.platform,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
                const SizedBox(width: 16),
                Icon(Icons.access_time, size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(
                  _formatTime(flashSale.timestamp),
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inHours < 1) return '${diff.inMinutes} menit lalu';
    if (diff.inDays < 1) return '${diff.inHours} jam lalu';
    return '${diff.inDays} hari lalu';
  }
}