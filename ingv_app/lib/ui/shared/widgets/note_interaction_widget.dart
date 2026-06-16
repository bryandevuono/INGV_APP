import 'package:flutter/material.dart';
import 'note_reply_model.dart';
import 'note_interaction_store.dart';

/// Signature called when a reply is submitted by the user.
typedef ReplySubmittedCallback = void Function(String replyText);

/// A reusable, self-contained widget that adds threaded replies
/// to an individual note item.
///
/// All state lives only in application memory and resets
/// when the app restarts. No database or persistent storage is used.
///
/// Usage example:
/// ```dart
/// NoteInteractionWidget(
///   noteId: note.noteId,
///   localUserName: 'Alice', // optional, defaults to "Local User"
/// )
/// ```
class NoteInteractionWidget extends StatelessWidget {
  /// Unique note identifier for tracking state.
  final int noteId;

  /// Display name for the local user (default: "Local User").
  final String localUserName;

  /// Called when the user submits a new reply (optional; the store persists it anyway).
  final ReplySubmittedCallback? onReplySubmitted;

  const NoteInteractionWidget({
    super.key,
    required this.noteId,
    this.localUserName = 'Local User',
    this.onReplySubmitted,
  });

  void _openReplyDialog(BuildContext context) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => _ReplyDialog(
        noteId: noteId,
        store: NoteInteractionStore.instance,
        localUserName: localUserName,
        controller: controller,
        onReplySubmitted: onReplySubmitted,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = NoteInteractionStore.instance;

    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final currentReplies = store.getReplies(noteId);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Reply button
            InkWell(
              onTap: () => _openReplyDialog(context),
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
                      'Reply${currentReplies.isNotEmpty ? ' (${currentReplies.length})' : ''}',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Replies thread
            if (currentReplies.isNotEmpty) ...[
              const SizedBox(height: 4),
              ...currentReplies.map(
                (reply) => _ReplyTile(
                  author: reply.author,
                  text: reply.text,
                  timestamp: reply.timestamp,
                ),
              ),
            ],
          ],
        );
      },
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

/// Dialog used to compose a reply to a note.
class _ReplyDialog extends StatefulWidget {
  final int noteId;
  final NoteInteractionStore store;
  final String localUserName;
  final TextEditingController controller;
  final ReplySubmittedCallback? onReplySubmitted;

  const _ReplyDialog({
    required this.noteId,
    required this.store,
    required this.localUserName,
    required this.controller,
    this.onReplySubmitted,
  });

  @override
  State<_ReplyDialog> createState() => _ReplyDialogState();
}

class _ReplyDialogState extends State<_ReplyDialog> {
  @override
  void dispose() {
    widget.controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = widget.controller.text.trim();
    if (text.isEmpty) return;

    widget.store.addReply(
      widget.noteId,
      NoteReply(
        author: widget.localUserName,
        text: text,
        timestamp: DateTime.now(),
      ),
    );
    widget.onReplySubmitted?.call(text);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Reply as ${widget.localUserName}'),
      content: TextField(
        controller: widget.controller,
        maxLines: null,
        minLines: 2,
        autofocus: true,
        style: const TextStyle(fontSize: 12),
        decoration: InputDecoration(
          hintText: 'Write a reply...',
          hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: Colors.blue.shade200),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade600,
            foregroundColor: Colors.white,
          ),
          child: const Text('Send'),
        ),
      ],
    );
  }
}
