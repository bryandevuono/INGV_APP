import 'package:flutter/material.dart';
import 'package:ingv_app/data/models/group_model.dart';
import 'package:ingv_app/ui/event_detail/view_models/event_detail_view_model.dart';
import 'package:ingv_app/ui/event_detail/widgets/event_overview_card.dart';
import 'package:ingv_app/ui/event_detail/widgets/event_notes_section.dart';
import 'package:ingv_app/ui/event_detail/widgets/event_media_section.dart';
import 'package:ingv_app/ui/event_detail/widgets/event_map_preview.dart';
import 'package:ingv_app/ui/map/ui_services/map_service.dart';

class EventDetailContent extends StatelessWidget {
  final EventDetailViewModel viewModel;
  final List<GroupModel> groupOptions;

  const EventDetailContent({
    super.key,
    required this.viewModel,
    this.groupOptions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: ListenableBuilder(
        listenable: viewModel,
        builder: (context, _) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left section: Overview and Notes
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    EventOverviewCard(viewModel: viewModel),
                    const SizedBox(height: 16),
                    EventNotesSection(
                      viewModel: viewModel,
                      groupOptions: groupOptions,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Right section: Media, Attachments & Map
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    EventMediaSection(viewModel: viewModel),
                    const SizedBox(height: 16),
                    EventMapPreview(viewModel: viewModel, mapService: MapServiceUI(userAgentPackageName: 'ingv_app')), 
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
