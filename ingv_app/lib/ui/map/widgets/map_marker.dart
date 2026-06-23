import 'package:flutter/material.dart';
import 'package:ingv_app/ui/map/ui_services/map_service_interface.dart';
import 'package:ingv_app/ui/shared/view_models/event_tooltip_helper.dart';

class AppMapMarkerWidget extends StatelessWidget {
  final AppMarker marker;
  const AppMapMarkerWidget({super.key, required this.marker});

  String _tooltipInfo(AppMarker m) {
    final start = formatDateShort(m.startDateTime);
    final end = m.endDateTime != null
        ? formatDateShort(m.endDateTime!)
        : 'Ongoing';
    final duration = formatDuration(
      m.startDateTime ?? DateTime.now(),
      m.endDateTime,
    );
    final location = formatLocation(m.latitude, m.longitude);

    return 'Author: ${m.author}\n'
        '$location\n'
        'Start: $start\n'
        'End: $end\n'
        'Duration: $duration';
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      preferBelow: false,
      verticalOffset: 20,
      waitDuration: const Duration(milliseconds: 200),
      showDuration: const Duration(seconds: 15),
      padding: EdgeInsets.zero,
      decoration: const BoxDecoration(color: Colors.transparent),
      richMessage: WidgetSpan(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // The Main Card Content
            Container(
              width: 520,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                border: Border.all(color: Colors.black54, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  marker.title,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                  style: const TextStyle(
                                    fontSize: 38,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF444444),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _tooltipInfo(marker),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 20),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    "Category:",
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: 100,
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      color: marker.categoryColor,
                                      child: Text(
                                        marker.category,
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: SizedBox(
                      width: 150,
                      height: 32,
                      child: Material(
                        color: const Color(0xFF76A7FF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: InkWell(
                          onTap: () {
                            marker.onTap();
                          },
                          child: const SizedBox(
                            width: double.infinity,
                            height: double.infinity,
                            child: Center(
                              child: Text(
                                "See event details",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      child: GestureDetector(
        onTap: marker.onTap,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: marker.size,
              height: marker.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: marker.fillColor,
              ),
            ),
            SizedBox(
              width: marker.size,
              height: marker.size,
              child: CircularProgressIndicator(
                value: marker.progress,
                strokeWidth: 6,
                color: marker.ringColor,
                backgroundColor: Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
