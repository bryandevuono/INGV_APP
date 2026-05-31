import 'package:ingv_app/ui/map/widgets/map_marker.dart'; 
import 'package:flutter/material.dart';
import 'package:ingv_app/data/models/event_model.dart';

abstract interface class IMap{
  List<MapMarker> generateMarkers(List<EventModel> events);
  StatefulWidget getMapWidget(List<EventModel> events);
  StatelessWidget getClusterWidget(List<MapMarker> mapMarkers);
}