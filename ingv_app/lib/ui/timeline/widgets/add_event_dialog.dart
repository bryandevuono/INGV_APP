import 'dart:io';
import 'package:flutter/material.dart';
import 'package:ingv_app/data/models/attachment_type.dart';
import 'package:ingv_app/data/models/event_attachment.dart';
import 'package:ingv_app/data/models/event_model.dart';
import 'package:ingv_app/data/repositories/attachment_repository.dart';
import 'package:ingv_app/data/services/file_picker_service.dart';
import 'package:ingv_app/data/models/group_model.dart';
import 'package:ingv_app/ui/timeline/view_models/timeline_interface.dart';
import 'package:ingv_app/data/services/attachment_service.dart';

void showAddEventDialog(
  BuildContext context,
  ITimelineViewModel viewModel,
  List<GroupModel> groupOptions,
) {
  if (!context.mounted) return;

  showDialog(
    routeSettings: const RouteSettings(name: 'disable-accessibility-view'),
    context: context,
    barrierDismissible: true,
    builder: (BuildContext dialogContext) {
      return Material(
        type: MaterialType.transparency,
        child: AddEventDialogContent(
          viewModel: viewModel,
          groupOptions: groupOptions,
        ),
      );
    },
  );
}

class AddEventDialogContent extends StatefulWidget {
  final ITimelineViewModel viewModel;
  final List<GroupModel> groupOptions;

  const AddEventDialogContent({
    super.key,
    required this.viewModel,
    required this.groupOptions,
  });

  @override
  State<AddEventDialogContent> createState() => _AddEventDialogContentState();
}

class _AddEventDialogContentState extends State<AddEventDialogContent> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController titleController;
  late final TextEditingController descriptionController;
  late final TextEditingController latController;
  late final TextEditingController longController;

  final filePickerService = FilePickerService();
  final attachmentRepository = AttachmentRepository(AttachmentService());

  final defaultCategories = <String>[
    'Volcanic',
    'Earthquake',
    'Hydrological',
    'Meteorological',
    'Geological',
    'Atmospheric',
  ];

  String? selectedGroup;
  late String selectedCategory;
  late List<String> categoryOptions;
  List<File> selectedMediaFiles = [];
  DateTime? startDate;
  TimeOfDay? startTime;
  DateTime? endDate;
  TimeOfDay? endTime;

  String? errorMessage;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController();
    descriptionController = TextEditingController();
    latController = TextEditingController(text: '0.0');
    longController = TextEditingController(text: '0.0');

    categoryOptions = widget.viewModel.categories.isNotEmpty
        ? widget.viewModel.categories
        : defaultCategories;
    selectedCategory = categoryOptions.first;
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    latController.dispose();
    longController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.75;

    return AlertDialog(
      title: const Text('Add New Event'),
      content: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight, maxWidth: 400),
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Error Alert Box
                if (errorMessage != null) ...[
                  Container(
                    key: ValueKey(errorMessage),
                    width: 300,
                    padding: const EdgeInsets.all(10.0),
                    margin: const EdgeInsets.only(bottom: 12.0),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      border: Border.all(
                        color: Colors.red.shade400,
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.error, color: Colors.red.shade900, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            errorMessage!,
                            style: TextStyle(
                              color: Colors.red.shade900,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                TextFormField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title *'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                TextFormField(
                  controller: latController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Latitude'),
                  validator: (value) {
                    if (value == null || value.isEmpty) return null;
                    final numValue = double.tryParse(value);
                    if (numValue == null) {
                      return 'Must be a valid number';
                    }
                    if (numValue < -90 || numValue > 90) {
                      return 'Must be between -90 and 90';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: longController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Longitude'),
                  validator: (value) {
                    if (value == null || value.isEmpty) return null;
                    final numValue = double.tryParse(value);
                    if (numValue == null) {
                      return 'Must be a valid number';
                    }
                    if (numValue < -180 || numValue > 180) {
                      return 'Must be between -180 and 180';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedCategory,
                      isExpanded: true,
                      items: categoryOptions
                          .map(
                            (category) => DropdownMenuItem<String>(
                              value: category,
                              child: Text(category),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            selectedCategory = value;
                          });
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Group',
                    border: OutlineInputBorder(),
                  ),
                  child: DropdownButton<String?>(
                    value: selectedGroup,
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('None'),
                      ),
                      ...widget.groupOptions.map(
                        (group) => DropdownMenuItem<String?>(
                          value: group.id,
                          child: Text(group.name),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedGroup = value;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 10),

                // Start Date Row
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        startDate == null
                            ? 'No start date *'
                            : 'Start: ${startDate!.toString().split(' ')[0]} ${startTime?.format(context) ?? ''}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: startDate ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (date != null) {
                          if (!mounted) return;
                          final time = await showTimePicker(
                            context: context,
                            initialTime: startTime ?? TimeOfDay.now(),
                          );
                          if (time != null) {
                            setState(() {
                              startDate = date;
                              startTime = time;
                              errorMessage = null;
                            });
                          }
                        }
                      },
                      child: const Text('Pick Start Date'),
                    ),
                  ],
                ),

                // End Date Row
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        endDate == null
                            ? 'No end date'
                            : 'End: ${endDate!.toString().split(' ')[0]} ${endTime?.format(context) ?? ''}',
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: endDate ?? startDate ?? DateTime.now(),
                          firstDate: startDate ?? DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (date != null) {
                          if (!mounted) return;
                          final time = await showTimePicker(
                            context: context,
                            initialTime: endTime ?? TimeOfDay.now(),
                          );
                          if (time != null) {
                            setState(() {
                              endDate = date;
                              endTime = time;
                              errorMessage = null;
                            });
                          }
                        }
                      },
                      child: const Text('Pick End Date'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Attachments Container
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Attachments (optional)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (selectedMediaFiles.isEmpty)
                        Text(
                          'No files selected',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        )
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: selectedMediaFiles.asMap().entries.map((
                            entry,
                          ) {
                            final index = entry.key;
                            final file = entry.value;
                            final fileName = _fileNameFromPath(file);
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  if (file.path.toLowerCase().endsWith(
                                        '.jpg',
                                      ) ||
                                      file.path.toLowerCase().endsWith(
                                        '.jpeg',
                                      ) ||
                                      file.path.toLowerCase().endsWith(
                                        '.png',
                                      ) ||
                                      file.path.toLowerCase().endsWith('.webp'))
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: Image.file(
                                        file,
                                        width: 40,
                                        height: 40,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  else
                                    const Icon(Icons.attach_file, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      fileName,
                                      style: const TextStyle(fontSize: 12),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close, size: 16),
                                    onPressed: () {
                                      setState(() {
                                        selectedMediaFiles.removeAt(index);
                                      });
                                    },
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final files = await filePickerService
                                    .pickImages();
                                if (files.isNotEmpty) {
                                  setState(() {
                                    selectedMediaFiles.addAll(files);
                                  });
                                }
                              },
                              icon: const Icon(Icons.image, size: 14),
                              label: const Text('Image'),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final files = await filePickerService
                                    .pickVideos();
                                if (files.isNotEmpty) {
                                  setState(() {
                                    selectedMediaFiles.addAll(files);
                                  });
                                }
                              },
                              icon: const Icon(Icons.videocam, size: 14),
                              label: const Text('Video'),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final files = await filePickerService
                                    .pickFiles();
                                if (files.isNotEmpty) {
                                  setState(() {
                                    selectedMediaFiles.addAll(files);
                                  });
                                }
                              },
                              icon: const Icon(Icons.attach_file, size: 14),
                              label: const Text('Files'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: isLoading
              ? null
              : () {
                  setState(() {
                    startDate = DateTime.now();
                    startTime = TimeOfDay.fromDateTime(startDate!);
                    errorMessage = null;
                  });
                },
          child: const Text('Now'),
        ),
        TextButton(
          onPressed: isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: isLoading ? null : () => _submitForm(),
          child: isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Add'),
        ),
      ],
    );
  }

  void _submitForm() async {
    // 1. Validate custom configurations like date picker elements first
    if (startDate == null || startTime == null) {
      setState(() {
        errorMessage =
            'Required fields missing: Fill Title, Start Date & Time!';
      });
      return;
    }

    // 2. Fire the global form logic (runs validators for Title, Latitude, and Longitude)
    if (!_formKey.currentState!.validate()) {
      return;
    }

    DateTime finalStartDate = DateTime(
      startDate!.year,
      startDate!.month,
      startDate!.day,
      startTime!.hour,
      startTime!.minute,
    );
    DateTime? finalEndDate;

    if (endDate != null && endTime != null) {
      finalEndDate = DateTime(
        endDate!.year,
        endDate!.month,
        endDate!.day,
        endTime!.hour,
        endTime!.minute,
      );
      if (finalEndDate.isBefore(finalStartDate)) {
        setState(() {
          errorMessage = 'Logic error: End date cannot be before Start date!';
        });
        return;
      }
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final newEvent = EventModel(
        eventId: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        category: selectedCategory,
        startDt: finalStartDate,
        endDt: finalEndDate,
        author: 'User',
        lat: double.tryParse(latController.text) ?? 0.0,
        long: double.tryParse(longController.text) ?? 0.0,
        title: titleController.text.trim(),
        tag: '',
        groupId: selectedGroup,
        description: descriptionController.text.trim(),
      );

      await widget.viewModel.addEvent(newEvent);

      for (final file in selectedMediaFiles) {
        await attachmentRepository.addAttachment(
          _buildAttachment(newEvent.eventId.toString(), file),
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = 'System catch error: $e';
          isLoading = false;
        });
      }
    }
  }
}

String _fileNameFromPath(File file) {
  return file.path.split(Platform.pathSeparator).last;
}

EventAttachment _buildAttachment(String eventId, File file) {
  final fileName = _fileNameFromPath(file);
  final extension = fileName.split('.').last.toLowerCase();

  return EventAttachment(
    id: 'local_${DateTime.now().microsecondsSinceEpoch}',
    eventId: eventId,
    fileName: fileName,
    localPath: file.path,
    type: parseAttachmentTypeFromExtension(extension),
    sizeBytes: file.existsSync() ? file.lengthSync() : null,
    mimeType: _guessMimeType(extension),
    createdAt: DateTime.now(),
  );
}

String _guessMimeType(String extension) {
  switch (extension.toLowerCase()) {
    case 'jpg':
    case 'jpeg':
      return 'image/jpeg';
    case 'png':
      return 'image/png';
    case 'gif':
      return 'image/gif';
    case 'webp':
      return 'image/webp';
    case 'mp4':
      return 'video/mp4';
    case 'mov':
      return 'video/quicktime';
    case 'avi':
      return 'video/x-msvideo';
    case 'mkv':
      return 'video/x-matroska';
    case 'webm':
      return 'video/webm';
    case 'pdf':
      return 'application/pdf';
    case 'csv':
      return 'text/csv';
    case 'docx':
      return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    case 'xlsx':
      return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
    case 'xls':
      return 'application/vnd.ms-excel';
    default:
      return 'application/octet-stream';
  }
}
