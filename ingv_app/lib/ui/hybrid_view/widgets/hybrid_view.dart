import 'package:flutter/material.dart';
import 'package:ingv_app/ui/hybrid_view/view_model/hybrid_view_model.dart';
import 'package:ingv_app/ui/event_detail/view_models/event_detail_view_model.dart';
import 'package:ingv_app/ui/event_detail/widgets/event_detail_panel.dart';
import 'package:ingv_app/data/models/event_model.dart';

class ResizableHybridView extends StatefulWidget {
  final Widget topWidget;
  final Widget bottomWidget;
  final HybridViewModel? viewModel;
  final EventDetailViewModel? detailViewModel;
  final ValueChanged<bool>? onPanelToggle;

  const ResizableHybridView({
    super.key,
    required this.topWidget,
    required this.bottomWidget,
    this.viewModel,
    this.detailViewModel,
    this.onPanelToggle,
  });

  @override
  State<ResizableHybridView> createState() => _ResizableHybridViewState();
}

class _ResizableHybridViewState extends State<ResizableHybridView> {
  late final HybridViewModel _effectiveViewModel;

  @override
  void initState() {
    super.initState();
    _effectiveViewModel = widget.viewModel ?? HybridViewModel();
  }

  @override
  void dispose() {
    if (widget.viewModel == null) {
      _effectiveViewModel.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _effectiveViewModel,
      builder: (context, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final totalHeight = constraints.maxHeight;
            const double dividerHeight = 12.0;
            final availableHeight = totalHeight - dividerHeight;

            final topHeight =
                availableHeight * _effectiveViewModel.topHeightRatio;
            final bottomHeight =
                availableHeight * (1 - _effectiveViewModel.topHeightRatio);

            return Stack(
              children: [
                Column(
                  children: [
                    SizedBox(
                      height: topHeight,
                      width: double.infinity,
                      child: ClipRect(child: widget.topWidget),
                    ),
                    GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onVerticalDragUpdate: (details) {
                        _effectiveViewModel.changeRatio(
                          details.delta.dy,
                          availableHeight,
                        );
                      },
                      child: Container(
                        color: Colors.grey[300],
                        height: dividerHeight,
                        width: double.infinity,
                        child: Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.grey[600],
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: bottomHeight,
                      width: double.infinity,
                      child: ClipRect(child: widget.bottomWidget),
                    ),
                  ],
                ),
                // Overlay: dimmed backdrop + detail panel that covers entire hybrid view area
                if (widget.viewModel != null &&
                    widget.viewModel!.selectedEvent != null &&
                    widget.detailViewModel != null)
                  GestureDetector(
                    onTap: () {
                      widget.viewModel!.clearEvent();
                      widget.detailViewModel!.clearEventDetails();
                      widget.onPanelToggle?.call(false);
                    },
                    child: Container(
                      color: Colors.black45,
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: SizedBox(
                          width: double.infinity,
                          child: AnimatedSlide(
                            offset: Offset.zero,
                            duration: const Duration(milliseconds: 350),
                            curve: Curves.fastOutSlowIn,
                            child: SizedBox(
                              height: constraints.maxHeight * 0.8,
                              child: EventDetailPanel(
                                viewModel: widget.detailViewModel!,
                                groupOptions: const [],
                                onEventUpdated: (updatedEvent) async {
                                  widget.viewModel!.selectEvent(
                                    updatedEvent,
                                    fromMap: widget.viewModel!.selectedFromMap,
                                  );
                                },
                                onDismiss: () {
                                  widget.viewModel!.clearEvent();
                                  widget.detailViewModel!.clearEventDetails();
                                  widget.onPanelToggle?.call(false);
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}
