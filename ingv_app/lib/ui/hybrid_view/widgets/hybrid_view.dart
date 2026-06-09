import 'package:flutter/material.dart';
import 'package:ingv_app/ui/hybrid_view/view_model/hybrid_view_model.dart';

class ResizableHybridView extends StatefulWidget {
  final Widget topWidget;
  final Widget bottomWidget;

  const ResizableHybridView({
    super.key,
    required this.topWidget,
    required this.bottomWidget,
  });

  @override
  State<ResizableHybridView> createState() => _ResizableHybridViewState();
}

class _ResizableHybridViewState extends State<ResizableHybridView> {
  late HybridViewModel viewModel;

  @override
  void initState() {
    super.initState();
    viewModel = HybridViewModel();
  }

  @override
  void dispose() {
    viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final totalHeight = constraints.maxHeight;

            const double dividerHeight = 12.0;

            final availableHeight = totalHeight - dividerHeight;

            final topHeight = availableHeight * viewModel.topHeightRatio;
            final bottomHeight =
                availableHeight * (1 - viewModel.topHeightRatio);

            return Column(
              children: [
                // Top Component
                SizedBox(
                  height: topHeight,
                  width: double.infinity,
                  child: ClipRect(
                    child: widget.topWidget,
                  ), 
                ),

                GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onVerticalDragUpdate: (details) {
                    viewModel.changeRatio(details.delta.dy, availableHeight);
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

                // Bottom 
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
