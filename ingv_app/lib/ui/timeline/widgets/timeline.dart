import 'package:flutter/material.dart';
import 'package:legacy_gantt_chart/legacy_gantt_chart.dart';
import 'package:ingv_app/data/models/event_model.dart';
import 'package:ingv_app/data/models/timeline_presentation_models.dart';
import 'package:ingv_app/ui/event_detail/view_models/event_detail_view_model.dart';
import 'package:ingv_app/ui/timeline/view_models/timeline_interface.dart';
import 'package:ingv_app/ui/event_detail/widgets/event_detail_panel.dart';
import 'add_event_dialog.dart';
import 'package:ingv_app/ui/shared/controllers/event_filter_controller.dart';
import 'package:ingv_app/ui/shared/widgets/event_filter_action_bar.dart';
import 'package:ingv_app/ui/shared/view_models/event_tooltip_helper.dart';

class TimelineScreen extends StatefulWidget {
  final ITimelineViewModel viewModel;
  final EventDetailViewModel detailViewModel;
  final bool showControlBar;
  final EventFilterController? sharedFilterController;
  final VoidCallback? onAddEvent;
  final ValueChanged<bool>?
  onPanelToggle; // for resizing hybrid view when event details panel opens/closes

  const TimelineScreen({
    super.key,
    required this.viewModel,
    required this.detailViewModel,
    this.showControlBar = true,
    this.sharedFilterController,
    this.onAddEvent,
    this.onPanelToggle,
  });

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

/// Visual zoom levels for the timeline grid.
enum TimelineZoomLevel {
  oneDay, // 1 day
  oneWeek, // 7 days
  oneMonth, // 30 days
  threeMonths, // 90 days
  fitAll, // auto-fit to all events
}

extension TimelineZoomLevelExtension on TimelineZoomLevel {
  String get label {
    switch (this) {
      case TimelineZoomLevel.oneDay:
        return '1 Day';
      case TimelineZoomLevel.oneWeek:
        return '1 Week';
      case TimelineZoomLevel.oneMonth:
        return '1 Month';
      case TimelineZoomLevel.threeMonths:
        return '3 Months';
      case TimelineZoomLevel.fitAll:
        return 'Fit All';
    }
  }

  int get days {
    switch (this) {
      case TimelineZoomLevel.oneDay:
        return 1;
      case TimelineZoomLevel.oneWeek:
        return 7;
      case TimelineZoomLevel.oneMonth:
        return 30;
      case TimelineZoomLevel.threeMonths:
        return 90;
      case TimelineZoomLevel.fitAll:
        return -1;
    }
  }
}

class _TimelineScreenState extends State<TimelineScreen> {
  EventModel? _selectedEvent;

  DateTime _clientBaselineStart = DateTime.now().subtract(
    const Duration(days: 1),
  );

  TimelineZoomLevel _zoomLevel = TimelineZoomLevel.oneDay;

  // Horizontal drag state for time panning
  double _dragDxTotal = 0;
  bool _isHorizontalPanning = false;

  EventFilterController? get _filterController => widget.sharedFilterController;

  @override
  void initState() {
    super.initState();
    _refreshInitialData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _refreshInitialData() async {
    try {
      await widget.viewModel.getColors();
      await widget.viewModel.fetchEvents();
      await widget.viewModel.getGroupsOfUser();
    } catch (e) {
      debugPrint('Timeline initialization error: $e');
      // Safe to fail silently — fetchEvents already sets errorMessage
    }
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
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
      widget.viewModel.setDateRangeFilter(picked.start, picked.end);
      _filterController?.setDateRange(picked.start, picked.end);
    }
  }

  Future<void> _showExportResult(
    Future<String?> Function() exportAction,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final exportPath = await exportAction();
    if (!mounted) {
      return;
    }

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          exportPath?.isNotEmpty == true
              ? 'Timeline export saved: $exportPath'
              : (widget.viewModel.exportErrorMessage ??
                    'Failed to export timeline events.'),
        ),
      ),
    );
  }

  Future<void> _exportDateRangePdf() async {
    final picked = await showDateRangePicker(
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
    if (picked == null) {
      return;
    }

    await _showExportResult(
      () => widget.viewModel.exportTimelineReportForDateRange(
        picked.start,
        picked.end,
      ),
    );
  }

  Future<void> _exportDateRangeZip() async {
    final picked = await showDateRangePicker(
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
    if (picked == null) {
      return;
    }

    await _showExportResult(
      () => widget.viewModel.exportTimelineAsZipForDateRange(
        picked.start,
        picked.end,
      ),
    );
  }

  void _syncFromSharedFilters() {
    final controller = _filterController;
    if (controller == null) {
      return;
    }

    if (widget.viewModel.selectedCategory != controller.selectedCategory) {
      widget.viewModel.setCategoryFilter(controller.selectedCategory);
    }
    if (widget.viewModel.searchQuery != controller.searchQuery) {
      widget.viewModel.setSearchQuery(controller.searchQuery);
    }
    if (widget.viewModel.filterStartDate != controller.startDate ||
        widget.viewModel.filterEndDate != controller.endDate) {
      widget.viewModel.setDateRangeFilter(
        controller.startDate,
        controller.endDate,
      );
    }
  }

  Future<void> _toggleEventDetails(EventModel event) async {
    if (_selectedEvent != null && _selectedEvent!.eventId == event.eventId) {
      setState(() => _selectedEvent = null);
      widget.detailViewModel.clearEventDetails();
      widget.onPanelToggle?.call(false);
      return;
    }

    setState(() => _selectedEvent = event);
    // callback for hybrid responsiveness
    widget.onPanelToggle?.call(true);
    await widget.detailViewModel.loadEventDetails(event);
  }

  void _navigateToPast() {
    final span = _zoomLevel.days;
    setState(() {
      _clientBaselineStart = _clientBaselineStart.subtract(
        Duration(days: span > 0 ? span : 7),
      );
      // If a hardcoded filter was explicitly active, clear it so navigation shifts the view instead
      if (widget.viewModel.filterStartDate != null) {
        widget.viewModel.setDateRangeFilter(null, null);
        _filterController?.clearDateRange();
      }
    });
  }

  void _navigateToFuture() {
    final span = _zoomLevel.days;
    setState(() {
      _clientBaselineStart = _clientBaselineStart.add(
        Duration(days: span > 0 ? span : 7),
      );
      // If a hardcoded filter was explicitly active, clear it so navigation shifts the view instead
      if (widget.viewModel.filterStartDate != null) {
        widget.viewModel.setDateRangeFilter(null, null);
        _filterController?.clearDateRange();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge(
        _filterController == null
            ? [widget.viewModel]
            : [widget.viewModel, _filterController!],
      ),
      builder: (context, _) {
        _syncFromSharedFilters();
        return Stack(
          children: [
            Column(
              children: [
                if (widget.showControlBar) _buildToolbar(context),
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onHorizontalDragStart: (_) {
                      _dragDxTotal = 0;
                      _isHorizontalPanning = false;
                    },
                    onHorizontalDragUpdate: (details) {
                      _dragDxTotal += details.delta.dx;

                      if (!_isHorizontalPanning && _dragDxTotal.abs() < 10) {
                        // Still accumulating — tiny movements don't trigger pan
                        return;
                      }
                      _isHorizontalPanning = true;

                      final span = _zoomLevel.days;
                      final days = span > 0 ? span : 7;
                      final deltaDays = -details.primaryDelta! / 300.0 * days;
                      final shift = Duration(
                        seconds: (days * 86400 * deltaDays).round(),
                      );
                      setState(() {
                        _clientBaselineStart = _clientBaselineStart.add(shift);
                        if (widget.viewModel.filterStartDate != null ||
                            widget.viewModel.filterEndDate != null) {
                          widget.viewModel.setDateRangeFilter(null, null);
                          _filterController?.clearDateRange();
                        }
                      });
                    },
                    onHorizontalDragEnd: (_) {
                      _isHorizontalPanning = false;
                    },
                    child: _buildTimelineCanvas(widget.viewModel.events),
                  ),
                ),
              ],
            ),
            if (_selectedEvent != null)
              EventDetailPanel(
                viewModel: widget.detailViewModel,
                groupOptions: widget.viewModel.userGroups,
                onEventUpdated: (updatedEvent) async {
                  setState(() {
                    _selectedEvent = updatedEvent;
                  });
                  await widget.viewModel.fetchEvents();
                },
                onDismiss: () {
                  setState(() => _selectedEvent = null);
                  widget.detailViewModel.clearEventDetails();
                  widget.onPanelToggle?.call(false);
                },
              ),
          ],
        );
      },
    );
  }

  Widget _buildZoomSelector() {
    return SizedBox(
      width: 130,
      child: DropdownButtonFormField<TimelineZoomLevel>(
        value: _zoomLevel,
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 4,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade400),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Theme.of(context).primaryColor),
          ),
        ),
        items: TimelineZoomLevel.values
            .map(
              (level) => DropdownMenuItem(
                value: level,
                child: Text(level.label, style: const TextStyle(fontSize: 13)),
              ),
            )
            .toList(),
        onChanged: (value) {
          if (value != null) {
            setState(() => _zoomLevel = value);
          }
        },
      ),
    );
  }

  Widget _buildToolbar(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.only(
          top: 12,
          bottom: 18,
          left: 16,
          right: 16,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1400),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                  tooltip: 'Go back ${_zoomLevel.label}',
                  onPressed:
                      widget.viewModel.filterStartDate != null ||
                          widget.viewModel.filterEndDate != null
                      ? null
                      : _navigateToPast,
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios, size: 20),
                  tooltip: 'Go forward ${_zoomLevel.label}',
                  onPressed:
                      widget.viewModel.filterStartDate != null ||
                          widget.viewModel.filterEndDate != null
                      ? null
                      : _navigateToFuture,
                ),
                const SizedBox(width: 8),
                // Zoom level selector
                _buildZoomSelector(),
                const SizedBox(width: 8),
                Expanded(
                  child: EventFilterActionBar(
                    categories: {
                      'All',
                      ...widget.viewModel.categories,
                    }.toList(),
                    selectedCategory: widget.viewModel.selectedCategory,
                    searchQuery: widget.viewModel.searchQuery,
                    startDate: widget.viewModel.filterStartDate,
                    endDate: widget.viewModel.filterEndDate,
                    showCategoryDropdown: true,
                    showDateFilter: true,
                    showSearch: true,
                    showExportPdf: true,
                    showExportZip: true,
                    showAddEvent: true,
                    isExporting: widget.viewModel.isExporting,
                    embeddedInPage: true,
                    onCategoryChanged: (newValue) {
                      widget.viewModel.setCategoryFilter(newValue);
                      _filterController?.setCategory(newValue);
                    },
                    onDateRangePicked: _pickDateRange,
                    onClearDateFilter: () {
                      widget.viewModel.setDateRangeFilter(null, null);
                      _filterController?.clearDateRange();
                    },
                    onSearchChanged: (query) {
                      widget.viewModel.setSearchQuery(query);
                      _filterController?.setSearchQuery(query);
                    },
                    onExportPdf: () => _showExportResult(
                      widget.viewModel.exportTimelineReport,
                    ),
                    onExportZip: () =>
                        _showExportResult(widget.viewModel.exportTimelineAsZip),
                    onExportDateRangePdf: _exportDateRangePdf,
                    onExportDateRangeZip: _exportDateRangeZip,
                    onAddEvent:
                        widget.onAddEvent ??
                        () => showAddEventDialog(
                          context,
                          widget.viewModel,
                          const [],
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineCanvas(List<EventModel> eventList) {
    final lanes = widget.viewModel.timelineLanes;

    if (eventList.isEmpty || lanes.isEmpty) {
      bool hasFilter =
          widget.viewModel.searchQuery.isNotEmpty ||
          widget.viewModel.selectedCategory != 'All' ||
          widget.viewModel.filterStartDate != null ||
          widget.viewModel.filterEndDate != null;

      return Center(
        child: Text(
          hasFilter
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

    final DateTime rangeStart;
    final DateTime rangeEnd;

    if (widget.viewModel.filterStartDate != null) {
      rangeStart = widget.viewModel.filterStartDate!;
      rangeEnd =
          widget.viewModel.filterEndDate ??
          widget.viewModel.filterStartDate!.add(const Duration(days: 7));
    } else if (widget.viewModel.filterEndDate != null) {
      rangeEnd = widget.viewModel.filterEndDate!;
      rangeStart = widget.viewModel.filterEndDate!.subtract(
        const Duration(days: 7),
      );
    } else {
      // No filter active — span all events so "All" timeline shows everything
      if (eventList.isEmpty) {
        rangeStart = _clientBaselineStart;
        rangeEnd = rangeStart.add(const Duration(days: 7));
      } else {
        // Compute min/max across ALL events (not just filtered subset)
        final minDt = eventList
            .map((e) => e.startDt)
            .reduce((a, b) => a.isBefore(b) ? a : b);
        final maxDt = eventList
            .map((e) => e.endDt ?? e.startDt)
            .reduce((a, b) => a.isAfter(b) ? a : b);
        rangeStart = minDt;
        rangeEnd = maxDt;
      }
    }

    // Compute gridMin/gridMax based on zoom level.
    final Duration rangeSpan = rangeEnd.difference(rangeStart);
    final DateTime gridMin;
    final DateTime gridMax;

    if (rangeSpan.inDays < 1) {
      // All events fit in one day — show a 7-day window centered on the first event
      gridMin = rangeStart.subtract(const Duration(days: 3));
      gridMax = rangeStart.add(const Duration(days: 4));
    } else if (_zoomLevel == TimelineZoomLevel.fitAll) {
      // Fit All: grid spans the full event range
      gridMin = rangeStart;
      gridMax = rangeEnd;
    } else {
      // Fixed zoom: center on the anchor (_clientBaselineStart) with selected span
      final int visibleDays = _zoomLevel.days;
      final halfSpan = Duration(days: visibleDays ~/ 2);
      gridMin = _clientBaselineStart.subtract(halfSpan);
      gridMax = _clientBaselineStart.add(
        Duration(days: visibleDays - halfSpan.inDays),
      );
    }

    // Total scrollable range = grid + buffer so events aren't clipped at edges
    final DateTime totalStart = gridMin.subtract(const Duration(days: 2));
    final DateTime totalEnd = gridMax.add(const Duration(days: 2));

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
            finalEnd = task.end!;
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

        // overlapping?
        bool showVerticalScrollIndicators = false;
        if (!isMinimized && genericTasks.length > 1) {
          for (int i = 0; i < genericTasks.length; i++) {
            final taskA = genericTasks[i];
            final endA = taskA.end;

            for (int j = i + 1; j < genericTasks.length; j++) {
              final taskB = genericTasks[j];
              final endB = taskB.end;

              if (endA == null || endB == null) continue;

              final bool overlapsInTime =
                  taskA.start.isBefore(endB) && taskB.start.isBefore(endA);

              if (overlapsInTime) {
                // Verify the collision happens
                if (taskA.start.isAfter(totalStart) &&
                    taskA.start.isBefore(totalEnd)) {
                  showVerticalScrollIndicators = true;
                  break;
                }
              }
            }
            if (showVerticalScrollIndicators) break;
          }
        }

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
                  rowHeight: definedRowHeight,
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

              // overlay arrow
              if (showVerticalScrollIndicators) ...[
                // Down Arrow
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
        '${event.title}\n'
        'Start: ${formatDateShort(event.startDt)} $startStringTime\n'
        'End: ${event.endDt != null ? '$endStringTime ${formatDateShort(event.endDt!)}' : 'Ongoing'}\n'
        'Duration: $duration\n'
        '${formatLocation(event.lat, event.long)}';

    final Color itemColor = widget.viewModel
        .getTimelineTasksForCategory(event.category.trim())
        .firstWhere((t) => t.id == eventId)
        .color;

    return Align(
      alignment: Alignment.centerLeft,
      child: GestureDetector(
        onTap: () => _toggleEventDetails(event),
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
                          color: Colors.black.withValues(alpha: 0.15),
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
              : ClipRRect(
                  child: Container(
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
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                event.title,
                                textAlign: TextAlign.left,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      '$startStringTime - $endStringTime $duration',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 9,
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
                ),
        ),
      ),
    );
  }
}
