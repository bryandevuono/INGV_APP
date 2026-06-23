import 'package:flutter/material.dart';
import 'package:ingv_app/data/models/group_model.dart';
import 'package:ingv_app/ui/event_detail/view_models/event_detail_view_model.dart';

class AddNoteDialog extends StatefulWidget {
  final EventDetailViewModel viewModel;
  final List<GroupModel> groupOptions;

  const AddNoteDialog({
    super.key,
    required this.viewModel,
    this.groupOptions = const [],
  });

  @override
  State<AddNoteDialog> createState() => _AddNoteDialogState();
}

class _AddNoteDialogState extends State<AddNoteDialog> {
  late final TextEditingController nameController;
  late final TextEditingController noteController;
  String? selectedGroup;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
    noteController = TextEditingController();
  }

  @override
  void dispose() {
    nameController.dispose();
    noteController.dispose();
    super.dispose();
  }

  String? _selectedGroupName() {
    if (selectedGroup == null) {
      return null;
    }

    for (final group in widget.groupOptions) {
      if (group.id == selectedGroup) {
        return group.name;
      }
    }

    return null;
  }

  List<DropdownMenuItem<String?>> _buildGroupItems() {
    final items = <DropdownMenuItem<String?>>[
      const DropdownMenuItem<String?>(value: null, child: Text('None')),
    ];
    final seenGroupIds = <String>{};

    for (final group in widget.groupOptions) {
      if (seenGroupIds.add(group.id)) {
        items.add(
          DropdownMenuItem<String?>(value: group.id, child: Text(group.name)),
        );
      }
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320, maxHeight: 520),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
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
                      decoration: const InputDecoration(
                        hintText: 'Input field',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Group',
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                child: DropdownButton<String?>(
                  value: selectedGroup,
                  isExpanded: true,
                  isDense: true,
                  iconSize: 18,
                  menuMaxHeight: 220,
                  items: _buildGroupItems(),
                  onChanged: (value) {
                    setState(() {
                      selectedGroup = value;
                    });
                  },
                ),
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
                      decoration: const InputDecoration(
                        hintText: 'Input field',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      final selectedGroupName = _selectedGroupName();
                      final authorParts = <String>[];
                      if (nameController.text.isNotEmpty) {
                        authorParts.add(nameController.text);
                      }
                      if (selectedGroupName != null) {
                        authorParts.add('- $selectedGroupName');
                      }

                      widget.viewModel.addNote(
                        noteController.text,
                        authorParts.join(' '),
                      );
                      Navigator.of(context).pop();
                    },
                    child: const Text('Add Note'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
