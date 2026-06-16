import 'package:flutter/foundation.dart';
import 'note_reply_model.dart';

/// A lightweight, in-memory state manager for note replies.
/// All data is volatile and resets when the application restarts.
class NoteInteractionStore extends ChangeNotifier {
  NoteInteractionStore._();

  static final NoteInteractionStore instance = NoteInteractionStore._();

  /// Replies keyed by noteId
  final Map<int, List<NoteReply>> _replies = {};

  /// Add a reply to a given note.
  void addReply(int noteId, NoteReply reply) {
    _replies.putIfAbsent(noteId, () => []);
    _replies[noteId]!.add(reply);
    notifyListeners();
  }

  /// Get all replies for a note.
  List<NoteReply> getReplies(int noteId) {
    return _replies[noteId] ?? [];
  }

  /// Clear all stored data (useful for testing or resetting).
  void clearAll() {
    _replies.clear();
  }
}
