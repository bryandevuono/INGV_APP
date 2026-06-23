import 'package:flutter/material.dart';
import 'package:ingv_app/data/models/event_model.dart';
import 'package:ingv_app/data/models/group_model.dart';
import 'package:ingv_app/data/repositories/event_repository.dart';
import 'package:ingv_app/ui/event_detail/view_models/edit_event_view_model.dart';

Future<EventModel?> showEditEventDialog(
  BuildContext context, {
  required EventModel event,
  required IEventRepository eventRepository,
  List<GroupModel> groupOptions = const [],
}) {
  return showDialog<EventModel>(
    context: context,
    builder: (context) {
      return _EditEventDialog(
        event: event,
        eventRepository: eventRepository,
        groupOptions: groupOptions,
      );
    },
  );
}

class _EditEventDialog extends StatefulWidget {
  final EventModel event;
  final IEventRepository eventRepository;
  final List<GroupModel> groupOptions;

  const _EditEventDialog({
    required this.event,
    required this.eventRepository,
    required this.groupOptions,
  });

  @override
  State<_EditEventDialog> createState() => _EditEventDialogState();
}

class _EditEventDialogState extends State<_EditEventDialog> {
  late final EditEventViewModel _viewModel;
  final List<String> _defaultCategories = const [
    'Volcanic',
    'Earthquake',
    'Hydrological',
    'Meteorological',
    'Geological',
    'Atmospheric',
  ];

  @override
  void initState() {
    super.initState();
    _viewModel = EditEventViewModel(
      eventRepository: widget.eventRepository,
      originalEvent: widget.event,
      groupOptions: widget.groupOptions,
    );
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _pickStartDateTime() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _viewModel.startDateTime ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (selectedDate == null || !mounted) {
      return;
    }

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        _viewModel.startDateTime ?? DateTime.now(),
      ),
    );
    if (selectedTime == null || !mounted) {
      return;
    }

    _viewModel.setStartDateTime(
      DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedTime.hour,
        selectedTime.minute,
      ),
    );
  }

  Future<void> _pickEndDateTime() async {
    final initialStart = _viewModel.startDateTime ?? DateTime.now();
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _viewModel.endDateTime ?? initialStart,
      firstDate: initialStart,
      lastDate: DateTime(2100),
    );
    if (selectedDate == null || !mounted) {
      return;
    }

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        _viewModel.endDateTime ?? _viewModel.startDateTime ?? DateTime.now(),
      ),
    );
    if (selectedTime == null || !mounted) {
      return;
    }

    _viewModel.setEndDateTime(
      DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedTime.hour,
        selectedTime.minute,
      ),
    );
  }

  Widget _buildDateRow({
    required String label,
    required DateTime? value,
    required VoidCallback onPick,
    VoidCallback? onClear,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            value == null
                ? 'No ${label.toLowerCase()}'
                : '${value.toLocal().toString().split(' ')[0]} ${TimeOfDay.fromDateTime(value).format(context)}',
          ),
        ),
        TextButton(
          onPressed: _viewModel.isSaving ? null : onPick,
          child: Text('Pick $label'),
        ),
        if (onClear != null)
          TextButton(
            onPressed: _viewModel.isSaving ? null : onClear,
            child: const Text('Clear'),
          ),
      ],
    );
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

    final selectedGroupId = _viewModel.selectedGroupId;
    if (selectedGroupId != null && seenGroupIds.add(selectedGroupId)) {
      items.add(
        DropdownMenuItem<String?>(
          value: selectedGroupId,
          child: Text('Unknown group ($selectedGroupId)'),
        ),
      );
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    final currentCategory =
        _defaultCategories.contains(_viewModel.categoryController.text)
        ? _viewModel.categoryController.text
        : _defaultCategories.first;
    final categoryItems = {
      ..._defaultCategories,
      if (!_defaultCategories.contains(_viewModel.categoryController.text))
        _viewModel.categoryController.text,
    }.toList();

    return AlertDialog(
      title: const Text('Edit Event'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 560,
          child: ListenableBuilder(
            listenable: _viewModel,
            builder: (context, _) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _viewModel.titleController,
                    enabled: !_viewModel.isSaving,
                    decoration: InputDecoration(
                      labelText: 'Title',
                      border: const OutlineInputBorder(),
                      errorText: _viewModel.titleError,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _viewModel.descriptionController,
                    enabled: !_viewModel.isSaving,
                    maxLines: 1,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _viewModel.latitudeController,
                    enabled: !_viewModel.isSaving,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Latitude',
                      border: const OutlineInputBorder(),
                      errorText: _viewModel.latitudeError,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _viewModel.longitudeController,
                    enabled: !_viewModel.isSaving,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Longitude',
                      border: const OutlineInputBorder(),
                      errorText: _viewModel.longitudeError,
                    ),
                  ),
                  const SizedBox(height: 8),
                  InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Category',
                      border: const OutlineInputBorder(),
                      errorText: _viewModel.categoryError,
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: currentCategory,
                        isExpanded: true,
                        items: categoryItems
                            .map(
                              (category) => DropdownMenuItem<String>(
                                value: category,
                                child: Text(category),
                              ),
                            )
                            .toList(),
                        onChanged: _viewModel.isSaving
                            ? null
                            : (value) {
                                if (value != null) {
                                  _viewModel.setCategory(value);
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
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String?>(
                        value: _viewModel.selectedGroupId,
                        isExpanded: true,
                        items: _buildGroupItems(),
                        onChanged: _viewModel.isSaving
                            ? null
                            : (value) => _viewModel.setGroupId(value),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _viewModel.authorController,
                    enabled: false,
                    decoration: const InputDecoration(
                      labelText: 'Author',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildDateRow(
                    label: 'Start date/time',
                    value: _viewModel.startDateTime,
                    onPick: _pickStartDateTime,
                  ),
                  if (_viewModel.startError != null)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          _viewModel.startError!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  _buildDateRow(
                    label: 'End date/time',
                    value: _viewModel.endDateTime,
                    onPick: _pickEndDateTime,
                    onClear: _viewModel.endDateTime == null
                        ? null
                        : () => _viewModel.setEndDateTime(null),
                  ),
                  if (_viewModel.endError != null)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          _viewModel.endError!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  if (_viewModel.generalError != null) ...[
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _viewModel.generalError!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _viewModel.isSaving
              ? null
              : () {
                  _viewModel.setStartDateTime(DateTime.now());
                  _viewModel.setEndDateTime(null);
                },
          child: const Text('Now'),
        ),
        TextButton(
          onPressed: _viewModel.isSaving
              ? null
              : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _viewModel.isSaving
              ? null
              : () async {
                  final updatedEvent = await _viewModel.save();
                  if (!context.mounted || updatedEvent == null) {
                    return;
                  }
                  Navigator.of(context).pop(updatedEvent);
                },
          child: _viewModel.isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}
