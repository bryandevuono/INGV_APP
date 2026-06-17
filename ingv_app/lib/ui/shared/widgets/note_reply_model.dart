/// Local (non-persistent) representation of a reply to a note.
/// Data lives only in application memory and resets on restart.
class NoteReply {
  final String author;
  final String text;
  final DateTime timestamp;

  const NoteReply({
    required this.author,
    required this.text,
    required this.timestamp,
  });
}
