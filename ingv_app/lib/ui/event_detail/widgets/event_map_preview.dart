// lib/ui/event_detail/widgets/event_map_preview.dart
import 'package:flutter/material.dart';
import 'package:ingv_app/ui/event_detail/view_models/event_detail_view_model.dart';
import 'package:ingv_app/ui/map/ui_services/map_service_interface.dart'; 
class EventMapPreview extends StatelessWidget {
  final EventDetailViewModel viewModel;
  final IMapService mapService; 

  const EventMapPreview({
    super.key, 
    required this.viewModel,
    required this.mapService,
  });

  @override
  Widget build(BuildContext context) {
    if (viewModel.selectedEvent == null) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(6),
        ),
      );
    }

    final event = viewModel.selectedEvent!;

    return Container(
      height: 200,
      padding: const EdgeInsets.all(0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(6),
      ),
      clipBehavior: Clip.antiAlias,
      child: mapService.buildPreviewMap(
        latitude: event.lat,
        longitude: event.long,
        initialZoom: 10,
      ),
    );
  }
}