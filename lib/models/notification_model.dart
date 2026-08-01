class NotificationModel {
  final String title;
  final String content;
  final String packageName;
  final DateTime timestamp;

  NotificationModel({
    required this.title,
    required this.content,
    required this.packageName,
    required this.timestamp,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      packageName: json['packageName'] ?? '',
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
      'packageName': packageName,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}