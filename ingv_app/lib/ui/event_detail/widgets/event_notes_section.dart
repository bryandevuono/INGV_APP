import 'package:flutter/material.dart';
import 'package:ingv_app/data/models/group_model.dart';
import 'package:ingv_app/ui/event_detail/view_models/event_detail_view_model.dart';
import 'package:ingv_app/ui/event_detail/widgets/add_note_dialog.dart';
import 'package:ingv_app/ui/shared/widgets/note_interaction_widget.dart';

class EventNotesSection extends StatelessWidget {
  final EventDetailViewModel viewModel;
  final List<GroupModel> groupOptions;

  const EventNotesSection({
    super.key,
    required this.viewModel,
    this.groupOptions = const [],
  });

  Future<void> _showReplyDialog(BuildContext context, int noteId) async {
    final replyController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Reply to note'),
          content: TextField(
            controller: replyController,
            autofocus: true,
            maxLines: 4,
            minLines: 2,
            decoration: const InputDecoration(hintText: 'Write a reply...'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final text = replyController.text.trim();
                if (text.isEmpty) {
                  return;
                }

                await viewModel.addReply(
                  noteId: noteId,
                  author: 'Local User',
                  text: text,
                );
                if (context.mounted) {
                  Navigator.of(dialogContext).pop();
                }
              },
              child: const Text('Send'),
            ),
          ],
        );
      },
    );

    replyController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Notes / Observations',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade900,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add, size: 16, color: Colors.blue),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'Add note',
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AddNoteDialog(
                      viewModel: viewModel,
                      groupOptions: groupOptions,
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (viewModel.notes.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'No notes yet',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ),
            )
          else
            SizedBox(
              height: 200, //
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Column(
                  children: List.generate(viewModel.notes.length, (index) {
                    final note = viewModel.notes[index];
                    return Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            border: Border.all(color: Colors.grey.shade200),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                note.text,
                                style: const TextStyle(
                                  fontSize: 11,
                                  height: 1.4,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        note.author,
                                        style: TextStyle(
                                          fontSize: 9,
                                          color: Colors.grey.shade700,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        note.timestamp.toString(),
                                        style: TextStyle(
                                          fontSize: 9,
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.close,
                                      size: 12,
                                      color: Colors.grey,
                                    ),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () {
                                      viewModel.deleteNote(note.noteId);
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              NoteInteractionWidget(
                                replies: viewModel.getRepliesForNote(
                                  note.noteId,
                                ),
                                onReplyTapped: () =>
                                    _showReplyDialog(context, note.noteId),
                              ),
                            ],
                          ),
                        ),

                        if (index < viewModel.notes.length - 1)
                          const SizedBox(height: 8),
                      ],
                    );
                  }),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
