import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ingv_app/data/repositories/attachment_repository.dart';
import 'package:ingv_app/data/repositories/event_detail_repository.dart';
import 'package:ingv_app/data/repositories/event_repository.dart';
import 'package:ingv_app/data/services/file_operations_interface.dart';
import 'package:ingv_app/data/repositories/event_search_repository.dart';
import 'package:ingv_app/data/services/event_seed_service.dart';
import 'package:ingv_app/data/models/event_model.dart';
import 'package:ingv_app/ui/event_detail/view_models/event_detail_view_model.dart';
import 'package:ingv_app/ui/groups/widgets/groups_screen.dart';
import 'package:ingv_app/ui/hybrid_view/widgets/hybrid_view.dart';
import 'package:ingv_app/ui/map/widgets/map.dart';
import 'package:ingv_app/ui/shared/controllers/event_filter_controller.dart';
import 'package:ingv_app/ui/shared/widgets/event_filter_action_bar.dart';
import 'package:ingv_app/ui/timeline/view_models/timeline_view_model.dart';
import 'package:ingv_app/ui/timeline/widgets/add_event_dialog.dart';
import 'package:ingv_app/ui/timeline/widgets/timeline.dart';
import 'package:ingv_app/ui/hybrid_view/view_model/hybrid_view_model.dart';

class TopNavigationBar extends StatefulWidget {
  final Widget mapScreen;
  final EventRepository eventRepository;
  final IEventSearchRepository searchRepository;

  final IEventDetailRepository detailRepository;
  final AttachmentRepository attachmentRepository;
  final ILocalFileService localFileService;
  final IFileOpenService fileOpenService;

  const TopNavigationBar({
    super.key,
    required this.mapScreen,
    required this.eventRepository,
    required this.searchRepository,
    required this.detailRepository,
    required this.attachmentRepository,
    required this.localFileService,
    required this.fileOpenService,
  });

  @override
  State<TopNavigationBar> createState() => _TopNavigationBarState();
}

class _TopNavigationBarState extends State<TopNavigationBar> {
  late final EventFilterController _hybridFilterController;
  late final TimelineViewModel _hybridTimelineViewModel;
  late final EventDetailViewModel _hybridDetailViewModel;
  late final HybridViewModel _hybridViewModel;
  late final EventSeedService _seedService;
  final GlobalKey<MapScreenState> _hybridMapScreenKey =
      GlobalKey<MapScreenState>();

  bool _initFailed = false;
  String? _initErrorMessage;

  @override
  void initState() {
    super.initState();
    try {
      _hybridFilterController = EventFilterController();
      _hybridViewModel = HybridViewModel();
      _hybridTimelineViewModel = TimelineViewModel(
        widget.eventRepository,
        widget.searchRepository,
      );
      _seedService = EventSeedService();
      _hybridDetailViewModel = EventDetailViewModel(
        widget.detailRepository,
        widget.attachmentRepository,
        widget.localFileService,
        widget.fileOpenService,
        widget.eventRepository,
      );
    } catch (e) {
      debugPrint('Navigation bar initialization error: $e');
      _hybridFilterController = EventFilterController();
      _hybridViewModel = HybridViewModel();
      _hybridTimelineViewModel = TimelineViewModel(
        widget.eventRepository,
        widget.searchRepository,
      );
      _seedService = EventSeedService();
      _hybridDetailViewModel = EventDetailViewModel(
        widget.detailRepository,
        widget.attachmentRepository,
        widget.localFileService,
        widget.fileOpenService,
        widget.eventRepository,
      );
      setState(() {
        _initFailed = true;
        _initErrorMessage = e.toString();
      });
    }
  }

  @override
  void dispose() {
    _hybridFilterController.dispose();
    _hybridViewModel.dispose();
    _hybridTimelineViewModel.dispose();
    _hybridDetailViewModel.dispose();
    super.dispose();
  }

  Future<void> _showHybridExportResult(
    Future<String?> Function() exportAction,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final exportPath = await exportAction();
      if (!mounted) {
        return;
      }

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            exportPath?.isNotEmpty == true
                ? 'Home export saved: $exportPath'
                : (_hybridTimelineViewModel.exportErrorMessage ??
                      'Failed to export home events.'),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }

  Future<void> _exportHybridDateRangePdf() async {
    try {
      final picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2000),
        lastDate: DateTime(2101),
        initialDateRange:
            _hybridTimelineViewModel.filterStartDate != null &&
                _hybridTimelineViewModel.filterEndDate != null
            ? DateTimeRange(
                start: _hybridTimelineViewModel.filterStartDate!,
                end: _hybridTimelineViewModel.filterEndDate!,
              )
            : null,
      );
      if (picked == null) {
        return;
      }

      await _showHybridExportResult(
        () => _hybridTimelineViewModel.exportTimelineReportForDateRange(
          picked.start,
          picked.end,
        ),
      );
    } catch (e) {
      debugPrint('Hybrid date-range PDF export error: $e');
    }
  }

  Future<void> _exportHybridDateRangeZip() async {
    try {
      final picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2000),
        lastDate: DateTime(2101),
        initialDateRange:
            _hybridTimelineViewModel.filterStartDate != null &&
                _hybridTimelineViewModel.filterEndDate != null
            ? DateTimeRange(
                start: _hybridTimelineViewModel.filterStartDate!,
                end: _hybridTimelineViewModel.filterEndDate!,
              )
            : null,
      );
      if (picked == null) {
        return;
      }

      await _showHybridExportResult(
        () => _hybridTimelineViewModel.exportTimelineAsZipForDateRange(
          picked.start,
          picked.end,
        ),
      );
    } catch (e) {
      debugPrint('Hybrid date-range ZIP export error: $e');
    }
  }

  Future<void> _showHybridAddEventDialog() async {
    await showAddEventDialog(
      context,
      _hybridTimelineViewModel,
      _hybridTimelineViewModel.userGroups,
    );

    if (!mounted) return;
    await _hybridMapScreenKey.currentState?.reloadEvents();
  }

  /// Combines suggestions from the timeline view model and the map view
  /// model into a single deduplicated list (by eventId), capped at 5.
  List<EventModel> _mergedSuggestions(EventModel? Function()? unused) {
    final timelineSuggestions = _hybridTimelineViewModel.searchSuggestions;
    final mapViewModel = _hybridMapScreenKey.currentState?.getViewModel();
    final mapSuggestions =
        mapViewModel?.searchSuggestions ?? const <EventModel>[];

    final merged = <EventModel>[...timelineSuggestions];
    final seenIds = timelineSuggestions.map((e) => e.eventId).toSet();
    for (final event in mapSuggestions) {
      if (seenIds.add(event.eventId)) {
        merged.add(event);
      }
    }
    return merged.take(5).toList();
  }

  /// Selecting a suggestion should sync both panels: scroll the timeline to
  /// the event and pan the map to it, since both are visible together here.
  void _selectHybridSuggestion(EventModel event) {
    _hybridTimelineViewModel.selectSuggestion(event);
    final mapViewModel = _hybridMapScreenKey.currentState?.getViewModel();
    if (mapViewModel != null) {
      mapViewModel.selectSuggestion(event);
    }
  }

  /// Debug-only: seed demo events.
  Future<void> _seedDemoEvents() async {
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seed Demo Events'),
        content: const Text(
          'This will insert 100 demo events (IDs 900000-900099) '
          'and replace any existing demo events.\n\n'
          'User-created events will NOT be affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Seed'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final inserted = await _seedService.seedDemoEvents(
        replaceExistingSeedEvents: true,
      );
      if (!mounted) return;

      // Refresh the timeline view model to reflect new data
      _hybridTimelineViewModel.fetchEvents();

      messenger.showSnackBar(
        SnackBar(
          content: Text('$inserted demo events seeded successfully.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Failed to seed events: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mapScreen = widget.mapScreen as MapScreen;

    // Optional error banner at top when init threw
    Widget? topBanner;
    if (_initFailed) {
      topBanner = Container(
        width: double.infinity,
        color: Colors.orange.shade100,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Row(
          children: [
            const Icon(Icons.warning_amber, color: Colors.orange, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Some features may be limited: ${_initErrorMessage ?? 'initialization error'}',
                style: const TextStyle(fontSize: 13, color: Colors.black87),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: () => setState(() => _initFailed = false),
            ),
          ],
        ),
      );
    }

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Container(
            color: Colors.blue,
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TabBar(
                      indicatorColor: Colors.white,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white70,
                      tabs: [
                        Tab(text: 'Home'),
                        Tab(text: 'Timeline'),
                        Tab(text: 'Map'),
                        Tab(text: 'Groups'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        body: Column(
          children: [
            if (topBanner != null) topBanner,
            Expanded(
              child: TabBarView(
                children: [
                  ClipRect(
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 12, bottom: 18),
                            child: Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 1400,
                                ),
                                child: ListenableBuilder(
                                  listenable: Listenable.merge([
                                    _hybridTimelineViewModel,
                                    _hybridFilterController,
                                  ]),
                                  builder: (context, _) {
                                    final mapViewModel = _hybridMapScreenKey
                                        .currentState
                                        ?.getViewModel();

                                    return ListenableBuilder(
                                      listenable:
                                          mapViewModel ??
                                          _hybridTimelineViewModel,
                                      builder: (context, __) {
                                        return Row(
                                          children: [
                                            Expanded(
                                              child: EventFilterActionBar(
                                                timelineScaleDuration:
                                                    _hybridTimelineViewModel
                                                        .getTimeScale(),
                                                availableTimeScales: const [
                                                  Duration(days: 7),
                                                  Duration(days: 1),
                                                  Duration(hours: 12),
                                                  Duration(hours: 1),
                                                ],
                                                onTimeScaleChanged: (scale) {
                                                  _hybridTimelineViewModel
                                                      .setTimeScale(scale);
                                                  _hybridFilterController
                                                      .setTimeScale(scale);
                                                },
                                                categories: {
                                                  'All',
                                                  ..._hybridTimelineViewModel
                                                      .categories,
                                                }.toList(),
                                                selectedCategory:
                                                    _hybridTimelineViewModel
                                                        .selectedCategory,
                                                searchQuery:
                                                    _hybridTimelineViewModel
                                                        .searchQuery,
                                                startDate:
                                                    _hybridTimelineViewModel
                                                        .filterStartDate,
                                                endDate:
                                                    _hybridTimelineViewModel
                                                        .filterEndDate,
                                                showCategoryDropdown: true,
                                                showDateFilter: true,
                                                showSearch: true,
                                                showExportPdf: true,
                                                showExportZip: true,
                                                showAddEvent: true,
                                                isExporting:
                                                    _hybridTimelineViewModel
                                                        .isExporting,
                                                embeddedInPage: true,
                                                onCategoryChanged: (newValue) {
                                                  _hybridTimelineViewModel
                                                      .setCategoryFilter(
                                                        newValue,
                                                      );
                                                  _hybridFilterController
                                                      .setCategory(newValue);
                                                },
                                                onDateRangePicked: () async {
                                                  final picked = await showDateRangePicker(
                                                    context: context,
                                                    firstDate: DateTime(2000),
                                                    lastDate: DateTime(2101),
                                                    initialDateRange:
                                                        _hybridTimelineViewModel
                                                                    .filterStartDate !=
                                                                null &&
                                                            _hybridTimelineViewModel
                                                                    .filterEndDate !=
                                                                null
                                                        ? DateTimeRange(
                                                            start: _hybridTimelineViewModel
                                                                .filterStartDate!,
                                                            end: _hybridTimelineViewModel
                                                                .filterEndDate!,
                                                          )
                                                        : null,
                                                  );
                                                  if (picked != null) {
                                                    _hybridTimelineViewModel
                                                        .setDateRangeFilter(
                                                          picked.start,
                                                          picked.end,
                                                        );
                                                    _hybridFilterController
                                                        .setDateRange(
                                                          picked.start,
                                                          picked.end,
                                                        );
                                                  }
                                                },
                                                onClearDateFilter: () {
                                                  _hybridTimelineViewModel
                                                      .setDateRangeFilter(
                                                        null,
                                                        null,
                                                      );
                                                  _hybridFilterController
                                                      .clearDateRange();
                                                },
                                                onSearchChanged: (query) {
                                                  _hybridTimelineViewModel
                                                      .setSearchQuery(query);
                                                  _hybridFilterController
                                                      .setSearchQuery(query);
                                                },
                                                onExportPdf: () =>
                                                    _showHybridExportResult(
                                                      _hybridTimelineViewModel
                                                          .exportTimelineReport,
                                                    ),
                                                onExportZip: () =>
                                                    _showHybridExportResult(
                                                      _hybridTimelineViewModel
                                                          .exportTimelineAsZip,
                                                    ),
                                                onExportDateRangePdf:
                                                    _exportHybridDateRangePdf,
                                                onExportDateRangeZip:
                                                    _exportHybridDateRangeZip,
                                                onAddEvent: () {
                                                  _showHybridAddEventDialog();
                                                },
                                                searchSuggestions:
                                                    _mergedSuggestions(null),
                                                onSuggestionSelected:
                                                    _selectHybridSuggestion,
                                              ),
                                            ),
                                            // Debug-only seed button on toolbar
                                            if (kDebugMode)
                                              TextButton(
                                                onPressed: _seedDemoEvents,
                                                child: const Text(
                                                  'Seed 100 Events',
                                                ),
                                              ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: ResizableHybridView(
                            viewModel: _hybridViewModel,
                            detailViewModel: _hybridDetailViewModel,
                            groupOptionsBuilder: () =>
                                _hybridTimelineViewModel.userGroups,
                            onPanelToggle: (isPanelOpen) {
                              if (isPanelOpen) {
                                _hybridViewModel.updateRatio(0.45);
                              } else {
                                _hybridViewModel.updateRatio(0.50);
                              }
                            },
                            topWidget: MapScreen(
                              key: _hybridMapScreenKey,
                              eventRepository: widget.eventRepository,
                              eventSearchRepository:
                                  mapScreen.eventSearchRepository,
                              mapService: mapScreen.mapService,
                              showControlBar: false,
                              showLocalDetailPanel: false,
                              sharedFilterController: _hybridFilterController,
                              hybridViewModel: _hybridViewModel,
                              detailViewModel: _hybridDetailViewModel,
                              onPanelToggle: (isPanelOpen) {
                                if (isPanelOpen) {
                                  _hybridViewModel.updateRatio(0.45);
                                } else {
                                  _hybridViewModel.updateRatio(0.50);
                                }
                              },
                            ),
                            bottomWidget: TimelineScreen(
                              viewModel: _hybridTimelineViewModel,
                              detailViewModel: _hybridDetailViewModel,
                              showControlBar: false,
                              showLocalDetailPanel: false,
                              sharedFilterController: _hybridFilterController,
                              hybridViewModel: _hybridViewModel,
                              onPanelToggle: (isPanelOpen) {
                                if (isPanelOpen) {
                                  _hybridViewModel.updateRatio(0.45);
                                } else {
                                  _hybridViewModel.updateRatio(0.50);
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  TimelineScreen(
                    viewModel: TimelineViewModel(
                      widget.eventRepository,
                      widget.searchRepository,
                    ),
                    detailViewModel: EventDetailViewModel(
                      widget.detailRepository,
                      widget.attachmentRepository,
                      widget.localFileService,
                      widget.fileOpenService,
                      widget.eventRepository,
                    ),
                  ),
                  widget.mapScreen,
                  GroupsScreen(),
                ], // TabBarView.children
              ), // TabBarView(...)
            ), // Expanded(...)
          ], // Column.children
        ), // Column(...)
      ), // Scaffold(...)
    ); // DefaultTabController(...)
  }
}
