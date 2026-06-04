class EventNoteModel {
  final int noteId;
  final String text;
  final String author;
  final DateTime timestamp;

  EventNoteModel({
    required this.noteId,
    required this.text,
    required this.author,
    required this.timestamp,
  });

  factory EventNoteModel.fromMap(Map<String, dynamic> map) {
    return EventNoteModel(
      noteId: map['note_id'] as int? ?? 0,
      text: map['text'] as String? ?? '',
      author: map['author'] as String? ?? 'Unknown',
      timestamp: map['timestamp'] is String
          ? DateTime.parse(map['timestamp'] as String)
          : (map['timestamp'] as DateTime? ?? DateTime.now()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'note_id': noteId,
      'text': text,
      'author': author,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
