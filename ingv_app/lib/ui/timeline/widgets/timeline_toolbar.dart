import 'package:flutter/material.dart';
import 'package:ingv_app/ui/shared/controllers/event_filter_controller.dart';
import 'package:ingv_app/ui/shared/widgets/event_filter_action_bar.dart';
import 'package:ingv_app/ui/timeline/view_models/timeline_interface.dart';

class TimelineToolbar extends StatelessWidget {
  final ITimelineViewModel viewModel;
  final EventFilterController? filterController;
  final VoidCallback? onAddEvent;
  final VoidCallback onNavigatePast;
  final VoidCallback onNavigateFuture;
  final Duration currentScale;
  final List<(Duration, String, String)> scaleOptions;
  final ValueChanged<Duration> onScaleChanged;
  final Future<void> Function() onPickDateRange;
  final VoidCallback onClearDateFilter;
  final Future<void> Function() onExportPdf;
  final Future<void> Function() onExportZip;
  final Future<void> Function() onExportJson;
  final Future<void> Function() onExportCsv;
  final Future<void> Function() onExportDateRangePdf;
  final Future<void> Function() onExportDateRangeZip;
  final Future<void> Function() onExportDateRangeJson;
  final Future<void> Function() onExportDateRangeCsv;

  const TimelineToolbar({
    super.key,
    required this.viewModel,
    this.filterController,
    this.onAddEvent,
    required this.onNavigatePast,
    required this.onNavigateFuture,
    required this.currentScale,
    required this.scaleOptions,
    required this.onScaleChanged,
    required this.onPickDateRange,
    required this.onClearDateFilter,
    required this.onExportPdf,
    required this.onExportZip,
    required this.onExportJson,
    required this.onExportCsv,
    required this.onExportDateRangePdf,
    required this.onExportDateRangeZip,
    required this.onExportDateRangeJson,
    required this.onExportDateRangeCsv,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 600;

            final navigationWidgets = [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                tooltip: 'Go back ${_currentScaleLabel()}',
                onPressed: onNavigatePast,
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios, size: 20),
                tooltip: 'Go forward ${_currentScaleLabel()}',
                onPressed: onNavigateFuture,
              ),
              const SizedBox(width: 12),
              _buildTimeScaleSelector(),
            ];

            final actionFilterBar = EventFilterActionBar(
              categories: {'All', ...viewModel.categories}.toList(),
              selectedCategory: viewModel.selectedCategory,
              searchQuery: viewModel.searchQuery,
              startDate: viewModel.filterStartDate,
              endDate: viewModel.filterEndDate,
              showCategoryDropdown: true,
              showDateFilter: true,
              showSearch: true,
              showExportPdf: true,
              showExportZip: true,
              showExportJson: true,
              showExportCsv: true,
              showAddEvent: true,
              isExporting: viewModel.isExporting,
              embeddedInPage: true,
              onCategoryChanged: (newValue) {
                viewModel.setCategoryFilter(newValue);
                filterController?.setCategory(newValue);
              },
              onDateRangePicked: onPickDateRange,
              onClearDateFilter: onClearDateFilter,
              onSearchChanged: (query) {
                viewModel.setSearchQuery(query);
                filterController?.setSearchQuery(query);
              },
              searchSuggestions: viewModel.searchSuggestions,
              onSuggestionSelected: (event) {
                viewModel.selectSuggestion(event);
              },
              onExportPdf: onExportPdf,
              onExportZip: onExportZip,
              onExportJson: onExportJson,
              onExportCsv: onExportCsv,
              onExportDateRangePdf: onExportDateRangePdf,
              onExportDateRangeZip: onExportDateRangeZip,
              onExportDateRangeJson: onExportDateRangeJson,
              onExportDateRangeCsv: onExportDateRangeCsv,
              onAddEvent: onAddEvent,
            );

            if (isMobile) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: navigationWidgets,
                  ),
                  const SizedBox(height: 12),
                  actionFilterBar,
                ],
              );
            }

            return Row(
              children: [
                ...navigationWidgets,
                const SizedBox(width: 12),
                Expanded(child: actionFilterBar),
              ],
            );
          },
        ),
      ),
    );
  }

  String _currentScaleLabel() {
    final match = scaleOptions.firstWhere(
      (o) => o.$1 == currentScale,
      orElse: () => scaleOptions.first,
    );
    return match.$3;
  }

  Widget _buildTimeScaleSelector() {
    return ToggleButtons(
      isSelected: scaleOptions.map((o) => o.$1 == currentScale).toList(),
      borderRadius: BorderRadius.circular(6),
      constraints: const BoxConstraints(minWidth: 42, minHeight: 32),
      onPressed: (index) => onScaleChanged(scaleOptions[index].$1),
      children: scaleOptions
          .map(
            (o) => Tooltip(
              message: o.$3,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(o.$2, style: const TextStyle(fontSize: 12)),
              ),
            ),
          )
          .toList(),
    );
  }
}
