import 'package:flutter_gantt/flutter_gantt.dart';
import 'package:flutter/material.dart';
import 'package:ingv_app/data/repositories/event_repository.dart';
import 'package:ingv_app/ui/map/view_models/timeline_view_model.dart';

class TimelineScreen extends StatefulWidget {
  final EventRepository eventRepository;
  const TimelineScreen({super.key, required this.eventRepository});

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  late final TimelineViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = TimelineViewModel(widget.eventRepository);
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
        if (_viewModel.events.isEmpty) {
          return const Center(child: CircularProgressIndicator()); // TODO: remove progress
        }

        // finds the earliest date
        final startDate = _viewModel.events
            .map((e) => e.startDt)
            .reduce((a, b) => a.isBefore(b) ? a : b);

        return Gantt(
          startDate: startDate,
          activities: [
            for (var event in _viewModel.events)
              GanttActivity(
                key: event.eventId.toString(),
                title: event.title,
                start: event.startDt,
                end: event.endDt,
              ),
          ],
          theme: GanttTheme.of(context),
          onActivityChanged: (activity, start, end) {
            if (start != null && end != null) {
              debugPrint('$activity was moved (Event on widget)');
            } else if (start != null) {
              debugPrint('$activity start was moved (Event on widget)');
            } else if (end != null) {
              debugPrint('$activity end was moved (Event on widget)');
            }
          },
        );
      },
    );
  }
}

