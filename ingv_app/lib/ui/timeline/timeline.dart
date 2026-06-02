import 'package:legacy_gantt_chart/legacy_gantt_chart.dart';
import 'package:flutter/material.dart';
import 'package:ingv_app/data/repositories/event_repository.dart';
import 'package:ingv_app/ui/map/view_models/timeline_view_model.dart';
import 'timeline_interface.dart';
import 'package:ingv_app/data/models/event_model.dart';
import 'event_dialog.dart';

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

    final displayCategories = _viewModel.categories
        .where((c) => c != 'All')
        .toList();

    final rows = [
      for (final category in displayCategories)
        LegacyGanttRow(id: category, label: category),
    ];

    final rowMaxStackDepth = <String, int>{
      for (final category in displayCategories) category: 1,
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Filter Section
                  Expanded(
                    child: Wrap(
                      spacing: 12.0,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        SizedBox(
                          width: 200,
                          child: TextField(
                            onChanged: _viewModel.setSearchQuery,
                            decoration: InputDecoration(
                              hintText: 'Search (keywords, tags)...',
                              prefixIcon: const Icon(Icons.search),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 0,
                              ),
                            ),
                          ),
                        ),
                        if (_viewModel.categories.isNotEmpty)
                          DropdownButton<String>(
                            value: _viewModel.selectedCategory,
                            items: _viewModel.categories.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (newValue) {
                              if (newValue != null) {
                                _viewModel.setCategoryFilter(newValue);
                              }
                            },
                          ),
                        TextButton.icon(
                          icon: const Icon(Icons.date_range),
                          label: Text(
                            _viewModel.filterStartDate == null
                                ? 'Filter by Date'
                                : '${_viewModel.filterStartDate!.toLocal().toString().split(' ')[0]} - ${_viewModel.filterEndDate?.toLocal().toString().split(' ')[0] ?? 'Any'}',
                          ),
                          onPressed: () async {
                            final DateTimeRange? picked =
                                await showDateRangePicker(
                                  context: context,
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2101),
                                  initialDateRange:
                                      _viewModel.filterStartDate != null &&
                                          _viewModel.filterEndDate != null
                                      ? DateTimeRange(
                                          start: _viewModel.filterStartDate!,
                                          end: _viewModel.filterEndDate!,
                                        )
                                      : null,
                                );
                            if (picked != null) {
                              _viewModel.setDateRangeFilter(
                                picked.start,
                                picked.end,
                              );
                            } else {
                              // If user cancels, maybe clear filter? Uncomment to clear on cancel
                              // _viewModel.setDateRangeFilter(null, null);
                            }
                          },
                        ),
                        if (_viewModel.filterStartDate != null)
                          IconButton(
                            icon: const Icon(Icons.clear),
                            tooltip: 'Clear Date Filter',
                            onPressed: () =>
                                _viewModel.setDateRangeFilter(null, null),
                          ),
                      ],
                    ),
                  ),
                  // Add Event Button
                  IconButton(
                    color: Colors.blue,
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      showAddEventDialog(context, _viewModel);
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: _viewModel.events.isEmpty
                  ? const Center(
                      child: Text('No events match the current filters'),
                    )
                  : buildTimeline(_viewModel.events),
            ),
          ],
        );
      },
    );
  }

  }
