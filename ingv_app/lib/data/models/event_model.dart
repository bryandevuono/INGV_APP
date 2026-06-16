class EventModel {
  final int eventId;
  final String category;
  final DateTime startDt;
  final DateTime? endDt;
  final String author;
  final double lat;
  final double long;
  final String title;
  final String tag;
  final String description;
  final String? groupId;

  EventModel({
    required this.eventId,
    required this.category,
    required this.startDt,
    this.endDt,
    required this.author,
    required this.lat,
    required this.long,
    required this.title,
    required this.tag,
    required this.description,
    required this.groupId,
  });

  EventModel copyWith({
    int? eventId,
    String? category,
    DateTime? startDt,
    DateTime? endDt,
    String? author,
    double? lat,
    double? long,
    String? title,
    String? tag,
    String? description,
    String? groupId,
  }) {
    return EventModel(
      eventId: eventId ?? this.eventId,
      category: category ?? this.category,
      startDt: startDt ?? this.startDt,
      endDt: endDt ?? this.endDt,
      author: author ?? this.author,
      lat: lat ?? this.lat,
      long: long ?? this.long,
      title: title ?? this.title,
      tag: tag ?? this.tag,
      description: description ?? this.description,
      groupId: groupId ?? this.groupId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'event_id': eventId,
      'start_datetime': startDt.toIso8601String(),
      'end_datetime': endDt?.toIso8601String(),
      'lat': lat,
      'lon': long,
      'title': title,
      'tag': tag,
      'description': description,
      'category': category,
      'author': author,
      'group_id': groupId,
    };
  }

  Map<String, dynamic> toJson() => {
    'event_id': eventId,
    'category': category,
    'start_datetime': startDt.toIso8601String(),
    'end_datetime': endDt?.toIso8601String(),
    'author': author,
    'lat': lat,
    'lon': long,
    'title': title,
    'tag': tag,
    'description': description,
    'group_id': groupId,
  };

  factory EventModel.fromMap(Map<String, dynamic> map) {
    return EventModel(
      eventId: map['event_id'] as int,
      category: (map['category'] ?? '') as String,
      startDt: DateTime.parse(map['start_datetime'] as String),
      endDt: map['end_datetime'] != null
          ? DateTime.parse(map['end_datetime'] as String)
          : null,
      author: (map['author'] ?? '').toString(),
      lat: (map['lat'] as num).toDouble(),
      long: (map['lon'] as num).toDouble(),
      title: (map['title'] ?? '') as String,
      tag: (map['tag'] ?? '') as String,
      description: (map['description'] ?? '') as String,
      groupId: map['group_id']?.toString(),
    );
  }
}
