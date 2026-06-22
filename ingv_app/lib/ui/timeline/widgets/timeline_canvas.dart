import 'package:flutter/material.dart';
import 'package:legacy_gantt_chart/legacy_gantt_chart.dart';
import 'package:ingv_app/data/models/event_model.dart';
import 'package:ingv_app/data/models/timeline_presentation_models.dart'; 
import 'package:ingv_app/ui/shared/view_models/event_tooltip_helper.dart';

class TimelineCanvas extends StatefulWidget {
  final List<EventModel> events;
  final List<TimelineLaneData> lanes; 
  final EventModel? selectedEvent;
  final bool hasActiveFilters;
  final Duration Function() getTimeScale;
  final DateTime? filterStartDate;
  final DateTime? filterEndDate;
  final bool Function(String) isCategoryMinimized;
  final List<TimelineTaskData> Function(String) getTimelineTasksForCategory;
  final void Function(int, int) reorderCategories;
  final void Function(String) toggleCategoryMinimized;
  final void Function(EventModel) onEventTap;
  final DateTime clientBaselineStart;

  const TimelineCanvas({
    super.key,
    required this.events,
    required this.lanes,
    this.selectedEvent,
    this.hasActiveFilters = false,
    required this.getTimeScale,
    this.filterStartDate,
    this.filterEndDate,
    required this.isCategoryMinimized,
    required this.getTimelineTasksForCategory,
    required this.reorderCategories,
    required this.toggleCategoryMinimized,
    required this.onEventTap,
    required this.clientBaselineStart,
  });

  @override
  State<TimelineCanvas> createState() => _TimelineCanvasState();
}

class _TimelineCanvasState extends State<TimelineCanvas> {
  final GlobalKey _viewportKey = GlobalKey();
  double? _viewportHeight;
  bool _measureScheduled = false;

  @override
  void initState() {
    super.initState();
    _scheduleViewportMeasure();
  }

  @override
  void didUpdateWidget(covariant TimelineCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    _scheduleViewportMeasure();
  }

  void _scheduleViewportMeasure() {
    if (_measureScheduled) return;
    _measureScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measureScheduled = false;
      if (!mounted) return;

      final size = _viewportKey.currentContext?.size;
      final height = size?.height;
      if (height == null || !height.isFinite) return;

      if (_viewportHeight == null || (_viewportHeight! - height).abs() > 0.5) {
        setState(() {
          _viewportHeight = height;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.events.isEmpty || widget.lanes.isEmpty) {
      return Center(
        child: Text(
          widget.hasActiveFilters
              ? 'No events match the current filters'
              : 'No events yet. Use + to add the first event.',
          style: const TextStyle(fontSize: 16, color: Colors.black54),
        ),
      );
    }

    const double minimizedRowHeight = 35.0;
    const double minExpandedRowHeight = 40.0;
    const double baseAxisHeight = 27.0;
    const double totalCanvasWidth = 1200.0;
    const double leftHeaderWidth = 160.0;
    const double dividerHeight = 4.0;
    const double listVerticalPadding = 16.0;

    final DateTime rangeStart =
        widget.filterStartDate ?? widget.clientBaselineStart;
    final DateTime rangeEnd =
        widget.filterEndDate ?? rangeStart.add(widget.getTimeScale());

    final DateTime gridMin = rangeStart;
    final DateTime gridMax = rangeEnd;

    final Duration visibleSpan = rangeEnd.difference(rangeStart);
    final Duration edgePadding = visibleSpan * 0.25;
    final DateTime totalStart = rangeStart.subtract(edgePadding);
    final DateTime totalEnd = rangeEnd.add(edgePadding);

    final int totalLanes = widget.lanes.length;
    final int minimizedCount =
        widget.lanes.where((l) => widget.isCategoryMinimized(l.id)).length;
        final int expandedCount = totalLanes - minimizedCount;

        double expandedRowHeight = minExpandedRowHeight;
    final double? viewportHeight = _viewportHeight;
        if (expandedCount > 0 &&
        viewportHeight != null &&
        viewportHeight.isFinite) {
          final double availableForExpanded =
          viewportHeight -
              listVerticalPadding -
              baseAxisHeight -
              (minimizedCount * minimizedRowHeight) -
              (totalLanes * dividerHeight);
          final double computedHeight = availableForExpanded / expandedCount;
          if (computedHeight > minExpandedRowHeight) {
            expandedRowHeight = computedHeight;
          }
        }

    return SizedBox.expand(
      key: _viewportKey,
      child: ReorderableListView.builder(
          buildDefaultDragHandles: false,
        onReorder: (old, current) => widget.reorderCategories(old, current),
          padding: const EdgeInsets.symmetric(vertical: 8.0),
        itemCount: widget.lanes.length,
          itemBuilder: (context, index) {
          final lane = widget.lanes[index];
            final isFirstRow = index == 0;
          final isMinimized = widget.isCategoryMinimized(lane.id);

            final double definedRowHeight = isMinimized
                ? minimizedRowHeight
                : expandedRowHeight;

            final List<TimelineTaskData> genericTasks =
              widget.getTimelineTasksForCategory(lane.id);

            final packageRows = [
              LegacyGanttRow(id: lane.id, label: lane.label),
            ];

            final packageTasks = genericTasks.map((task) {
              final DateTime finalEnd;
              if (task.start == task.end) {
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

            int maxConcurrentCount = 0;
            bool showVerticalScrollIndicators = false;

            if (!isMinimized && genericTasks.isNotEmpty) {
              final List<MapEntry<DateTime, int>> timePoints = [];

              for (final task in genericTasks) {
                final end = task.end;
                if (task.start.isBefore(totalEnd) && end.isAfter(totalStart)) {
                  timePoints.add(MapEntry(task.start, 1));
                  timePoints.add(MapEntry(end, -1));
                }
              }

              timePoints.sort((a, b) {
                final compare = a.key.compareTo(b.key);
                if (compare != 0) return compare;
                return a.value.compareTo(b.value);
              });

              int concurrentCount = 0;
              for (final point in timePoints) {
                concurrentCount += point.value;
                if (concurrentCount > maxConcurrentCount) {
                  maxConcurrentCount = concurrentCount;
                }
              }

              if (maxConcurrentCount >= 5) {
                showVerticalScrollIndicators = true;
              }
            }

            final rowMaxStackDepth = <String, int>{
              lane.id: maxConcurrentCount > 0 ? maxConcurrentCount : 1,
            };

            final double fullWidgetHeight = definedRowHeight + baseAxisHeight;
            final double visibleViewportHeight = isFirstRow
                ? fullWidgetHeight
                : definedRowHeight;

            Widget chartSection = SizedBox(
              width: totalCanvasWidth,
              height: fullWidgetHeight,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: LegacyGanttChartWidget(
                      data: packageTasks,
                      visibleRows: packageRows,
                      rowMaxStackDepth: rowMaxStackDepth,
                      rowHeight: 50,
                      axisHeight: baseAxisHeight,
                      gridMin: gridMin.millisecondsSinceEpoch.toDouble(),
                      gridMax: gridMax.millisecondsSinceEpoch.toDouble(),
                      totalGridMin: totalStart.millisecondsSinceEpoch.toDouble(),
                      totalGridMax: totalEnd.millisecondsSinceEpoch.toDouble(),
                      taskBarBuilder: (task) {
                        if (isMinimized) return const SizedBox.shrink();
                        return _buildEventContainer(task.id);
                      },
                    ),
                  ),
                  if (showVerticalScrollIndicators)
                    Positioned(
                      bottom: 4,
                      left: (totalCanvasWidth / 2) - 12,
                      child: IgnorePointer(
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          child: const Icon(
                            Icons.keyboard_arrow_down,
                            color: Colors.blueAccent,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                ],
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
                  onPressed: () => widget.toggleCategoryMinimized(lane.id),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    leftHeader,
                    Expanded(
                      child: SizedBox(
                        width: totalCanvasWidth,
                        height: visibleViewportHeight,
                        child: chartSection,
                      ),
                    ),
                  ],
                ),
                Divider(
                  color: Colors.grey.shade300,
                  thickness: 1.0,
                  height: 4.0,
                ),
              ],
            );
          },
      ),
    );
  }

  Widget _buildEventContainer(String eventId) {
    final eventIndex =
        widget.events.indexWhere((e) => e.eventId.toString() == eventId);
    if (eventIndex == -1) {
      return const SizedBox.shrink();
    }

    final EventModel event = widget.events[eventIndex];

    final String startStringTime = event.startDt
        .toLocal()
        .toString()
        .split(' ')[1]
        .substring(0, 5);

    final String endStringTime = event.endDt != null
        ? event.endDt!.toLocal().toString().split(' ')[1].substring(0, 5)
        : '';

    final String duration = formatDuration(event.startDt, event.endDt);

    final String tooltipMessage =
        'Title: ${event.title}\n'
        'Start: ${formatDateTimeTooltip(event.startDt)}\n'
        'End: ${event.endDt != null ? formatDateTimeTooltip(event.endDt) : 'Ongoing'}\n'
        'Duration: $duration\n'
        '${formatLocation(event.lat, event.long)}';

    final categoryTasks =
        widget.getTimelineTasksForCategory(event.category.trim());
    final taskIndex = categoryTasks.indexWhere((t) => t.id == eventId);
    final Color itemColor =
        taskIndex == -1 ? Colors.grey : categoryTasks[taskIndex].color;

    final bool isSelected = widget.selectedEvent?.eventId == event.eventId;

    return Align(
      alignment: Alignment.centerLeft,
      child: GestureDetector(
        onTap: () => widget.onEventTap(event),
        child: Tooltip(
          message: tooltipMessage,
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
                          color: Colors.black26,
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                      border: isSelected
                          ? Border.all(color: Colors.white, width: 2)
                          : Border.all(color: Colors.white, width: 1),
                    ),
                    child: const Center(
                      child: Text(
                        '\u2026',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final double availWidth = constraints.maxWidth;
                    return Container(
                      alignment: Alignment.topLeft,
                      height: 45.0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6.0,
                        vertical: 4.0,
                      ),
                      decoration: BoxDecoration(
                        color: itemColor,
                        border: isSelected
                            ? Border.all(color: Colors.white, width: 2)
                            : null,
                      ),
                      child: _buildEventCardContent(
                        event,
                        duration,
                        startStringTime,
                        endStringTime,
                        availWidth,
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildEventCardContent(
    EventModel event,
    String duration,
    String startStringTime,
    String endStringTime,
    double availableWidth,
  ) {
    if (availableWidth < 28) {
      return const Center(
        child: Text(
          '...',
          style: TextStyle(color: Colors.white70, fontSize: 11),
        ),
      );
    }

    if (availableWidth < 60) {
      return Center(
        child: Text(
          duration,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      );
    }

    if (availableWidth < 120) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            event.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            duration,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            event.title,
            textAlign: TextAlign.left,
            maxLines: 1,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              flex: 2,
              child: Text(
                '$startStringTime - $endStringTime',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ),
            const SizedBox(width: 4),
            Flexible(
              flex: 1,
              child: Text(
                duration,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
