import 'package:flutter/material.dart';
import 'package:ingv_app/data/models/event_model.dart';
import 'package:ingv_app/ui/event_detail/view_models/event_detail_view_model.dart';
import 'package:ingv_app/ui/timeline/view_models/timeline_interface.dart';
import 'package:ingv_app/ui/event_detail/widgets/event_detail_panel.dart';
import 'package:ingv_app/ui/shared/controllers/event_filter_controller.dart';
import 'package:ingv_app/ui/hybrid_view/view_model/hybrid_view_model.dart';
import 'package:ingv_app/ui/timeline/widgets/timeline_toolbar.dart';
import 'package:ingv_app/ui/timeline/widgets/timeline_scrollbar.dart';
import 'package:ingv_app/ui/timeline/widgets/timeline_canvas.dart';
import 'add_event_dialog.dart';

class TimelineScreen extends StatefulWidget {
  final ITimelineViewModel viewModel;
  final EventDetailViewModel detailViewModel;
  final bool showControlBar;
  final bool showLocalDetailPanel;
  final EventFilterController? sharedFilterController;
  final VoidCallback? onAddEvent;
  final ValueChanged<bool>? onPanelToggle;
  final HybridViewModel? hybridViewModel;

  const TimelineScreen({
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
    if (!mounted) return;
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
    if (picked == null) return;
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
    if (picked == null) return;
    await _showExportResult(
      () => widget.viewModel.exportTimelineAsZipForDateRange(
        picked.start,
        picked.end,
      ),
    );
  }

  Future<void> _exportDateRangeJson() async {
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
    if (picked == null) return;
    await _showExportResult(
      () => widget.viewModel.exportTimelineAsJsonForDateRange(
        picked.start,
        picked.end,
      ),
    );
  }

  Future<void> _exportDateRangeCsv() async {
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
    if (picked == null) return;
    await _showExportResult(
      () => widget.viewModel.exportTimelineAsCsvForDateRange(
        picked.start,
        picked.end,
      ),
    );
  }

  void _navigateToPast() {
    setState(() {
      _clientBaselineStart = _clientBaselineStart.subtract(
        widget.viewModel.getTimeScale(),
      );
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

  void _syncFromSharedFilters() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final controller = _filterController;
      if (controller == null) return;

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

  void _onHorizontalDragStart(DragStartDetails details) {
    _dragDxTotal = 0;
    _isHorizontalPanning = false;
    setState(() => _isDragging = true);
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    _dragDxTotal += details.delta.dx;
    setState(() {
      _scrollOffset += details.delta.dx;
    });

    if (!_isHorizontalPanning && _dragDxTotal.abs() < 10) return;
    _isHorizontalPanning = true;

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
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    _isHorizontalPanning = false;
    setState(() => _isDragging = false);
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
                if (widget.showControlBar)
                  TimelineToolbar(
                    viewModel: widget.viewModel,
                    filterController: _filterController,
                    onAddEvent:
                        widget.onAddEvent ??
                        () => showAddEventDialog(
                          context,
                          widget.viewModel,
                          widget.viewModel.userGroups,
                        ),
                    onNavigatePast: _navigateToPast,
                    onNavigateFuture: _navigateToFuture,
                    currentScale: widget.viewModel.getTimeScale(),
                    scaleOptions: _timeScaleOptions,
                    onScaleChanged: _setTimeScale,
                    onPickDateRange: _pickDateRange,
                    onClearDateFilter: () {
                      widget.viewModel.setDateRangeFilter(null, null);
                      _filterController?.clearDateRange();
                    },
                    onExportPdf: () => _showExportResult(
                      widget.viewModel.exportTimelineReport,
                    ),
                    onExportZip: () =>
                        _showExportResult(widget.viewModel.exportTimelineAsZip),
                    onExportJson: () => _showExportResult(
                      widget.viewModel.exportTimelineAsJson,
                    ),
                    onExportCsv: () =>
                        _showExportResult(widget.viewModel.exportTimelineAsCsv),
                    onExportDateRangePdf: _exportDateRangePdf,
                    onExportDateRangeZip: _exportDateRangeZip,
                    onExportDateRangeJson: _exportDateRangeJson,
                    onExportDateRangeCsv: _exportDateRangeCsv,
                  ),
                if (widget.viewModel.events.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 168.0),
                    child: TimelineScrollbar(
                      scrollOffset: _scrollOffset,
                      isDragging: _isDragging,
                      onDragStart: _onHorizontalDragStart,
                      onDragUpdate: _onHorizontalDragUpdate,
                      onDragEnd: _onHorizontalDragEnd,
                    ),
                  ),
                Expanded(
                  child: MouseRegion(
                    cursor: _isDragging
                        ? SystemMouseCursors.grabbing
                        : SystemMouseCursors.grab,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onHorizontalDragStart: _onHorizontalDragStart,
                      onHorizontalDragUpdate: _onHorizontalDragUpdate,
                      onHorizontalDragEnd: _onHorizontalDragEnd,
                      child: TimelineCanvas(
                        events: widget.viewModel.events,
                        lanes: widget.viewModel.timelineLanes,
                        selectedEvent: _selectedEvent,
                        getTimeScale: widget.viewModel.getTimeScale,
                        filterStartDate: widget.viewModel.filterStartDate,
                        filterEndDate: widget.viewModel.filterEndDate,
                        isCategoryMinimized:
                            widget.viewModel.isCategoryMinimized,
                        getTimelineTasksForCategory:
                            widget.viewModel.getTimelineTasksForCategory,
                        reorderCategories: widget.viewModel.reorderCategories,
                        toggleCategoryMinimized:
                            widget.viewModel.toggleCategoryMinimized,
                        onEventTap: _toggleEventDetails,
                        clientBaselineStart: _clientBaselineStart,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (_selectedEvent != null)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: EventDetailPanel(
                  viewModel: widget.detailViewModel,
                  groupOptions: widget.viewModel.userGroups,
                  onEventUpdated: (updatedEvent) async {
                    setState(() => _selectedEvent = updatedEvent);
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
}
