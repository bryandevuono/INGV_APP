import 'package:flutter/material.dart';
import 'package:legacy_gantt_chart/legacy_gantt_chart.dart';
import 'package:ingv_app/data/models/event_model.dart';
import 'package:ingv_app/data/models/timeline_presentation_models.dart';
import 'package:ingv_app/ui/event_detail/view_models/event_detail_view_model.dart';
import 'package:ingv_app/ui/timeline/view_models/timeline_interface.dart';
import 'package:ingv_app/ui/event_detail/widgets/event_detail_panel.dart';
import 'add_event_dialog.dart';
import 'package:ingv_app/ui/search.dart';

class TimelineScreen extends StatefulWidget {
  final ITimelineViewModel viewModel;
  final EventDetailViewModel detailViewModel;

  const TimelineScreen({
    super.key,
    required this.viewModel,
    required this.detailViewModel,
  });

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  EventModel? _selectedEvent;

  DateTime _clientBaselineStart = DateTime.now().subtract(
    const Duration(days: 1),
  );

  @override
  void initState() {
    super.initState();
    _refreshInitialData();
  }

  void dispose() {
    super.dispose();
  }
  
  Future<void> _refreshInitialData() async {
    await widget.viewModel.getColors();
    await widget.viewModel.fetchEvents();
    await widget.viewModel.getGroupsOfUser();
  }

  Future<void> _toggleEventDetails(EventModel event) async {
    if (_selectedEvent != null && _selectedEvent!.eventId == event.eventId) {
      setState(() => _selectedEvent = null);
      widget.detailViewModel.clearEventDetails();
      return;
    }

    setState(() => _selectedEvent = event);
    await widget.detailViewModel.loadEventDetails(event);
  }

  // Helper methods to shift the baseline date window
  void _navigateToPast() {
    setState(() {
      _clientBaselineStart = _clientBaselineStart.subtract(
        const Duration(days: 7),
      );
    });
  }

  void _navigateToFuture() {
    setState(() {
      _clientBaselineStart = _clientBaselineStart.add(const Duration(days: 7));
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        return Stack(
          children: [
            Column(
              children: [
                _buildToolbar(context),
                Expanded(child: _buildTimelineCanvas(widget.viewModel.events)),
              ],
            ),
            if (_selectedEvent != null)
              EventDetailPanel(
                viewModel: widget.detailViewModel,
                groupOptions: widget.viewModel.userGroups,
                onDismiss: () {
                  setState(() => _selectedEvent = null);
                  widget.detailViewModel.clearEventDetails();
                },
              ),
          ],
        );
      },
    );
  }

  Widget _buildToolbar(BuildContext context) {
    return Padding(
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
                if (widget.viewModel.orderedCategories.isNotEmpty)
                  DropdownButton<String>(
                    value: widget.viewModel.selectedCategory,
                    items: ['All', ...widget.viewModel.orderedCategories]
                        .toSet()
                        .map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        })
                        .toList(),
                    onChanged: (newValue) {
                      if (newValue != null) {
                        widget.viewModel.setCategoryFilter(newValue);
                      }
                    },
                  ),

                TextButton.icon(
                  icon: const Icon(Icons.date_range),
                  label: Text(
                    widget.viewModel.filterStartDate == null
                        ? 'Filter by Date'
                        : '${widget.viewModel.filterStartDate!.toLocal().toString().split(' ')[0]} - ${widget.viewModel.filterEndDate?.toLocal().toString().split(' ')[0] ?? 'Any'}',
                  ),
                  onPressed: () async {
                    final DateTimeRange? picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2101),
                      initialDateRange:
                          widget.viewModel.filterStartDate != null &&
                              widget.viewModel.filterEndDate != null
                          ? DateTimeRange(
                              start: widget.viewModel.filterStartDate!,
                              end: widget.viewModel.filterEndDate!,
                            )
                          : null,
                    );
                    if (picked != null) {
                      widget.viewModel.setDateRangeFilter(
                        picked.start,
                        picked.end,
                      );
                      // Sync baseline to the user selection
                      setState(() {
                        _clientBaselineStart = picked.start;
                      });
                    }
                  },
                ),
                // Backwards navigation button
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  tooltip: 'Previous 7 Days',
                  onPressed: _navigateToPast,
                ),
                // Forwards navigation button
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  tooltip: 'Next 7 Days',
                  onPressed: _navigateToFuture,
                ),

                if (widget.viewModel.filterStartDate != null)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    tooltip: 'Clear Date Filter',
                    onPressed: () {
                      widget.viewModel.setDateRangeFilter(null, null);
                      setState(() {
                        _clientBaselineStart = DateTime.now().subtract(
                          const Duration(days: 7),
                        );
                      });
                    },
                  ),
                _buildExportButton(
                  icon: const Icon(Icons.download),
                  label: 'Export PDF',
                  loadingLabel: 'Exporting...',
                  onTap: () => widget.viewModel.exportTimelineReport(),
                ),
                _buildExportButton(
                  icon: const Icon(Icons.folder_zip),
                  label: 'Export ZIP',
                  loadingLabel: 'Archiving...',
                  onTap: () => widget.viewModel.exportTimelineAsZip(),
                ),
                Search(viewModel: widget.viewModel),
              ],
            ),
          ),
          IconButton(
            color: Colors.blue,
            icon: const Icon(Icons.add),
            onPressed: () => showAddEventDialog(
              context,
              widget.viewModel,
              widget.viewModel.userGroups,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportButton({
    required Widget icon,
    required String label,
    required String loadingLabel,
    required Future<String?> Function() onTap,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    return TextButton.icon(
      onPressed: widget.viewModel.isExporting
          ? null
          : () async {
              final exportPath = await onTap();
              if (!mounted) return;

              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    exportPath != null
                        ? '$label Complete: $exportPath'
                        : (widget.viewModel.exportErrorMessage ??
                              'Action execution dropped.'),
                  ),
                ),
              );
            },
      icon: widget.viewModel.isExporting
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : icon,
      label: Text(widget.viewModel.isExporting ? loadingLabel : label),
    );
  }

  Widget _buildTimelineCanvas(List<EventModel> eventList) {
    final lanes = widget.viewModel.timelineLanes;

    if (eventList.isEmpty || lanes.isEmpty) {
      return Center(
        child: Text(
          widget.viewModel.searchQuery.isNotEmpty ||
                  widget.viewModel.selectedCategory != 'All' ||
                  widget.viewModel.filterStartDate != null
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

    // calc the start and end   
    final DateTime rangeStart =
    widget.viewModel.filterStartDate ?? _clientBaselineStart; 
    final DateTime rangeEnd =
    widget.viewModel.filterEndDate ??
    rangeStart.add(const Duration(days: 7));

    // boundaries
    final DateTime totalStart = rangeStart.subtract(const Duration(days: 2));
    final DateTime totalEnd = rangeEnd.add(const Duration(days: 2));

    return ReorderableListView.builder(
      buildDefaultDragHandles: false,
      onReorder: (old, current) =>
          widget.viewModel.reorderCategories(old, current),
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      itemCount: lanes.length,
      itemBuilder: (context, index) {
        final lane = lanes[index];
        final isFirstRow = index == 0;
        final isMinimized = widget.viewModel.isCategoryMinimized(lane.id);
        final double definedRowHeight = isMinimized
            ? minimizedRowHeight
            : expandedRowHeight;

        final List<TimelineTaskData> genericTasks = widget.viewModel
            .getTimelineTasksForCategory(lane.id);

        final packageRows = [LegacyGanttRow(id: lane.id, label: lane.label)];

        final packageTasks = genericTasks.map((task) {
          final DateTime finalEnd;
          if (task.start == task.end || task.end == null) {
            finalEnd = task.start.add(const Duration(hours: 1));
          } else {
            finalEnd = task.end;
          }
          return LegacyGanttTask(
            id: task.id,
            rowId: task.laneId,
            name: task.title,
            start: task.start,
            end: finalEnd,
            color: task.color,
          );
        }).toList();

        final rowMaxStackDepth = <String, int>{lane.id: 2};
        final double fullWidgetHeight = definedRowHeight + baseAxisHeight;
        final double visibleViewportHeight = isFirstRow
            ? fullWidgetHeight
            : definedRowHeight;

        Widget chartSection = SizedBox(
          width: totalCanvasWidth,
          height: fullWidgetHeight,
          child: LegacyGanttChartWidget(
            data: packageTasks,
            visibleRows: packageRows,
            rowMaxStackDepth: rowMaxStackDepth,
            rowHeight: definedRowHeight,
            axisHeight: baseAxisHeight,
            gridMin: rangeStart.millisecondsSinceEpoch.toDouble(),
            gridMax: rangeEnd.millisecondsSinceEpoch.toDouble(),
            totalGridMin: totalStart.millisecondsSinceEpoch.toDouble(),
            totalGridMax: totalEnd.millisecondsSinceEpoch.toDouble(),
            taskBarBuilder: (task) {
              if (isMinimized) return const SizedBox.shrink();
              return _buildEventContainer(task.id);
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
                onPressed: () =>
                    widget.viewModel.toggleCategoryMinimized(lane.id),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  lane.label,
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
          key: ValueKey('row_wrapper_${lane.id}'),
          children: [
            Row(
              children: [
                leftHeader,
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
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

  Widget _buildEventContainer(String eventId) {
    final EventModel event = widget.viewModel.events.firstWhere(
      (e) => e.eventId.toString() == eventId,
    );

    final String duration;
    final String endString;
    final String startStringTime = event.startDt
        .toLocal()
        .toString()
        .split(' ')[1]
        .substring(0, 5);

    final String endStringTime = event.endDt != null
        ? event.endDt!.toLocal().toString().split(' ')[1].substring(0, 5)
        : '';

    if (event.endDt != null) {
      duration = "${event.endDt!.difference(event.startDt).inHours} hrs";
      endString = event.endDt.toString();
    } else {
      duration = "Ongoing";
      endString = '...';
    }
    final Color itemColor = widget.viewModel
        .getTimelineTasksForCategory(event.category.trim())
        .firstWhere((t) => t.id == eventId)
        .color;

    return Align(
      alignment: Alignment.centerLeft,
      child: GestureDetector(
        onTap: () => _toggleEventDetails(event),
        child: Tooltip(
          message:
              "${event.title}\n${event.startDt} - $endString\nDuration: $duration",
          child: event.endDt == null
              ? OverflowBox(
                  minWidth: 24.0,
                  maxWidth: 24.0,
                  minHeight: 24.0,
                  maxHeight: 24.0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: itemColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                      border: _selectedEvent?.eventId == event.eventId
                          ? Border.all(color: Colors.white, width: 2)
                          : Border.all(color: Colors.white, width: 1),
                    ),
                  ),
                )
              : Container(
                  alignment: Alignment.topLeft,
                  height: 45.0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6.0,
                    vertical: 4.0,
                  ),
                  decoration: BoxDecoration(
                    color: itemColor,
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
                      Row(
                        spacing: 8.0,
                        children: [
                          Text(
                            '$startStringTime - $endStringTime',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 9,
                            ),
                          ),
                          Text(
                            duration,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
