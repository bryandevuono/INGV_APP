import 'package:flutter/material.dart';
import 'package:ingv_app/data/models/group_model.dart';
import 'package:ingv_app/ui/event_detail/view_models/event_detail_view_model.dart';
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

  static ValueKey _mapPreviewKey(EventDetailViewModel vm) {
    final event = vm.selectedEvent;
    if (event == null) return const ValueKey('map_null');
    return ValueKey('map_${event.eventId}_${event.lat}_${event.long}');
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 980;

        return ListenableBuilder(
          listenable: viewModel,
          builder: (context, _) {
            if (isWide) {
              return SizedBox(
                height: constraints.maxHeight,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 6,
                        child: SingleChildScrollView(
                          physics: const ClampingScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              EventMediaSection(viewModel: viewModel),
                              const SizedBox(height: 12),
                              EventNotesSection(
                                viewModel: viewModel,
                                groupOptions: groupOptions,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        flex: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: EventMapPreview(
                                key: _mapPreviewKey(viewModel),
                                viewModel: viewModel,
                                mapService: MapServiceUI(
                                  userAgentPackageName: 'ingv_app',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(14),
              physics: const ClampingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  EventMediaSection(viewModel: viewModel),
                  const SizedBox(height: 12),
                  EventMapPreview(
                    key: _mapPreviewKey(viewModel),
                    viewModel: viewModel,
                    mapService: MapServiceUI(userAgentPackageName: 'ingv_app'),
                    height: 280,
                  ),
                  const SizedBox(height: 12),
                  EventNotesSection(
                    viewModel: viewModel,
                    groupOptions: groupOptions,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
