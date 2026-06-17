import 'package:flutter/material.dart';
import 'package:ingv_app/data/models/event_model.dart';
import 'package:ingv_app/data/repositories/event_repository.dart';
import 'package:ingv_app/data/repositories/event_search_repository.dart';
import 'package:ingv_app/data/repositories/attachment_repository.dart';
import 'package:ingv_app/data/repositories/event_detail_repository.dart';
import 'package:ingv_app/data/services/event_detail_service.dart';
import 'package:ingv_app/data/services/export_service.dart';
import 'package:ingv_app/data/services/file_operations_service.dart';
import 'package:ingv_app/ui/event_detail/view_models/event_detail_view_model.dart';
import 'package:ingv_app/ui/event_detail/widgets/event_detail_panel.dart';
import 'package:ingv_app/ui/map/view_models/map_view_model.dart';
import 'package:ingv_app/ui/shared/controllers/event_filter_controller.dart';
import 'package:ingv_app/ui/shared/widgets/event_filter_action_bar.dart';
import 'package:ingv_app/ui/map/ui_services/map_service_interface.dart';

class MapScreen extends StatefulWidget {
  final IEventRepository eventRepository;
  final IEventSearchRepository eventSearchRepository;
  final IMapService mapService;
  final bool showControlBar;
  final EventFilterController? sharedFilterController;
  final VoidCallback? onAddEvent;
  final ValueChanged<bool>? onPanelToggle; 

  IEventSearchRepository get exposedEventSearchRepository =>
      eventSearchRepository;
  IMapService get exposedMapService => mapService;

  const MapScreen({
    super.key,
    required this.eventRepository,
    required this.eventSearchRepository,
    required this.mapService,
    this.showControlBar = true,
    this.sharedFilterController,
    this.onAddEvent,
    this.onPanelToggle,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late final MapScreenViewModel _viewModel;
  late final EventDetailViewModel _detailViewModel;
  EventModel? _selectedEvent;
  EventFilterController? get _filterController => widget.sharedFilterController;

  @override
  void initState() {
    super.initState();

    final detailRepository = EventDetailRepository(EventDetailService());
    final attachmentRepository = LocalAttachmentRepository();
    final localFileService = LocalFileService();

    final pdfExportService = PdfExportService(
      detailRepository,
      attachmentRepository,
      localFileService,
    );

    final zipExportService = ZipExportService(
      pdfExportService: pdfExportService,
      detailRepository: detailRepository,
      attachmentRepository: attachmentRepository,
      localFileService: localFileService,
    );

    _viewModel = MapScreenViewModel(
      widget.eventRepository,
      widget.eventSearchRepository,
      detailRepository,
      attachmentRepository,
      localFileService,
      FileOpenService(),
      pdfExportService,
      zipExportService,
    );

    _detailViewModel = EventDetailViewModel(
      detailRepository,
      attachmentRepository,
      localFileService,
      FileOpenService(),
      widget.eventRepository,
      null,
      pdfExportService,
      zipExportService,
    );

    _loadEvents();
  }

  Future<void> _loadEvents() async {
    await _viewModel.getColors();
    await _viewModel.fetchEvents();
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      initialDateRange:
          _viewModel.filterStartDate != null && _viewModel.filterEndDate != null
          ? DateTimeRange(
              start: _viewModel.filterStartDate!,
              end: _viewModel.filterEndDate!,
            )
          : null,
    );
    if (picked != null) {
      _viewModel.setDateRangeFilter(picked.start, picked.end);
      _filterController?.setDateRange(picked.start, picked.end);
    }
  }

  Future<void> _exportVisibleEvents({required bool zip}) async {
    final exportPath = zip
        ? await _viewModel.exportVisibleEventsZip()
        : await _viewModel.exportVisibleEventsPdf();

    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          exportPath?.isNotEmpty == true
              ? 'Map export saved: $exportPath'
              : (_viewModel.exportErrorMessage ??
                    'Failed to export map events.'),
        ),
      ),
    );
  }

  void _syncFromSharedFilters() {
    final controller = _filterController;
    if (controller == null) return;

    if (_viewModel.selectedCategory != controller.selectedCategory) {
      _viewModel.setCategoryFilter(controller.selectedCategory);
    }
    if (_viewModel.searchQuery != controller.searchQuery) {
      _viewModel.setSearchQuery(controller.searchQuery);
    }
    if (_viewModel.filterStartDate != controller.startDate ||
        _viewModel.filterEndDate != controller.endDate) {
      _viewModel.setDateRangeFilter(controller.startDate, controller.endDate);
    }
  }

  Future<void> _toggleEventDetails(EventModel event) async {
    if (_selectedEvent != null && _selectedEvent!.eventId == event.eventId) {
      setState(() {
        _selectedEvent = null;
      });
      _detailViewModel.clearEventDetails();
      widget.onPanelToggle?.call(false); // Panel closed expand timeline
      return;
    }

    setState(() {
      _selectedEvent = event;
    });
    widget.onPanelToggle?.call(true); // Panel opened shrink timeline
    await _detailViewModel.loadEventDetails(event);
  }

  List<AppMarker> _convertEventsToMarkers(List<EventModel> events) {
    return [
      for (var event in events)
        AppMarker(
          latitude: event.lat,
          longitude: event.long,
          author: 'Author ${event.author}',
          category: event.category,
          title: event.title,
          startDateTime: event.startDt,
          endDateTime: event.endDt,
          progress: _viewModel.calculateMarkerDuration(
            event.startDt,
            event.endDt,
          ),
          onTap: () => _toggleEventDetails(event),
          categoryColor: _viewModel.getCategoryColor(event.category),
          fillColor: _viewModel.getCategoryColor(event.category),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge(
        _filterController == null
            ? [_viewModel]
            : [_viewModel, _filterController!],
      ),
      builder: (context, _) {
        _syncFromSharedFilters();

        // Determine if the panel should be visible
        final isPanelOpen = _selectedEvent != null;

        return Stack(
          children: [
            // 1. Your Main Map & Controls Column
            Column(
              children: [
                if (widget.showControlBar)
                  SizedBox(
                    width: double.infinity,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12, bottom: 18),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1400),
                          child: EventFilterActionBar(
                            categories: _viewModel.categories.isNotEmpty
                                ? _viewModel.categories
                                : const ['All'],
                            selectedCategory: _viewModel.selectedCategory,
                            searchQuery: _viewModel.searchQuery,
                            startDate: _viewModel.filterStartDate,
                            endDate: _viewModel.filterEndDate,
                            showCategoryDropdown: true,
                            showDateFilter: true,
                            showSearch: true,
                            showExportPdf: true,
                            showExportZip: true,
                            showAddEvent: widget.onAddEvent != null,
                            embeddedInPage: true,
                            onCategoryChanged: (newValue) {
                              _viewModel.setCategoryFilter(newValue);
                              _filterController?.setCategory(newValue);
                            },
                            onDateRangePicked: _pickDateRange,
                            onClearDateFilter: () {
                              _viewModel.setDateRangeFilter(null, null);
                              _filterController?.clearDateRange();
                            },
                            onSearchChanged: (query) {
                              _viewModel.setSearchQuery(query);
                              _filterController?.setSearchQuery(query);
                            },
                            onExportPdf: () => _exportVisibleEvents(zip: false),
                            onExportZip: () => _exportVisibleEvents(zip: true),
                            onAddEvent: widget.onAddEvent,
                          ),
                        ),
                      ),
                    ),
                  ),
                Expanded(
                  child: widget.mapService.buildMap(
                    initialLat: 41.9028,
                    initialLng: 12.4963,
                    initialZoom: 6,
                    markers: _convertEventsToMarkers(_viewModel.events),
                    mapViewModel: _viewModel,
                  ),
                ),
              ],
            ),

            // 2. Animated Slide-Up Detail Panel
            AnimatedSlide(
              // Offset(0, 0) means normal position, Offset(0, 1) slides it 100% downward off-screen
              offset: isPanelOpen ? Offset.zero : const Offset(0, 1),
              duration: const Duration(milliseconds: 350),
              curve: Curves.fastOutSlowIn, // Smooth, modern easing curve
              child: Align(
                alignment: Alignment.bottomCenter,
                child: isPanelOpen
                    ? EventDetailPanel(
                        viewModel: _detailViewModel,
                        onEventUpdated: (updatedEvent) async {
                          setState(() {
                            _selectedEvent = updatedEvent;
                          });
                          await _loadEvents();
                        },
                        onDismiss: () {
                          setState(() {
                            _selectedEvent = null;
                          });
                          _detailViewModel.clearEventDetails();
                          widget.onPanelToggle?.call(
                            false,
                          ); // Panel closed expand timeline again
                        },
                      )
                    : const SizedBox.shrink(), // Keeps an empty placeholder when hidden
              ),
            ),
          ],
        );
      },
    );
  }
}
