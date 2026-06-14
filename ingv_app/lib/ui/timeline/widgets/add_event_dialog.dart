import 'dart:io';
import 'package:flutter/material.dart';
import 'package:ingv_app/data/models/event_model.dart';
import 'package:ingv_app/data/services/file_picker_service.dart';
import 'package:ingv_app/data/models/group_model.dart';
import 'package:ingv_app/ui/timeline/view_models/timeline_interface.dart';

void showAddEventDialog(
  BuildContext context,
  ITimelineViewModel viewModel,
  List<GroupModel> groupOptions,
) async {
  final titleController = TextEditingController();

  final descriptionController = TextEditingController();
  final latController = TextEditingController(text: '0.0');
  final longController = TextEditingController(text: '0.0');
  final filePickerService = FilePickerService();
  final defaultCategories = <String>[
    'Volcanic',
    'Earthquake',
    'Hydrological',
    'Meteorological',
    'Geological',
    'Atmospheric',
  ];

  String? selectedGroup;
  List<String> categories = viewModel.orderedCategories;
  String selectedCategory = defaultCategories.first;
  List<String> categoryOptions = categories.isNotEmpty
      ? categories
      : defaultCategories;
  List<File> selectedMediaFiles = [];
  DateTime? startDate;
  TimeOfDay? startTime;
  DateTime? endDate;
  TimeOfDay? endTime;

  if (!context.mounted) return;
  showDialog(
    routeSettings: const RouteSettings(name: 'disable-accessibility-view'),
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Add New Event'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Title'),
                  ),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(labelText: 'Description'),
                  ),
                  TextField(
                    controller: latController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'Latitude'),
                  ),
                  TextField(
                    controller: longController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'Longitude'),
                  ),
                  const SizedBox(height: 8),
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
                  const SizedBox(height: 8),
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
                        ...groupOptions.map(
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
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          startDate == null
                              ? 'No start date'
                              : 'Start: ${startDate!.toString().split(' ')[0]} ${startTime?.format(context) ?? ''}',
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
                            if (!context.mounted) {
                              return;
                            }
                            final time = await showTimePicker(
                              context: context,
                              initialTime: startTime ?? TimeOfDay.now(),
                            );
                            if (time != null) {
                              setState(() {
                                startDate = date;
                                startTime = time;
                              });
                            }
                          }
                        },
                        child: const Text('Pick Start Date'),
                      ),
                    ],
                  ),
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
                            if (!context.mounted) {
                              return;
                            }
                            final time = await showTimePicker(
                              context: context,
                              initialTime: endTime ?? TimeOfDay.now(),
                            );
                            if (time != null) {
                              setState(() {
                                endDate = date;
                                endTime = time;
                              });
                            }
                          }
                        },
                        child: const Text('Pick End Date'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Media attachments section
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
                              final fileName = file.path.split('/').last;
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
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
                                        file.path.toLowerCase().endsWith(
                                          '.webp',
                                        ))
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
                                    IconButton(
                                      icon: const Icon(Icons.close, size: 14),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
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
                                  final file = await filePickerService
                                      .pickImage();
                                  if (file != null) {
                                    setState(() {
                                      selectedMediaFiles.add(file);
                                    });
                                  }
                                },
                                icon: const Icon(Icons.image, size: 14),
                                label: const Text('Image'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 6,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  final file = await filePickerService
                                      .pickFile();
                                  if (file != null) {
                                    setState(() {
                                      selectedMediaFiles.add(file);
                                    });
                                  }
                                },
                                icon: const Icon(Icons.attach_file, size: 14),
                                label: const Text('File'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 6,
                                  ),
                                ),
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
            actions: [
              TextButton(
                onPressed: () {
                  setState(() {
                    startDate = DateTime.now();
                    startTime = TimeOfDay.fromDateTime(startDate!);
                  });
                },
                child: const Text('Now'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  if (titleController.text.isNotEmpty &&
                      startDate != null &&
                      startTime != null) {
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
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('End date must be after Start date'),
                          ),
                        );
                        return;
                      }
                    }

                    final newEvent = EventModel(
                      eventId: DateTime.now().millisecondsSinceEpoch ~/ 1000,
                      category: selectedCategory,
                      startDt: finalStartDate,
                      endDt: finalEndDate,
                      author: 'User',
                      lat: double.tryParse(latController.text) ?? 0.0,
                      long: double.tryParse(longController.text) ?? 0.0,
                      title: titleController.text,
                      tag: '',
                      groupId: selectedGroup,
                      description: descriptionController.text,
                    );
                    viewModel.addEvent(newEvent);
                    Navigator.of(context).pop();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please fill all required fields'),
                      ),
                    );
                  }
                },
                child: const Text('Add'),
              ),
            ],
          );
        },
      );
    },
  );
}
