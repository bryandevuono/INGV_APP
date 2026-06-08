import 'package:flutter/material.dart';
import 'package:ingv_app/ui/event_detail/view_models/event_detail_view_model.dart';

class AddNoteDialog extends StatelessWidget {
  final EventDetailViewModel viewModel;

  const AddNoteDialog({
    super.key,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    final nameController = TextEditingController();
    final teamController = TextEditingController();
    final noteController = TextEditingController();

    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SizedBox(
          width: 320,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Add Note:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    const SizedBox(width: 50, child: Text('Name:')),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: nameController,
                        decoration: const InputDecoration(hintText: 'Input field'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    const SizedBox(width: 50, child: Text('Team:')),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: teamController,
                        decoration: const InputDecoration(hintText: 'Input field'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(
                      width: 50,
                      child: Padding(
                        padding: EdgeInsets.only(top: 12.0),
                        child: Text('Note:'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: noteController,
                        maxLines: 5,
                        decoration: const InputDecoration(hintText: 'Input field'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () {
                      final authorInfo = teamController.text.isNotEmpty
                          ? '${nameController.text} (${teamController.text})'
                          : nameController.text;

                      viewModel.addNote(noteController.text, authorInfo);
                      Navigator.of(context).pop();
                    },
                    child: const Text('Add Note'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}