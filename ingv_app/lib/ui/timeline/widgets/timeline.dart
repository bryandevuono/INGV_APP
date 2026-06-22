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
import 'package:ingv_app/ui/hybrid_view/view_model/hybrid_view_model.dart';

class TimelineScreen extends StatefulWidget {
  final ITimelineViewModel viewModel;
  final EventDetailViewModel detailViewModel;
  final bool showControlBar;
  final bool showLocalDetailPanel;
  final EventFilterController? sharedFilterController;
  final VoidCallback? onAddEvent;
  final ValueChanged<bool>? onPanelToggle;
  final HybridViewModel? hybridViewModel;

  TimelineScreen({
    super.key,
    required this.viewModel,
    required this.detailViewModel,
    this.showControlBar = true,
    this.showLocalDetailPanel = true,
    this.sharedFilterController,
    this.onAddEvent,
    this.onPanelToggle,
    this.hybridViewModel,
  });

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  EventModel? _selectedEvent;

  DateTime _clientBaselineStart = DateTime.now().subtract(
    const Duration(days: 1),
  );

  double _dragDxTotal = 0;
  bool _isHorizontalPanning = false;
  bool _isDragging = false;
  double _scrollOffset = 0.0;
  static const List<(Duration, String, String)> _timeScaleOptions = [
    (Duration(days: 7), '1w', '1 week'),
    (Duration(days: 1), '1d', '1 day'),
    (Duration(hours: 12), '12h', '12 hours'),
    (Duration(hours: 1), '1h', '1 hour'),
  ];

  EventFilterController? get _filterController => widget.sharedFilterController;

  String get _currentScaleLabel {
    final match = _timeScaleOptions.firstWhere(
      (o) => o.$1 == widget.viewModel.getTimeScale(),
      orElse: () => _timeScaleOptions.first,
    );
    return match.$3;
  }

  @override
  void initState() {
    super.initState();
    widget.detailViewModel.addListener(_handleDetailViewModelChange);
    _refreshInitialData();
  }

  @override
  void dispose() {
    widget.detailViewModel.removeListener(_handleDetailViewModelChange);
    super.dispose();
  }

  void _handleDetailViewModelChange() {
    if (widget.detailViewModel.selectedEvent == null &&
        _selectedEvent != null) {
      setState(() {
        _selectedEvent = null;
      });

      widget.onPanelToggle?.call(false);

      widget.viewModel.fetchEvents();
    }
  }

  Future<void> _refreshInitialData() async {
    try {
      await widget.viewModel.getColors();
      await widget.viewModel.fetchEvents();
      await widget.viewModel.getGroupsOfUser();
    } catch (e) {
      debugPrint('Timeline initialization error: $e');
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

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
      if (widget.viewModel.getTimeScale() != controller.timeScale) {
        widget.viewModel.setTimeScale(controller.timeScale);
      }
    });
  }

  Future<void> _toggleEventDetails(EventModel event) async {
    if (widget.hybridViewModel != null) {
      if (widget.hybridViewModel!.selectedEvent?.eventId == event.eventId) {
        widget.hybridViewModel!.clearEvent();
        widget.onPanelToggle?.call(false);
        return;
      }
      await widget.detailViewModel.loadEventDetails(event);
      widget.hybridViewModel!.selectEvent(event, fromMap: false);
      widget.onPanelToggle?.call(true);
      return;
    }
    if (_selectedEvent != null && _selectedEvent!.eventId == event.eventId) {
      setState(() => _selectedEvent = null);
      widget.detailViewModel.clearEventDetails();
      widget.onPanelToggle?.call(false);
      return;
    }

    setState(() => _selectedEvent = event);
    widget.onPanelToggle?.call(true);
    await widget.detailViewModel.loadEventDetails(event);
  }

  void _navigateToPast() {
    setState(() {
      _clientBaselineStart = _clientBaselineStart.subtract(
        widget.viewModel.getTimeScale(),
      );
      // clear the filter so navigation shifts the view instead
      if (widget.viewModel.filterStartDate != null) {
        widget.viewModel.setDateRangeFilter(null, null);
        _filterController?.clearDateRange();
      }
    });
  }

  void _navigateToFuture() {
    setState(() {
      _clientBaselineStart = _clientBaselineStart.add(
        widget.viewModel.getTimeScale(),
      );
      // clear the filter so navigation shifts the view instead
      if (widget.viewModel.filterStartDate != null) {
        widget.viewModel.setDateRangeFilter(null, null);
        _filterController?.clearDateRange();
      }
    });
  }

  void _setTimeScale(Duration scale) {
    if (scale == widget.viewModel.getTimeScale()) return;
    setState(() {
      if (widget.viewModel.filterStartDate != null) {
        _clientBaselineStart = widget.viewModel.filterStartDate!;
        widget.viewModel.setDateRangeFilter(null, null);
        _filterController?.clearDateRange();
      }
      widget.viewModel.setTimeScale(scale);
      _filterController?.setTimeScale(scale);
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
                if (widget.viewModel.events.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 168.0),
                    child: _buildTimelineScrollBar(),
                  ),
                Expanded(
                  child: MouseRegion(
                    cursor: _isDragging
                        ? SystemMouseCursors.grabbing
                        : SystemMouseCursors.grab,
                    child: Stack(
                      children: [
                        GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onHorizontalDragStart: (_) {
                            _dragDxTotal = 0;
                            _isHorizontalPanning = false;
                            setState(() {
                              _isDragging = true;
                            });
                          },
                          onHorizontalDragUpdate: (details) {
                            // Track scrubber visual position
                            _dragDxTotal += details.delta.dx;
                            setState(() {
                              _scrollOffset += details.delta.dx;
                            });

                            if (!_isHorizontalPanning &&
                                _dragDxTotal.abs() < 10) {
                              return;
                            }
                            _isHorizontalPanning = true;

                            final double scaleMs = widget.viewModel
                                .getTimeScale()
                                .inMilliseconds
                                .toDouble();
                            final double deltaMs =
                                -details.primaryDelta! / 300.0 * scaleMs;
                            final shift = Duration(
                              milliseconds: deltaMs.round(),
                            );
                            setState(() {
                              _clientBaselineStart = _clientBaselineStart.add(
                                shift,
                              );
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
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Pin the detail panel to the bottom of the stack
            if (_selectedEvent != null)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: EventDetailPanel(
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
              ),
          ],
        );
      },
    );
  }

  Widget _buildToolbar(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Check if we are on a mobile-sized screen
            final isMobile = constraints.maxWidth < 600;

            final navigationWidgets = [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                tooltip: 'Go back $_currentScaleLabel',
                onPressed: _navigateToPast,
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios, size: 20),
                tooltip: 'Go forward $_currentScaleLabel',
                onPressed: _navigateToFuture,
              ),
              const SizedBox(width: 12),
              _buildTimeScaleSelector(),
            ];

            final actionFilterBar = EventFilterActionBar(
              categories: {'All', ...widget.viewModel.categories}.toList(),
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
              searchSuggestions: widget.viewModel.searchSuggestions,
              onSuggestionSelected: (event) {
                widget.viewModel.selectSuggestion(event);
              },
              onExportPdf: () =>
                  _showExportResult(widget.viewModel.exportTimelineReport),
              onExportZip: () =>
                  _showExportResult(widget.viewModel.exportTimelineAsZip),
              onExportDateRangePdf: _exportDateRangePdf,
              onExportDateRangeZip: _exportDateRangeZip,
              onAddEvent:
                  widget.onAddEvent ??
                  () => showAddEventDialog(context, widget.viewModel, const []),
            );

            if (isMobile) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: navigationWidgets,
                  ),
                  const SizedBox(height: 12), // Spacer between rows
                  actionFilterBar,
                ],
              );
            }

            return Row(
              children: [
                ...navigationWidgets,
                const SizedBox(width: 12),
                Expanded(child: actionFilterBar),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTimeScaleSelector() {
    return ToggleButtons(
      isSelected: _timeScaleOptions
          .map((o) => o.$1 == widget.viewModel.getTimeScale())
          .toList(),
      borderRadius: BorderRadius.circular(6),
      constraints: const BoxConstraints(minWidth: 42, minHeight: 32),
      onPressed: (index) => _setTimeScale(_timeScaleOptions[index].$1),
      children: _timeScaleOptions
          .map(
            (o) => Tooltip(
              message: o.$3,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(o.$2, style: const TextStyle(fontSize: 12)),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildTimelineScrollBar() {
    return Tooltip(
      message: 'Drag to move timeline',
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragStart: (_) {
          setState(() => _isDragging = true);
        },
        onHorizontalDragUpdate: (details) {
          setState(() {
            _scrollOffset += details.delta.dx;
          });

          final double scaleMs = widget.viewModel
              .getTimeScale()
              .inMilliseconds
              .toDouble();
          final double deltaMs = -details.primaryDelta! / 300.0 * scaleMs;
          final shift = Duration(milliseconds: deltaMs.round());
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
          setState(() => _isDragging = false);
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            final availableWidth = constraints.maxWidth;
            final thumbWidth = 100.0;
            final maxOffset = availableWidth - thumbWidth;
            final thumbOffset = _scrollOffset.clamp(
              -maxOffset * 0.3,
              maxOffset * 0.3,
            );

            return Stack(
              alignment: Alignment.center,
              children: [
                // Track
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                // Draggable thumb
                Positioned(
                  left: (availableWidth / 2) - (thumbWidth / 2) + thumbOffset,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    width: thumbWidth,
                    height: 22,
                    decoration: BoxDecoration(
                      color: _isDragging
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.drag_handle_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
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

    const double minimizedRowHeight = 35.0;
    const double minExpandedRowHeight = 40.0;
    const double baseAxisHeight = 27.0;
    const double totalCanvasWidth = 1200.0;
    const double leftHeaderWidth = 160.0;
    const double dividerHeight = 4.0;
    const double listVerticalPadding = 16.0; // 8 top + 8 bottom

    final DateTime rangeStart =
        widget.viewModel.filterStartDate ?? _clientBaselineStart;
    final DateTime rangeEnd =
        widget.viewModel.filterEndDate ??
        rangeStart.add(widget.viewModel.getTimeScale());

    final DateTime gridMin = rangeStart;
    final DateTime gridMax = rangeEnd;

    final Duration visibleSpan = rangeEnd.difference(rangeStart);
    final Duration edgePadding = visibleSpan * 0.25;
    final DateTime totalStart = rangeStart.subtract(edgePadding);
    final DateTime totalEnd = rangeEnd.add(edgePadding);

    return LayoutBuilder(
      builder: (context, constraints) {
        final int totalLanes = lanes.length;
        final int minimizedCount = lanes
            .where((l) => widget.viewModel.isCategoryMinimized(l.id))
            .length;
        final int expandedCount = totalLanes - minimizedCount;

        double expandedRowHeight = minExpandedRowHeight;
        if (expandedCount > 0 && constraints.hasBoundedHeight) {
          final double availableForExpanded =
              constraints.maxHeight -
              listVerticalPadding -
              baseAxisHeight -
              (minimizedCount * minimizedRowHeight) -
              (totalLanes * dividerHeight);
          final double computedHeight = availableForExpanded / expandedCount;
          if (computedHeight > minExpandedRowHeight) {
            expandedRowHeight = computedHeight;
          }
        }

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

            final packageRows = [
              LegacyGanttRow(id: lane.id, label: lane.label),
            ];

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

            int maxConcurrentCount = 0;
            bool showVerticalScrollIndicators = false;

            if (!isMinimized && genericTasks.isNotEmpty) {
              final List<MapEntry<DateTime, int>> timePoints = [];

              for (final task in genericTasks) {
                final end =
                    task.end ?? task.start.add(const Duration(hours: 1));

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
                      totalGridMin: totalStart.millisecondsSinceEpoch
                          .toDouble(),
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
                Divider(
                  color: Colors.grey.shade300,
                  thickness: 1.0,
                  height: 4.0,
                ),
              ],
            );
          },
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
        'Title: ${event.title}\n'
        'Start: ${formatDateTimeTooltip(event.startDt)}\n'
        'End: ${event.endDt != null ? formatDateTimeTooltip(event.endDt) : 'Ongoing'}\n'
        'Duration: $duration\n'
        '${formatLocation(event.lat, event.long)}';

    final Color itemColor = widget.viewModel
        .getTimelineTasksForCategory(event.category.trim())
        .firstWhere((t) => t.id == eventId)
        .color;

    final bool isSelected = _selectedEvent?.eventId == event.eventId;

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
    double availWidth,
  ) {
    if (availWidth < 28) {
      // Very small: show ellipsis
      return const Center(
        child: Text(
          '...',
          style: TextStyle(color: Colors.white70, fontSize: 11),
        ),
      );
    }

    if (availWidth < 60) {
      // Small: show duration only
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

    if (availWidth < 120) {
      // Medium: short title + duration
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

    // Large: full title + time range + duration
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
