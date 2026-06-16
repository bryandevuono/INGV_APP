import 'package:flutter/material.dart';
import 'package:ingv_app/data/repositories/attachment_repository_interface.dart';
import 'package:ingv_app/data/repositories/event_detail_repository.dart';
import 'package:ingv_app/data/repositories/event_repository.dart';
import 'package:ingv_app/data/services/file_operations_interface.dart';
import 'package:ingv_app/ui/event_detail/view_models/event_detail_view_model.dart';
import 'package:ingv_app/ui/groups/widgets/groups_screen.dart';
import 'package:ingv_app/ui/hybrid_view/widgets/hybrid_view.dart';
import 'package:ingv_app/ui/map/widgets/map.dart';
import 'package:ingv_app/ui/shared/controllers/event_filter_controller.dart';
import 'package:ingv_app/ui/shared/widgets/event_filter_action_bar.dart';
import 'package:ingv_app/ui/timeline/view_models/timeline_view_model.dart';
import 'package:ingv_app/ui/timeline/widgets/add_event_dialog.dart';
import 'package:ingv_app/ui/timeline/widgets/timeline.dart';

class TopNavigationBar extends StatefulWidget {
  final Widget mapScreen;
  final EventRepository eventRepository;
  final IEventDetailRepository detailRepository;
  final IAttachmentRepository attachmentRepository;
  final ILocalFileService localFileService;
  final IFileOpenService fileOpenService;

  const TopNavigationBar({
    super.key,
    required this.mapScreen,
    required this.eventRepository,
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

  @override
  void initState() {
    super.initState();
    _hybridFilterController = EventFilterController();
    _hybridTimelineViewModel = TimelineViewModel(widget.eventRepository);
    _hybridDetailViewModel = EventDetailViewModel(
      widget.detailRepository,
      widget.attachmentRepository,
      widget.localFileService,
      widget.fileOpenService,
      widget.eventRepository,
    );
  }

  @override
  void dispose() {
    _hybridFilterController.dispose();
    _hybridTimelineViewModel.dispose();
    _hybridDetailViewModel.dispose();
    super.dispose();
  }

  Future<void> _showHybridExportResult(
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
              ? 'Home export saved: $exportPath'
              : (_hybridTimelineViewModel.exportErrorMessage ??
                    'Failed to export home events.'),
        ),
      ),
    );
  }

  Future<void> _exportHybridDateRangePdf() async {
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
  }

  Future<void> _exportHybridDateRangeZip() async {
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
  }

  @override
  Widget build(BuildContext context) {
    final mapScreen = widget.mapScreen as MapScreen;

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Container(
            color: Colors.blue,
            child: const SafeArea(
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
          ),
        ),
        body: TabBarView(
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
                          constraints: const BoxConstraints(maxWidth: 1400),
                          child: ListenableBuilder(
                            listenable: Listenable.merge([
                              _hybridTimelineViewModel,
                              _hybridFilterController,
                            ]),
                            builder: (context, _) {
                              return EventFilterActionBar(
                                categories: {
                                  'All',
                                  ..._hybridTimelineViewModel.categories,
                                }.toList(),
                                selectedCategory:
                                    _hybridTimelineViewModel.selectedCategory,
                                searchQuery:
                                    _hybridTimelineViewModel.searchQuery,
                                startDate:
                                    _hybridTimelineViewModel.filterStartDate,
                                endDate: _hybridTimelineViewModel.filterEndDate,
                                showCategoryDropdown: true,
                                showDateFilter: true,
                                showSearch: true,
                                showExportPdf: true,
                                showExportZip: true,
                                showAddEvent: true,
                                isExporting:
                                    _hybridTimelineViewModel.isExporting,
                                embeddedInPage: true,
                                onCategoryChanged: (newValue) {
                                  _hybridTimelineViewModel.setCategoryFilter(
                                    newValue,
                                  );
                                  _hybridFilterController.setCategory(newValue);
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
                                    _hybridTimelineViewModel.setDateRangeFilter(
                                      picked.start,
                                      picked.end,
                                    );
                                    _hybridFilterController.setDateRange(
                                      picked.start,
                                      picked.end,
                                    );
                                  }
                                },
                                onClearDateFilter: () {
                                  _hybridTimelineViewModel.setDateRangeFilter(
                                    null,
                                    null,
                                  );
                                  _hybridFilterController.clearDateRange();
                                },
                                onSearchChanged: (query) {
                                  _hybridTimelineViewModel.setSearchQuery(
                                    query,
                                  );
                                  _hybridFilterController.setSearchQuery(query);
                                },
                                onExportPdf: () => _showHybridExportResult(
                                  _hybridTimelineViewModel.exportTimelineReport,
                                ),
                                onExportZip: () => _showHybridExportResult(
                                  _hybridTimelineViewModel.exportTimelineAsZip,
                                ),
                                onExportDateRangePdf: _exportHybridDateRangePdf,
                                onExportDateRangeZip: _exportHybridDateRangeZip,
                                onAddEvent: () => showAddEventDialog(
                                  context,
                                  _hybridTimelineViewModel,
                                  const [],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ResizableHybridView(
                      topWidget: MapScreen(
                        eventRepository: widget.eventRepository,
                        eventSearchRepository: mapScreen.eventSearchRepository,
                        mapService: mapScreen.mapService,
                        showControlBar: false,
                        sharedFilterController: _hybridFilterController,
                      ),
                      bottomWidget: TimelineScreen(
                        viewModel: _hybridTimelineViewModel,
                        detailViewModel: _hybridDetailViewModel,
                        showControlBar: false,
                        sharedFilterController: _hybridFilterController,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            TimelineScreen(
              viewModel: TimelineViewModel(widget.eventRepository),
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
          ],
        ),
      ),
    );
  }
}
