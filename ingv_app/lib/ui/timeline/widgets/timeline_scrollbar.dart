import 'package:flutter/material.dart';

class TimelineScrollbar extends StatelessWidget {
  final double scrollOffset;
  final bool isDragging;
  final GestureDragStartCallback? onDragStart;
  final GestureDragUpdateCallback? onDragUpdate;
  final GestureDragEndCallback? onDragEnd;

  const TimelineScrollbar({
    super.key,
    required this.scrollOffset,
    required this.isDragging,
    this.onDragStart,
    this.onDragUpdate,
    this.onDragEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Drag to move timeline',
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragStart: onDragStart,
        onHorizontalDragUpdate: onDragUpdate,
        onHorizontalDragEnd: onDragEnd,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final availableWidth = constraints.maxWidth;
            const thumbWidth = 100.0;
            final maxOffset = availableWidth - thumbWidth;
            final thumbOffset = scrollOffset.clamp(
              -maxOffset * 0.3,
              maxOffset * 0.3,
            );

            return Stack(
              alignment: Alignment.center,
              children: [
                // Track
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                // Draggable thumb
                Positioned(
                  left: (availableWidth / 2) - (thumbWidth / 2) + thumbOffset,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    width: thumbWidth,
                    height: 22,
                    decoration: BoxDecoration(
                      color: isDragging
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.primary.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.drag_handle_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}