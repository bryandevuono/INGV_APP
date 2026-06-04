class EventMediaModel {
  final int mediaId;
  final String title;
  final String mediaType; // 'image', 'video', etc.
  final String url;
  final DateTime timestamp;

  EventMediaModel({
    required this.mediaId,
    required this.title,
    required this.mediaType,
    required this.url,
    required this.timestamp,
  });

  factory EventMediaModel.fromMap(Map<String, dynamic> map) {
    return EventMediaModel(
      mediaId: map['media_id'] as int? ?? 0,
      title: map['title'] as String? ?? '',
      mediaType: map['media_type'] as String? ?? 'image',
      url: map['url'] as String? ?? '',
      timestamp: map['timestamp'] is String
          ? DateTime.parse(map['timestamp'] as String)
          : (map['timestamp'] as DateTime? ?? DateTime.now()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'media_id': mediaId,
      'title': title,
      'media_type': mediaType,
      'url': url,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
