class EventModel{
  final int eventId;
  final String category;
  final DateTime startDt;
  final DateTime endDt;
  final String author;
  final double lat;
  final double long;
  final String title;
  final String tag;
  final String description;

  EventModel({
    required this.eventId,
    required this.category,
    required this.startDt,
    required this.endDt,
    required this.author,
    required this.lat,
    required this.long,
    required this.title,
    required this.tag,
    required this.description
  });

  Map<String, dynamic> toMap() {
    return {
      'event_id': eventId,
      'start_datetime': startDt.toIso8601String(),
      'end_datetime': endDt.toIso8601String(),
      'lat': lat,
      'lon': long,
      'title': title,
      'tag': tag,
      'description': description,
      'category': category,
      'author': author
    };
  }

  Map<String, dynamic> toJson() => {
      'eventId': eventId,
      'category': category,
      'startDt': startDt.toIso8601String(),
      'endDt': endDt.toIso8601String(),
      'author': author,
      'lat': lat,
      'long': long,
      'title': title,
      'tag': tag,
      'description': description
    };

  factory EventModel.fromMap(Map<String, dynamic> map) {
    return EventModel(
      eventId: map['event_id'] as int,
      category: (map['category'] ?? '') as String,
      startDt: DateTime.parse(map['start_datetime'] as String),
      endDt: DateTime.parse(map['end_datetime'] as String),
      author: (map['author'] ?? '').toString(),
      lat: (map['lat'] as num).toDouble(),
      long: (map['lon'] as num).toDouble(),
      title: (map['title'] ?? '') as String,
      tag: (map['tag'] ?? '') as String,
      description: (map['description'] ?? '') as String
    );
  }
}