class EventModel{
  final int eventId;
  final String category;
  final DateTime date;
  final String authorId;
  final double lat;
  final double long;
  final String title;
  final String tag;
  final String description;

  EventModel({
    required this.eventId,
    required this.category,
    required this.date,
    required this.authorId,
    required this.lat,
    required this.long,
    required this.title,
    required this.tag,
    required this.description
  });

  Map<String, dynamic> toMap() {
    return {
      'event_id': eventId,
      'datetime': date.toIso8601String(),
      'lat': lat,
      'lon': long,
      'tag': tag,
      'category': category,
      'author_id': authorId
    };
  }

  Map<String, dynamic> toJson() => {
      'eventId': eventId,
      'category': category,
      'date': date.toIso8601String(),
      'authorId': authorId,
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
      date: DateTime.parse(map['datetime'] as String),
      authorId: (map['author_id'] ?? '').toString(),
      lat: (map['lat'] as num).toDouble(),
      long: (map['lon'] as num).toDouble(),
      title: (map['title'] ?? '') as String,
      tag: (map['tag'] ?? '') as String,
      description: (map['description'] ?? '') as String
    );
  }
}