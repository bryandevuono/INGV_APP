/// Persistent representation of a reply to a note.
/// Stored through the repository/service layer and survives app restarts.
class NoteReplyModel {
  final int id;
  final int noteId;
  final String author;
  final String text;
  final DateTime timestamp;

  const NoteReplyModel({
    required this.id,
    required this.noteId,
    required this.author,
    required this.text,
    required this.timestamp,
  });

  factory NoteReplyModel.fromMap(Map<String, dynamic> map) {
    return NoteReplyModel(
      id: map['reply_id'] as int? ?? 0,
      noteId: map['note_id'] as int? ?? 0,
      author: map['author'] as String? ?? 'Unknown',
      text: map['text'] as String? ?? '',
      timestamp: map['timestamp'] is String
          ? DateTime.parse(map['timestamp'] as String)
          : (map['timestamp'] as DateTime? ?? DateTime.now()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'reply_id': id,
      'note_id': noteId,
      'author': author,
      'text': text,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
