import 'dart:io';
import 'package:flutter/material.dart';
import 'package:ingv_app/ui/groups/view_models/group_view_model.dart';
import 'package:file_picker/file_picker.dart';

class GroupDialog extends StatefulWidget {
  const GroupDialog({
    super.key,
    required this.mode,
    required this.groupId,
    required this.viewModel,
  });

  final String mode;
  final String groupId;
  final GroupScreenViewModel viewModel;

  @override
  State<GroupDialog> createState() => _GroupDialogState();
}

class _GroupDialogState extends State<GroupDialog> {
  late final GroupScreenViewModel _viewModel;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController searchController = TextEditingController();

  PlatformFile? _pickedFile;
  String? _nameError;

  @override
  void initState() {
    super.initState();
    _viewModel = widget.viewModel;

    _viewModel.getPersons();
    _viewModel.selectUsers(widget.mode, widget.groupId, nameController);

    searchController.addListener(_onSearchChanged);

    nameController.addListener(() {
      if (_nameError != null && nameController.text.isNotEmpty) {
        setState(() {
          _nameError = null;
        });
      }
    });
  }

  void _onSearchChanged() {
    _viewModel.setSearchQuery(searchController.text);
  }

  Future<void> _pickImageFile() async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _pickedFile = result.files.first;
        });
      }
    } catch (e) {
      debugPrint("Error picking file: $e");
    }
  }

  String? get _resolvedPath {
    final raw = _pickedFile?.path;
    if (raw == null) return null;
    if (raw.startsWith('file:///')) return raw.substring(8);
    return raw;
  }

  @override
  void dispose() {
    searchController.removeListener(_onSearchChanged);
    nameController.dispose();
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.75,
        padding: const EdgeInsets.all(32.0),
        child: ListenableBuilder(
          listenable: _viewModel,
          builder: (context, _) {
            final displayPersons = _viewModel.filteredPersons;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                const Text(
                  'Add people to group:',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w400,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 24),

                // Name Input Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment
                      .start, // Align top to account for error text height
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(
                        top: 10.0,
                      ), // Align with input text
                      child: SizedBox(
                        width: 80,
                        child: Text(
                          'Name:',
                          style: TextStyle(fontSize: 16, color: Colors.black),
                        ),
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          hintText: 'Input field',
                          hintStyle: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 14,
                          ),
                          errorText:
                              _nameError, // Displays error within the dialog
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Media Input Row
                Row(
                  children: [
                    const SizedBox(
                      width: 80,
                      child: Text(
                        'Media:',
                        style: TextStyle(fontSize: 16, color: Colors.black),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _pickImageFile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                          side: const BorderSide(
                            color: Colors.black,
                            width: 1.2,
                          ),
                        ),
                      ),
                      child: Text(
                        _pickedFile == null ? 'Add image' : 'Change image',
                      ),
                    ),
                    const SizedBox(width: 12),
                    // UI Feedback showing preview or file name
                    if (_pickedFile != null)
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.grey),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Image.file(
                                  File(_resolvedPath!),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _pickedFile!.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 24),

                // Search Input Bar
                Container(
                  height: 44,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black, width: 1.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: TextField(
                    controller: searchController,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(
                        Icons.search,
                        color: Colors.black,
                        size: 20,
                      ),
                      hintText: 'Search',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Total Users Text Indicator
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Showing ${displayPersons.length} users:',
                    style: const TextStyle(fontSize: 14, color: Colors.black),
                  ),
                ),
                const SizedBox(height: 12),

                // Users List
                Expanded(
                  child: _viewModel.persons.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : displayPersons.isEmpty
                      ? const Center(
                          child: Text(
                            'No users found.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          itemCount: displayPersons.length,
                          itemBuilder: (context, index) {
                            final person = displayPersons[index];
                            final isSelected = _viewModel.checkIfUserSelected(
                              person.id,
                            );

                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 10.0,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.grey.shade400,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.person_outline,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  const SizedBox(width: 20),

                                  Expanded(
                                    child: Text(
                                      person.name,
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ),

                                  GestureDetector(
                                    onTap: () {
                                      if (_viewModel.checkIfUserSelected(
                                        person.id,
                                      )) {
                                        _viewModel.removeUserId(person.id);
                                      } else {
                                        _viewModel.addUserId(person.id);
                                      }

                                      _viewModel.toggleNotify();

                                      if (widget.mode == 'update') {
                                        _viewModel.addorRemoveMember(
                                          widget.groupId,
                                          person.id,
                                        );
                                      }
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? Colors.green
                                            : const Color(0xFF2563EB),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.black,
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Icon(
                                        isSelected ? Icons.check : Icons.add,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                              ),
                            );
                          },
                        ),
                ),
                const SizedBox(height: 16),

                // Dialog Actions (Footer Row)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        _viewModel.clearSelectedUsers();
                        _viewModel.setSearchQuery('');
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Colors.black54),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () async {
                        // Check if the input is empty
                        if (nameController.text.trim().isEmpty) {
                          setState(() {
                            _nameError = 'Group name cannot be empty';
                          });
                          return;
                        }

                        if (widget.mode == 'create') {
                          final newGroupId = await _viewModel.createNewGroup(
                            nameController.text,
                          );
                          _viewModel.clearSelectedUsers();
                          _viewModel.setSearchQuery('');
                          if (_pickedFile != null && _resolvedPath != null) {
                            await _viewModel.postImageToGroupId(
                              newGroupId,
                              _resolvedPath!,
                            );
                          }
                          Navigator.pop(context);
                        } else if (widget.mode == 'update') {
                          _viewModel.editGroup(
                            widget.groupId,
                            nameController.text,
                          );
                          _viewModel.clearSelectedUsers();
                          _viewModel.setSearchQuery('');
                          await _viewModel.postImageToGroupId(
                            widget.groupId,
                            _resolvedPath ?? '',
                          );
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                      ),
                      child: widget.mode == 'create'
                          ? const Text('Create Group')
                          : const Text('Update Group'),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
