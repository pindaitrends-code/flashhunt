class FlashSaleModel {
  final String id;
  final String title;
  final String content;
  final String platform;
  final DateTime timestamp;
  final bool isVerified;
  final double discount;

  FlashSaleModel({
    required this.id,
    required this.title,
    required this.content,
    required this.platform,
    required this.timestamp,
    this.isVerified = false,
    this.discount = 0,
  });

  factory FlashSaleModel.fromJson(Map<String, dynamic> json) {
    return FlashSaleModel(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      platform: json['platform'] ?? 'Unknown',
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      isVerified: json['isVerified'] ?? false,
      discount: json['discount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'platform': platform,
      'timestamp': timestamp.toIso8601String(),
      'isVerified': isVerified,
      'discount': discount,
    };
  }
}