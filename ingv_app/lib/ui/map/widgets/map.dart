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
import 'package:ingv_app/ui/search.dart';

import 'package:ingv_app/ui/map/ui_services/map_service_interface.dart'; 

class MapScreen extends StatefulWidget {
  final IEventRepository eventRepository;
  final IEventSearchRepository eventSearchRepository;
  final IMapService mapService; 

  const MapScreen({
    super.key,
    required this.eventRepository,
    required this.eventSearchRepository,
    required this.mapService,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late final MapScreenViewModel _viewModel;
  late final EventDetailViewModel _detailViewModel;
  EventModel? _selectedEvent;

  @override
  void initState() {
    super.initState();
    _viewModel = MapScreenViewModel(
      widget.eventRepository,
      widget.eventSearchRepository,
    );

    // Keeping your original initialization chain exactly as it was:
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
    await _viewModel.fetchEvents();
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

  // Maps EventModel to the generic AppMarker structure configuration
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
          progress: 0.5,
          onTap: () => _toggleEventDetails(event),
        ),
    ];
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
                  child: Wrap(
                    spacing: 12.0,
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
                          final DateTimeRange? picked = await showDateRangePicker(
                            context: context,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2101),
                            initialDateRange: _viewModel.filterStartDate != null &&
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
                      Search(viewModel: _viewModel),
                    ],
                  ),
                ),
                Expanded(
                  child: widget.mapService.buildMap(
                    initialLat: 41.9028,
                    initialLng: 12.4963,
                    initialZoom: 6,
                    markers: _convertEventsToMarkers(_viewModel.events),
                  ),
                ),
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