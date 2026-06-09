import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong2;
import 'package:ingv_app/data/models/event_model.dart';
import 'package:ingv_app/data/repositories/attachment_repository.dart';
import 'package:ingv_app/data/repositories/event_detail_repository.dart';
import 'package:ingv_app/ui/map/view_models/map_view_model.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:ingv_app/data/services/event_detail_service.dart';
import 'package:ingv_app/data/services/file_operations_service.dart';
import 'package:ingv_app/ui/map/widgets/map_marker.dart';
import 'package:ingv_app/data/repositories/event_repository.dart';
import 'package:ingv_app/data/repositories/event_search_repository.dart';
import 'package:ingv_app/ui/event_detail/view_models/event_detail_view_model.dart';
import 'package:ingv_app/ui/event_detail/widgets/event_detail_panel.dart';
import 'package:ingv_app/ui/map/widgets/map_interface.dart';
import 'package:ingv_app/ui/search.dart';

class MapScreen extends StatefulWidget {
  final IEventRepository eventRepository;
  final IEventSearchRepository eventSearchRepository;

  const MapScreen({
    super.key,
    required this.eventRepository,
    required this.eventSearchRepository,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> implements IMap {
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
    _detailViewModel = EventDetailViewModel(
      EventDetailRepository(EventDetailService()),
      LocalAttachmentRepository(),
      LocalFileService(),
      FileOpenService(),
      widget.eventRepository,
    );
    _loadEvents();
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
  List<MapMarker> generateMarkers(List<EventModel> events) {
    return [
      for (var event in events)
        MapMarker(
          point: latlong2.LatLng(event.lat, event.long),
          author: 'Author ${event.author}',
          category: event.category,
          title: event.title,
          tag: event.tag,
          progress: 0.5,
          onTap: () {
            _toggleEventDetails(event);
          },
          onAction: () {},
        ),
    ];
  }

  @override
  StatelessWidget getClusterWidget(List<MapMarker> mapMarkers) {
    return MarkerClusterLayerWidget(
      options: MarkerClusterLayerOptions(
        size: const Size(40, 40),
        maxZoom: 15,
        markers: mapMarkers,
        builder: (context, combinedMarkers) {
          return Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color.fromARGB(255, 58, 133, 183),
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: Text(
                combinedMarkers.length.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  StatefulWidget getMapWidget(List<EventModel> events) {
    return FlutterMap(
      options: MapOptions(
        initialCenter: latlong2.LatLng(41.9028, 12.4963),
        initialZoom: 6,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.ingv_app',
        ),
        getClusterWidget(generateMarkers(events)),
      ],
    );
  }

  Future<void> _loadEvents() async {
    await _viewModel.fetchEvents();
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
                          final DateTimeRange? picked =
                              await showDateRangePicker(
                                context: context,
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2101),
                                initialDateRange:
                                    _viewModel.filterStartDate != null &&
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
                      Search(viewModel: _viewModel)
                    ],
                  ),
                ),
                Expanded(child: getMapWidget(_viewModel.events)),
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
