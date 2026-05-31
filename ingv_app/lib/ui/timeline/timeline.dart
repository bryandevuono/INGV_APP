import 'package:flutter_gantt/flutter_gantt.dart';
import 'package:flutter/material.dart';
import 'package:ingv_app/data/repositories/event_repository.dart';
import 'package:ingv_app/ui/map/view_models/timeline_view_model.dart';
import 'timeline_interface.dart';

class TimelineScreen extends StatefulWidget {
  final EventRepository eventRepository;
  const TimelineScreen({super.key, required this.eventRepository});

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> implements ITimeline {
  late final TimelineViewModel _viewModel;

  final Map<String, Color> cellColors = {
    "Volcanic": Colors.red,
    "Earthquake": Colors.green,
    "Hydrological": Colors.blue,
    "Meteorological": Colors.orange,
    "Geological": Colors.purple,
    "Atmospheric": Colors.cyan,
  };

  @override
  void initState() {
    super.initState();
    _viewModel = TimelineViewModel(widget.eventRepository);
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    await _viewModel.fetchEvents();
  }

  // TODO: Calculate start date based on earliest event
  final startDate = DateTime(2026, 5, 31);
  
  @override
  StatefulWidget buildTimeline(events) {
   return Gantt(
      startDate: startDate,
      activities: [
        for (var event in events)
          GanttActivity(
            key: event.eventId.toString(),
            title: event.title,
            start: event.startDt,
            end: event.endDt,
            color: cellColors[event.category] ?? Colors.grey,
            builder: (activity) {
              return Container(
                alignment: Alignment.topLeft,
                color: activity.color,
                child: Column(
                  children: [
                    Text(
                      event.title,
                      textAlign: TextAlign.left,
                      style: const TextStyle(color: Colors.white),
                    ),
                    Row(
                      children: [
                        Text(
                          "${event.startDt.toString().split(' ')[1]} - ${event.endDt.toString().split(' ')[1]}",
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12),
                        ),
                        Text(
                          "${event.endDt.difference(event.startDt).inHours} hrs",
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12),
                        )
                      ],
                    )
                  ],
                ),
              );
            },
          ),
      ],
      theme: const GanttTheme(
        dayMinWidth: 200.0,
        cellHeight: 60.0,
      ),
      onActivityChanged: (activity, start, end) {},
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        if (_viewModel.events.isEmpty) {
          return const Center();
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SizedBox(
                    width: 200,
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    color: Colors.blue,
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      // Handle plus button press
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: buildTimeline(_viewModel.events),
            ),
          ],
        );
      },
    );
  }
}
