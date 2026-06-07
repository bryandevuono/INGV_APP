import 'package:legacy_gantt_chart/legacy_gantt_chart.dart';
import 'package:flutter/material.dart';
import 'package:ingv_app/data/repositories/event_repository.dart';
import 'package:ingv_app/ui/map/view_models/timeline_view_model.dart';
import 'timeline_interface.dart';
import 'package:ingv_app/data/models/event_model.dart';
import 'add_event_dialog.dart';

class TimelineScreen extends StatefulWidget {
  final EventRepository eventRepository;
  const TimelineScreen({super.key, required this.eventRepository});

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> implements ITimeline {
  late final TimelineViewModel _viewModel;

  // TODO: shouldn't be hardcoded here, after SQL migration 
  final Map<String, Color> cellColors = {
    "Volcanic": Colors.red,
    "Earthquake": Colors.green,
    "Hydrological": Colors.blue,
    "Meteorological": Colors.orange,
    "Geological": Colors.purple,
    "Atmospheric": Colors.cyan,
  };

  final startDate = DateTime.now().subtract(const Duration(days: 1));
  final Map<String, ScrollController> _laneControllers = {};

  @override
  void initState() {
    super.initState();
    _viewModel = TimelineViewModel(widget.eventRepository);
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    await _viewModel.fetchEvents();
  }

  @override
  void dispose() {
    for (final controller in _laneControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget buildEventContainer(String eventId) {
    EventModel event = _viewModel.events.firstWhere(
      (e) => e.eventId.toString() == eventId,
    );

    final String duration;
      
    if (event.endDt != null) {
      duration = "${event.endDt!.difference(event.startDt).inHours} hrs";
    } else {
      duration = "Ongoing";
    }

    final String endString;
    if (event.endDt != null) {
      endString = event.endDt.toString();
    } else {
      endString = '...';
    }

    // colored boxes
    return Align(
      alignment: Alignment.centerLeft,
      child: Tooltip(
        message: "${event.title}\n${event.startDt} - $endString\nDuration: $duration",
        child: Container(
          alignment: Alignment.topLeft,
          height: 45.0,
          padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
          color: cellColors[event.category] ?? Colors.grey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                event.title,
                textAlign: TextAlign.left,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                duration,
                style: const TextStyle(color: Colors.white70, fontSize: 9),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget buildTimeline(List<EventModel> eventList) {
    if (_viewModel.categories.isEmpty) {
      return const Center(child: Text('No events match the current filters'));
    }

    const double expandedRowHeight = 140.0;
    const double minimizedRowHeight = 35.0;
    const double baseAxisHeight = 27.0;
    const double totalCanvasWidth = 1200.0;
    const double leftHeaderWidth = 160.0;

    _viewModel.getEventDateRange();
    DateTime minStart = _viewModel.minStart;
    final rangeStart = startDate.isBefore(minStart) ? startDate : minStart;
    final rangeEnd = rangeStart.add(const Duration(days: 2));
    final totalStart = rangeStart.subtract(const Duration(days: 1));
    final totalEnd = rangeEnd.add(const Duration(days: 1));

    return ReorderableListView.builder(
      // multiple chart rows
      buildDefaultDragHandles: false,
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      itemCount: _viewModel.orderedCategories.length,
      onReorder: _viewModel.reorderCategories,
      itemBuilder: (context, index) {
        final category = _viewModel.orderedCategories[index];
        final isFirstRow = index == 0;
        final isMinimized = _viewModel.isCategoryMinimized(category);

        final double definedRowHeight;
        
        if (isMinimized) {
          definedRowHeight = minimizedRowHeight;
        } else {
          definedRowHeight = expandedRowHeight;
        }

        final laneEvents = eventList
            .where((e) => (e.category?.toString().trim() ?? '') == category)
            .toList();

        final singleRow = [LegacyGanttRow(id: category, label: category)];

        final laneTasks = laneEvents.map((event) {
          return LegacyGanttTask(
            id: event.eventId.toString(),
            rowId: category,
            name: event.title,
            start: event.startDt,
            end: event.endDt ?? event.startDt.add(const Duration(hours: 1)),
            color: cellColors[category] ?? Colors.grey,
          );
        }).toList();

        final rowMaxStackDepth = <String, int>{category: 2};
        final double fullWidgetHeight = definedRowHeight + baseAxisHeight;
        final double visibleViewportHeight;
        
        // different height for first row to show axis labels
        if (isFirstRow) {
          visibleViewportHeight = fullWidgetHeight;
        } else {
          visibleViewportHeight = definedRowHeight;
        }

        Widget chartSection = SizedBox(
          width: totalCanvasWidth,
          height: fullWidgetHeight,
          child: LegacyGanttChartWidget(
            data: laneTasks,
            visibleRows: singleRow,
            rowMaxStackDepth: rowMaxStackDepth,
            rowHeight: definedRowHeight,
            axisHeight: baseAxisHeight,
            gridMin: rangeStart.millisecondsSinceEpoch.toDouble(),
            gridMax: rangeEnd.millisecondsSinceEpoch.toDouble(),
            totalGridMin: totalStart.millisecondsSinceEpoch.toDouble(),
            totalGridMax: totalEnd.millisecondsSinceEpoch.toDouble(),
            taskBarBuilder: (task) {
              if (isMinimized) return const SizedBox.shrink();
              return buildEventContainer(task.id);
            },
          ),
        );

        if (!isFirstRow) {
          chartSection = ClipRect(
            child: SizedBox(
              width: totalCanvasWidth,
              height: visibleViewportHeight,
              child: OverflowBox(
                minHeight: fullWidgetHeight,
                maxHeight: fullWidgetHeight,
                alignment: Alignment.bottomCenter,
                child: chartSection,
              ),
            ),
          );
        }

        //draggable headers
        Widget leftHeader = Container(
          width: leftHeaderWidth,
          height: visibleViewportHeight,
          padding: EdgeInsets.only(
            left: 4.0,
            right: 4.0,
            top: isFirstRow ? baseAxisHeight : 0.0,
          ),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            border: Border(right: BorderSide(color: Colors.grey.shade300)),
          ),
          child: Row(
            children: [
              ReorderableDragStartListener(
                index: index,
                child: const Icon(
                  Icons.drag_indicator,
                  size: 20,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: Icon(
                  isMinimized ? Icons.chevron_right : Icons.expand_more,
                  size: 20,
                  color: Colors.black54,
                ),
                tooltip: isMinimized ? 'Expand lane' : 'Minimize lane',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => _viewModel.toggleCategoryMinimized(category),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  category,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );

        return Column(
          key: ValueKey('row_wrapper_$category'),
          children: [
            Row(
              children: [
                leftHeader,
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: totalCanvasWidth,
                      height: visibleViewportHeight,
                      child: chartSection,
                    ),
                  ),
                ),
              ],
            ),
            Divider(color: Colors.grey.shade300, thickness: 1.0, height: 4.0),
          ],
        );
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
                  Expanded(
                    child: Wrap(
                      spacing: 12.0,
                      runSpacing: 8.0,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
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
                      ],
                    ),
                  ),
                  IconButton(
                    color: Colors.blue,
                    icon: const Icon(Icons.add),
                    onPressed: () => showAddEventDialog(context, _viewModel),
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
}