import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong2;
import 'package:ingv_app/ui/map/view_models/map_view_model.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:ingv_app/ui/map/widgets/map_marker.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late final MapScreenViewModel _viewModel;
  @override
  void initState() {
    super.initState();
    {
      _viewModel = MapScreenViewModel();
    }
  }

  @override
  Widget build(BuildContext context) {
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
        MarkerClusterLayerWidget(
          options: MarkerClusterLayerOptions(
            size: const Size(40, 40),
            maxZoom: 15,
            markers: [
              // TODO: dit moet naar een lijst van de backend die widgets aan maakt
              Marker(
                point: latlong2.LatLng(41.9028, 12.4863),
                width: 20,
                height: 20,
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.red,
                  ),
                ),
              ),
              Marker(
                point: latlong2.LatLng(41.9028, 12.4863),
                width: 20,
                height: 20,
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.red,
                  ),
                ),
              ),
              MapMarker(
                point: latlong2.LatLng(41.9028, 12.4863),
                title: "Sample Marker",
                author: "John Doe",
                category: "Sample Category",
                tag: "Sample Tag",
                progress: 0.5,
                onAction: () {
                  // TODO: dit in de class zelf zetten
                },
              ),
            ],
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
        ),
      ],
    );
  }
}
