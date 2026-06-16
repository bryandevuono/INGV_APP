import 'package:flutter/material.dart';
import 'package:ingv_app/data/models/note_reply_model.dart';

/// Signature called when the user wants to compose a reply.
typedef ReplyTapCallback = void Function();

/// A presentational, self-contained widget that displays threaded replies
/// for an individual note and shows a "Reply" action button.
///
/// The widget is **dumb** — it does not own or manage any state.
/// The parent (typically a ViewModel) passes in replies and receives callbacks.
///
/// Usage example:
/// ```dart
/// NoteInteractionWidget(
///   replies: viewModel.getRepliesForNote(note.noteId),
///   onReplyTapped: () => showReplyDialog(noteId: note.noteId),
/// )
/// ```
class NoteInteractionWidget extends StatelessWidget {
  /// Replies to display underneath this note.
  final List<NoteReplyModel> replies;

  /// Called when the user taps the "Reply" button.
  final ReplyTapCallback onReplyTapped;

  const NoteInteractionWidget({
    super.key,
    required this.replies,
    required this.onReplyTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Reply button
        InkWell(
          onTap: onReplyTapped,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.reply_rounded,
                  size: 12,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
                Text(
                  'Reply${replies.isNotEmpty ? ' (${replies.length})' : ''}',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ),

        // Replies thread
        if (replies.isNotEmpty) ...[
          const SizedBox(height: 4),
          ...replies.map(
            (reply) => _ReplyTile(
              author: reply.author,
              text: reply.text,
              timestamp: reply.timestamp,
            ),
          ),
        ],
      ],
    );
  }
}

/// --- Private child widgets ---------------------------------------------------

class _ReplyTile extends StatelessWidget {
  final String author;
  final String text;
  final DateTime timestamp;

  const _ReplyTile({
    required this.author,
    required this.text,
    required this.timestamp,
  });

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';

    return '${dt.month}/${dt.day}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 12, top: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(left: BorderSide(color: Colors.blue.shade300, width: 2)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                author,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade700,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                _formatTimestamp(timestamp),
                style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              height: 1.4,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }
}
