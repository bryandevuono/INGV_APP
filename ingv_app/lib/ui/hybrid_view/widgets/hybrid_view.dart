import 'package:flutter/material.dart';
import 'package:ingv_app/ui/hybrid_view/view_model/hybrid_view_model.dart';

class ResizableHybridView extends StatefulWidget {
  final Widget topWidget;
  final Widget bottomWidget;
  final HybridViewModel? viewModel;

  const ResizableHybridView({
    super.key,
    required this.topWidget,
    required this.bottomWidget,
    this.viewModel,
  });

  @override
  State<ResizableHybridView> createState() => _ResizableHybridViewState();
}

class _ResizableHybridViewState extends State<ResizableHybridView> {
  late final HybridViewModel _effectiveViewModel;

  @override
  void initState() {
    super.initState();
    // Use the passed instance, or safely fallback to a local one
    _effectiveViewModel = widget.viewModel ?? HybridViewModel();
  }

  @override
  void dispose() {
    // Only dispose if we created it locally to prevent breaking parent scopes
    if (widget.viewModel == null) {
      _effectiveViewModel.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _effectiveViewModel, // No more null-assertion issues
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

            return Column(
              children: [
                // Top Component
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
                    height: dividerHeight, // Exactly 12.0 pixels
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

                // Bottom Component
                SizedBox(
                  height: bottomHeight,
                  width: double.infinity,
                  child: ClipRect(child: widget.bottomWidget),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
