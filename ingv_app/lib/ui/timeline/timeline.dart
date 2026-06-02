import 'package:legacy_gantt_chart/legacy_gantt_chart.dart';
import 'package:flutter/material.dart';
import 'package:ingv_app/data/repositories/event_repository.dart';
import 'package:ingv_app/ui/map/view_models/timeline_view_model.dart';
import 'timeline_interface.dart';
import 'package:ingv_app/data/models/event_model.dart';

class TimelineScreen extends StatefulWidget {
  final EventRepository eventRepository;
  const TimelineScreen({super.key, required this.eventRepository});

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> implements ITimeline {
  late final TimelineViewModel _viewModel;

  // TODO: Place somewhere else non hard coded
  final Map<String, Color> cellColors = {
    "Volcanic": Colors.red,
    "Earthquake": Colors.green,
    "Hydrological": Colors.blue,
    "Meteorological": Colors.orange,
    "Geological": Colors.purple,
    "Atmospheric": Colors.cyan,
  };

  @override
  void initState() {
    super.initState();
    _viewModel = TimelineViewModel(widget.eventRepository);
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    await _viewModel.fetchEvents();
  }

  // TODO: Calculate start date based on earliest event
  final startDate = DateTime(2026, 5, 31);

  @override
  StatefulWidget buildEventContainer(String eventId) {
    EventModel event = _viewModel.events.firstWhere(
      (e) => e.eventId.toString() == eventId,
    );

    final duration = event.endDt != null
        ? "${event.endDt!.difference(event.startDt).inHours} hrs"
        : "Ongoing";
    final endString = event.endDt != null ? event.endDt.toString() : '...';

    return Tooltip(
      message:
          "${event.title}\n${event.startDt} - $endString\nDuration: $duration",
      child: Container(
        alignment: Alignment.topLeft,
        padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
        color: cellColors[event.category] ?? Colors.grey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              event.title,
              textAlign: TextAlign.left,
              style: const TextStyle(color: Colors.white),
            ),
            Wrap(
              spacing: 6,
              children: [
                Text(
                  "${event.startDt} - $endString",
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  duration,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  StatefulWidget buildTimeline(events) {
    final tasks = [
      for (final event in events)
        LegacyGanttTask(
          id: event.eventId.toString(),
          rowId: event.category,
          name: event.title,
          start: event.startDt,
          end:
              event.endDt ??
              event.startDt.add(
                const Duration(hours: 1),
              ), // Provide a default end
          color: cellColors[event.category] ?? Colors.grey,
        ),
    ];

    final rows = [
      for (final category in _viewModel.categories)
        LegacyGanttRow(id: category, label: category),
    ];

    final rowMaxStackDepth = <String, int>{
      for (final category in _viewModel.categories) category: 1,
    };

    _viewModel.getEventDateRange();
    DateTime minStart = _viewModel.minStart;

    final rangeStart = startDate.isBefore(minStart) ? startDate : minStart;
    final rangeEnd = rangeStart.add(const Duration(days: 2));
    final totalStart = rangeStart.subtract(const Duration(days: 1));
    final totalEnd = rangeEnd.add(const Duration(days: 1));

    return LegacyGanttChartWidget(
      data: tasks,
      visibleRows: rows,
      rowMaxStackDepth: rowMaxStackDepth,
      rowHeight: 70.0,
      axisHeight: 27.0,
      gridMin: rangeStart.millisecondsSinceEpoch.toDouble(),
      gridMax: rangeEnd.millisecondsSinceEpoch.toDouble(),
      totalGridMin: totalStart.millisecondsSinceEpoch.toDouble(),
      totalGridMax: totalEnd.millisecondsSinceEpoch.toDouble(),
      taskBarBuilder: (task) {
        return buildEventContainer(task.id);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        if (_viewModel.events.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SizedBox(
                    width: 200,
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    color: Colors.blue,
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      _showAddEventDialog();
                    },
                  ),
                ],
              ),
            ),
            Expanded(child: buildTimeline(_viewModel.events)),
          ],
        );
      },
    );
  }

  void _showAddEventDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final latController = TextEditingController(text: '0.0');
    final longController = TextEditingController(text: '0.0');
    DateTime? startDate;
    TimeOfDay? startTime;
    DateTime? endDate;
    TimeOfDay? endTime;

    showDialog(
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
                      decoration: const InputDecoration(
                        labelText: 'Description',
                      ),
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
                              initialDate:
                                  endDate ?? startDate ?? DateTime.now(),
                              firstDate: startDate ?? DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (date != null) {
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
                              content: Text(
                                'End date must be after Start date',
                              ),
                            ),
                          );
                          return;
                        }
                      }

                      final newEvent = EventModel(
                        eventId: DateTime.now().millisecondsSinceEpoch ~/ 1000,
                        category: _viewModel.categories.isNotEmpty
                            ? _viewModel.categories.first
                            : 'Volcanic',
                        startDt: finalStartDate,
                        endDt: finalEndDate,
                        author: 'User',
                        lat: double.tryParse(latController.text) ?? 0.0,
                        long: double.tryParse(longController.text) ?? 0.0,
                        title: titleController.text,
                        tag: '',
                        description: descriptionController.text,
                      );
                      _viewModel.addEvent(newEvent);
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
}
