// lib/ui/event_detail/widgets/event_map_preview.dart
import 'package:flutter/material.dart';
import 'package:ingv_app/ui/event_detail/view_models/event_detail_view_model.dart';
import 'package:ingv_app/ui/map/ui_services/map_service_interface.dart';

class EventMapPreview extends StatelessWidget {
  final EventDetailViewModel viewModel;
  final IMapService mapService;
  final double? height;

  const EventMapPreview({
    super.key,
    required this.viewModel,
    required this.mapService,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    if (viewModel.selectedEvent == null) {
      return _buildFrame(child: Container(color: Colors.grey.shade200));
    }

    final event = viewModel.selectedEvent!;

    return _buildFrame(
      child: mapService.buildPreviewMap(
        latitude: event.lat,
        longitude: event.long,
        initialZoom: 10,
      ),
    );
  }

  Widget _buildFrame({required Widget child}) {
    final map = DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(6),
      ),
      child: ClipRRect(borderRadius: BorderRadius.circular(6), child: child),
    );

    if (height != null) {
      return SizedBox(height: height, child: map);
    }

    return SizedBox.expand(child: map);
  }
}
