import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:ingv_app/ui/timeline/widgets/timeline_canvas.dart';
import 'package:ingv_app/ui/shared/view_models/event_tooltip_helper.dart';
import 'package:ingv_app/data/models/event_model.dart';

Widget buildEventContainer(String eventId, TimelineCanvas widget) {
  final eventIndex = widget.events.indexWhere(
    (e) => e.eventId.toString() == eventId,
  );
  if (eventIndex == -1) {
    return const SizedBox.shrink();
  }

  final EventModel event = widget.events[eventIndex];

  final String startStringTime = event.startDt
      .toLocal()
      .toString()
      .split(' ')[1]
      .substring(0, 5);

  final String endStringTime = event.endDt != null
      ? event.endDt!.toLocal().toString().split(' ')[1].substring(0, 5)
      : '';

  final String duration = formatDuration(event.startDt, event.endDt);

  final String tooltipMessage =
      'Title: ${event.title}\n'
      'Start: ${formatDateTimeTooltip(event.startDt)}\n'
      'End: ${event.endDt != null ? formatDateTimeTooltip(event.endDt) : 'Ongoing'}\n'
      'Duration: $duration\n'
      '${formatLocation(event.lat, event.long)}';

  final categoryTasks = widget.getTimelineTasksForCategory(
    event.category.trim(),
  );
  final taskIndex = categoryTasks.indexWhere((t) => t.id == eventId);
  final Color itemColor = taskIndex == -1
      ? Colors.grey
      : categoryTasks[taskIndex].color;

  final bool isSelected = widget.selectedEvent?.eventId == event.eventId;

  return Align(
    alignment: Alignment.centerLeft,
    child: GestureDetector(
      onTap: () => widget.onEventTap(event),
      child: Tooltip(
        message: tooltipMessage,
        child: event.endDt == null
            ? OverflowBox(
                minWidth: 24.0,
                maxWidth: 24.0,
                minHeight: 24.0,
                maxHeight: 24.0,
                child: Container(
                  decoration: BoxDecoration(
                    color: itemColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                    border: isSelected
                        ? Border.all(color: Colors.white, width: 2)
                        : Border.all(color: Colors.white, width: 1),
                  ),
                  child: const Center(
                    child: Text(
                      '\u2026',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        height: 1.0,
                      ),
                    ),
                  ),
                ),
              )
            : LayoutBuilder(
                builder: (context, constraints) {
                  final double availWidth = constraints.maxWidth;
                  final double contentOffset = _calculateVisibleContentOffset(
                    event,
                    widget,
                    availWidth,
                  );
                  return Container(
                    alignment: Alignment.topLeft,
                    height: 45.0,
                    clipBehavior: Clip.hardEdge,
                    decoration: BoxDecoration(
                      color: itemColor,
                      border: isSelected
                          ? Border.all(color: Colors.white, width: 2)
                          : null,
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Positioned(
                          left: contentOffset,
                          top: 0,
                          right: 0,
                          bottom: 0,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6.0,
                              vertical: 4.0,
                            ),
                            child: _buildEventCardContent(
                              event,
                              duration,
                              startStringTime,
                              endStringTime,
                              math.max(0, availWidth - contentOffset),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    ),
  );
}

Widget _buildEventCardContent(
  EventModel event,
  String duration,
  String startStringTime,
  String endStringTime,
  double availableWidth,
) {
  if (availableWidth < 28) {
    return const Center(
      child: Text('...', style: TextStyle(color: Colors.white70, fontSize: 11)),
    );
  }

  if (availableWidth < 60) {
    return Center(
      child: Text(
        duration,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  if (availableWidth < 120) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          event.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          duration,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ],
    );
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Expanded(
        child: Text(
          event.title,
          textAlign: TextAlign.left,
          maxLines: 1,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            flex: 2,
            child: Text(
              '$startStringTime - $endStringTime',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ),
          const SizedBox(width: 4),
          Flexible(
            flex: 1,
            child: Text(
              duration,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ),
        ],
      ),
    ],
  );
}

double _calculateVisibleContentOffset(
  EventModel event,
  TimelineCanvas widget,
  double availableWidth,
) {
  final eventEnd = event.endDt;
  if (eventEnd == null || availableWidth <= 0) return 0;

  final DateTime visibleStart =
      widget.filterStartDate ?? widget.clientBaselineStart;

  if (!event.startDt.isBefore(visibleStart)) return 0;

  final int eventDurationMs = eventEnd.difference(event.startDt).inMilliseconds;
  if (eventDurationMs <= 0) return 0;

  final int hiddenDurationMs = visibleStart
      .difference(event.startDt)
      .inMilliseconds;
  if (hiddenDurationMs <= 0) return 0;

  final double hiddenRatio = hiddenDurationMs / eventDurationMs;
  final double desiredOffset = availableWidth * hiddenRatio;
  const double minimumReadableWidth = 80.0;
  final double maxOffset = math.max(0, availableWidth - minimumReadableWidth);

  return desiredOffset.clamp(0, maxOffset).toDouble();
}
