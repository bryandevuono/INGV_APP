import 'package:flutter/material.dart';
import 'package:ingv_app/data/models/group_model.dart';
import 'package:ingv_app/data/models/event_model.dart';
import 'package:ingv_app/ui/event_detail/view_models/event_detail_view_model.dart';
import 'package:ingv_app/ui/event_detail/widgets/event_detail_header.dart';
import 'package:ingv_app/ui/event_detail/widgets/event_detail_content.dart';
import 'package:ingv_app/ui/event_detail/widgets/edit_event_dialog.dart';

class EventDetailPanel extends StatefulWidget {
  final EventDetailViewModel viewModel;
  final VoidCallback onDismiss;
  final List<GroupModel> groupOptions;
  final Future<void> Function(EventModel updatedEvent)? onEventUpdated;

  const EventDetailPanel({
    super.key,
    required this.viewModel,
    required this.onDismiss,
    this.groupOptions = const [],
    this.onEventUpdated,
  });

  @override
  State<EventDetailPanel> createState() => _EventDetailPanelState();
}

class _EventDetailPanelState extends State<EventDetailPanel>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  double _dragOffset = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset = (_dragOffset + details.delta.dy).clamp(
        0.0,
        double.infinity,
      );
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    if (_dragOffset > 100 || details.velocity.pixelsPerSecond.dy > 500) {
      _animationController.reverse().then((_) {
        widget.onDismiss();
      });
    } else {
      setState(() {
        _dragOffset = 0;
      });
    }
  }

  Future<void> _openEditDialog(BuildContext context) async {
    final selectedEvent = widget.viewModel.selectedEvent;
    if (selectedEvent == null) return;

    final updatedEvent = await showEditEventDialog(
      context,
      event: selectedEvent,
      eventRepository: widget.viewModel.eventRepository,
      groupOptions: widget.groupOptions,
    );

    if (!context.mounted || updatedEvent == null) return;

    await widget.viewModel.updateSelectedEvent(updatedEvent);
    if (widget.onEventUpdated != null) {
      await widget.onEventUpdated!(updatedEvent);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final panelHeight = screenHeight * 0.65;

    return SlideTransition(
      position: _slideAnimation,
      child: GestureDetector(
        onVerticalDragUpdate: _handleDragUpdate,
        onVerticalDragEnd: _handleDragEnd,
        child: Transform.translate(
          offset: Offset(0, _dragOffset),
          child: Container(
            height: panelHeight,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            // We change the top-level child to a Stack so we can absolutely position the X button
            child: Stack(
              children: [
                // Main content column
                Column(
                  children: [
                    // Drag handle indicator
                    GestureDetector(
                      onTap: () {
                        _animationController.reverse().then((_) {
                          widget.onDismiss();
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade400,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListenableBuilder(
                        listenable: widget.viewModel,
                        builder: (context, _) {
                          final selectedEvent = widget.viewModel.selectedEvent;
                          if (selectedEvent == null) {
                            return const SizedBox.shrink();
                          }

                          return Column(
                            children: [
                              EventDetailHeader(
                                event: selectedEvent,
                                viewModel: widget.viewModel,
                                onDismiss: widget.onDismiss,
                                onEdit: () => _openEditDialog(context),
                              ),
                              Expanded(
                                child: EventDetailContent(
                                  viewModel: widget.viewModel,
                                  groupOptions: widget.groupOptions,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),

                // Top Right Close Cross
                Positioned(
                  top: 4,
                  right: 4,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.black54),
                    onPressed: () {
                      _animationController.reverse().then((_) {
                        widget.onDismiss();
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
