import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong2;
import 'package:ingv_app/ui/map/view_models/map_view_model.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:ingv_app/ui/map/widgets/map_marker.dart';
import 'package:ingv_app/data/repositories/event_repository.dart';
import 'package:ingv_app/ui/map/widgets/map_interface.dart';
import 'package:ingv_app/data/models/event_model.dart';

class MapScreen extends IMap {
  final EventRepository eventRepository;

  const MapScreen({super.key, required this.eventRepository});

  @override
  State<MapScreen> createState() => _MapScreenState();

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
}

class _MapScreenState extends State<MapScreen> {
  late final MapScreenViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = MapScreenViewModel(widget.eventRepository);
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    await _viewModel.fetchEvents();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        return widget.getMapWidget(_viewModel.events);
      },
    );
  }
}

