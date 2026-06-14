// lib/ui/map/interfaces/map_service_interface.dart
import 'package:flutter/material.dart';
// interface to add a abstraction layer to flutter maps
// lib/domain/models/app_marker.dart
import 'package:flutter/material.dart';

class AppMarker {
  final double latitude;
  final double longitude;
  final String title;
  final String author;
  final String category;
  final double progress;
  final DateTime? startDateTime;
  final DateTime? endDateTime;
  final VoidCallback onTap;
  
  final Color categoryColor;
  final Color tagColor;
  final Color fillColor;
  final Color ringColor;
  final double size;

  const AppMarker({
    required this.latitude,
    required this.longitude,
    required this.title,
    required this.author,
    required this.category,
    required this.startDateTime,
    required this.endDateTime,
    this.progress = 0.5,
    required this.onTap,
    this.categoryColor = const Color(0xFFFFE082), 
    this.tagColor = Colors.red,
    this.fillColor = const Color(0xFF39D353),
    this.ringColor = Colors.deepPurple,
    this.size = 28,
  });
}

abstract class IMapService {
  Widget buildMap({
    required double initialLat,
    required double initialLng,
    required double initialZoom,
    required List<AppMarker> markers,
  });
  
  Widget buildPreviewMap({
    required double latitude,
    required double longitude,
    required double initialZoom,
  });
}