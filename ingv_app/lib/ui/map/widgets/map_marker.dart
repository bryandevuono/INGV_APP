// lib/infrastructure/map/widgets/app_map_marker_widget.dart
import 'package:flutter/material.dart';
import 'package:ingv_app/ui/map/ui_services/map_service_interface.dart';

class AppMapMarkerWidget extends StatelessWidget {
  final AppMarker marker;

  const AppMapMarkerWidget({super.key, required this.marker});

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
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              marker.title,
                              style: const TextStyle(
                                fontSize: 38,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF444444),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const SizedBox(width: 8),
                                Text(
                                  "Author: ${marker.author}",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 40),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                "Category:",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black54,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                color: marker.categoryColor,
                                child: Text(
                                  marker.category,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Text(
                                "Tag:",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black54,
                                ),
                              ),
                              const SizedBox(width: 46),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: marker.tagColor,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  marker.tag,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: SizedBox(
                      width: 150,
                      height: 32,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF76A7FF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: marker.onAction,
                        child: const Text(
                          "Submit a note",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 2,
              height: 20,
              color: Colors.black54,
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