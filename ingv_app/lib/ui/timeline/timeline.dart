import 'package:legacy_gantt_chart/legacy_gantt_chart.dart';
import 'package:flutter/material.dart';
import 'package:ingv_app/data/repositories/event_repository.dart';
import 'package:ingv_app/data/repositories/attachment_repository.dart';
import 'package:ingv_app/data/repositories/event_detail_repository.dart';
import 'package:ingv_app/ui/map/view_models/timeline_view_model.dart';
import 'timeline_interface.dart';
import 'package:ingv_app/data/models/event_model.dart';
import 'package:ingv_app/data/services/event_detail_service.dart';
import 'package:ingv_app/data/services/file_operations_service.dart';
import 'add_event_dialog.dart';
import '../search.dart';
import 'package:ingv_app/ui/event_detail/view_models/event_detail_view_model.dart';
import 'package:ingv_app/ui/event_detail/widgets/event_detail_panel.dart';

class TimelineScreen extends StatefulWidget {
  final EventRepository eventRepository;
  const TimelineScreen({super.key, required this.eventRepository});

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> implements ITimeline {
  late final TimelineViewModel _viewModel;
  late final EventDetailViewModel _detailViewModel;
  EventModel? _selectedEvent;

  final startDate = DateTime.now().subtract(const Duration(days: 1));
  final Map<String, ScrollController> _laneControllers = {};

  
  @override
  void initState() {
    super.initState();
    _viewModel = TimelineViewModel(widget.eventRepository);
    _viewModel.getColors();
    _detailViewModel = EventDetailViewModel(
      EventDetailRepository(EventDetailService()),
      LocalAttachmentRepository(),
      LocalFileService(),
      FileOpenService(),
      widget.eventRepository,
    );
    _loadEvents();
    _loadGroups();
  }

  Future<void> _loadEvents() async {
    await _viewModel.fetchEvents();
  }

  Future<void> _loadGroups() async {
    await _viewModel.getGroupsOfUser();
  }

  Future<void> _toggleEventDetails(EventModel event) async {
    if (_selectedEvent != null && _selectedEvent!.eventId == event.eventId) {
      setState(() {
        _selectedEvent = null;
      });
      _detailViewModel.clearEventDetails();
      return;
    }

    setState(() {
      _selectedEvent = event;
    });
    await _detailViewModel.loadEventDetails(event);
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
      child: GestureDetector(
        onTap: () => _toggleEventDetails(event),
        child: Tooltip(
          message:
              "${event.title}\n${event.startDt} - $endString\nDuration: $duration",
          child: Container(
            alignment: Alignment.topLeft,
            height: 45.0,
            padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
            decoration: BoxDecoration(
              color: _viewModel.categoryColors.firstWhere(
                (entry) => entry.key == event.category,
                orElse: () => MapEntry(event.category, Colors.grey),
              ).value,
              border: _selectedEvent?.eventId == event.eventId
                  ? Border.all(color: Colors.white, width: 2)
                  : null,
            ),
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
      ),
    );
  }

  @override
  Widget buildTimeline(List<EventModel> eventList) {
    if (eventList.isEmpty || _viewModel.orderedCategories.isEmpty) {
      return Center(
        child: Text(
          _viewModel.searchQuery.isNotEmpty ||
                  _viewModel.selectedCategory != 'All' ||
                  _viewModel.filterStartDate != null
              ? 'No events match the current filters'
              : 'No events yet. Use + to add the first event.',
          style: const TextStyle(fontSize: 16, color: Colors.black54),
        ),
      );
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
      onReorder: (oldIndex, newIndex) {
        _viewModel.reorderCategories(oldIndex, newIndex);
      },
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      itemCount: _viewModel.orderedCategories.length,
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
            .where((e) => e.category.trim() == category)
            .toList();

        final singleRow = [LegacyGanttRow(id: category, label: category)];

        final laneTasks = laneEvents.map((event) {
          return LegacyGanttTask(
            id: event.eventId.toString(),
            rowId: category,
            name: event.title,
            start: event.startDt,
            end: event.endDt ?? event.startDt.add(const Duration(hours: 1)),
            color: _viewModel.categoryColors.firstWhere(
              (entry) => entry.key == event.category,
              orElse: () => MapEntry(event.category, Colors.grey),
            ).value,
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
        return Stack(
          children: [
            Column(
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
                                items: _viewModel.categories.map((
                                  String value,
                                ) {
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
                                              start:
                                                  _viewModel.filterStartDate!,
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
                            Search(viewModel: _viewModel)
                          ],
                        ),
                      ),
                      IconButton(
                        color: Colors.blue,
                        icon: const Icon(Icons.add),
                        onPressed: () =>
                          showAddEventDialog(context, _viewModel, _viewModel.groupOptions),
                      ),
                    ],
                  ),
                ),
                Expanded(child: buildTimeline(_viewModel.events)),
              ],
            ),
            if (_selectedEvent != null)
              EventDetailPanel(
                viewModel: _detailViewModel,
                onDismiss: () {
                  setState(() {
                    _selectedEvent = null;
                  });
                  _detailViewModel.clearEventDetails();
                },
              ),
          ],
        );
      },
    );
  }
}
