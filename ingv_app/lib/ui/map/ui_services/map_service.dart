import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart' as latlong2;
import 'package:ingv_app/ui/map/view_models/map_view_model.dart';
import 'package:ingv_app/ui/map/ui_services/map_service_interface.dart';
import 'package:ingv_app/ui/map/widgets/map_marker.dart';
import 'package:ingv_app/data/repositories/event_repository.dart';
import 'package:ingv_app/data/repositories/event_search_repository.dart';

class MapServiceUI implements IMapService {
  final String userAgentPackageName;

  MapServiceUI({required this.userAgentPackageName});

 @override
  Widget buildMap({
    required double initialLat,
    required double initialLng,
    required double initialZoom,
    required List<AppMarker> markers,
    required MapScreenViewModel mapViewModel,
  }) {
    final List<Marker> flutterMarkers = markers.map((m) {
      return Marker(
        // Use an ObjectKey containing the original AppMarker data
        key: ObjectKey(m), 
        point: latlong2.LatLng(m.latitude, m.longitude),
        width: m.size,
        height: m.size,
        child: AppMapMarkerWidget(marker: m),
      );
    }).toList();

    return FlutterMap(
      mapController: mapViewModel.mapController,
      options: MapOptions(
        initialCenter: latlong2.LatLng(initialLat, initialLng),
        initialZoom: initialZoom,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: userAgentPackageName,
        ),
        _buildClusterLayer(flutterMarkers, mapViewModel),
      ],
    );
  }

  Widget _buildClusterLayer(List<Marker> markers, MapScreenViewModel mapViewModel) {
    return MarkerClusterLayerWidget(
      options: MarkerClusterLayerOptions(
        size: const Size(50, 50), // Increased slightly to comfortably hold text + progress ring
        maxZoom: 15,
        markers: markers,
        builder: (context, combinedMarkers) {
          // Extract the AppMarker instances back from the ObjectKeys
          final List<AppMarker> appMarkers = combinedMarkers
          .map((m) => (m.key as ObjectKey).value as AppMarker)
          .toList();
          final double avgProgress = mapViewModel.calculateAverageDuration(appMarkers);

          return Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 39,
                height: 39,
                child: CircularProgressIndicator(
                  value: avgProgress,
                  strokeWidth: 6,
                  color: Colors.deepPurple, 
                  backgroundColor: Colors.white24,
                ),
              ),
              // Inner cluster circle
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color.fromARGB(255, 58, 133, 183),
                  border: Border.all(color: Colors.white, width: 1.5),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    combinedMarkers.length.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Moved safely back into MapServiceUI where userAgentPackageName is defined
  @override
  Widget buildPreviewMap({
    required double latitude,
    required double longitude,
    required double initialZoom,
  }) {
    final eventLocation = latlong2.LatLng(latitude, longitude);

    return FlutterMap(
      options: MapOptions(
        initialCenter: eventLocation,
        initialZoom: initialZoom,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: userAgentPackageName,
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: eventLocation,
              width: 40,
              height: 40,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withValues(alpha: 0.4),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.location_on,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

}
class MarkerClusterLayerWidget extends StatelessWidget {
  final MarkerClusterLayerOptions options;
  const MarkerClusterLayerWidget({super.key, required this.options});

  @override
  Widget build(BuildContext context) {
    return MarkerClusterLayer(
      mapController: MapController.of(context),
      mapCamera: MapCamera.of(context),
      options: options,
    );
  }
}
