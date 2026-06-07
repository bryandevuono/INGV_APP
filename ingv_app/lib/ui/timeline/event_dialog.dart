import 'package:flutter/material.dart';
import 'package:ingv_app/data/models/event_model.dart';
import 'package:ingv_app/ui/map/view_models/timeline_view_model.dart';

void showAddEventDialog(BuildContext context, TimelineViewModel viewModel) {
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final latController = TextEditingController(text: '0.0');
  final longController = TextEditingController(text: '0.0');
  final defaultCategories = <String>[
    'Volcanic',
    'Earthquake',
    'Hydrological',
    'Meteorological',
    'Geological',
    'Atmospheric',
  ];
  final categoryOptions = <String>[
    ...viewModel.categories.where((category) => category != 'All'),
  ];
  if (categoryOptions.isEmpty) {
    categoryOptions.addAll(defaultCategories);
  }
  String selectedCategory = categoryOptions.first;
  DateTime? startDate;
  TimeOfDay? startTime;
  DateTime? endDate;
  TimeOfDay? endTime;

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
