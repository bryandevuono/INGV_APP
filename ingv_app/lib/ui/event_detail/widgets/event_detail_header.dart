import 'package:flutter/material.dart';
import 'package:ingv_app/data/models/event_model.dart';
import 'package:ingv_app/ui/event_detail/view_models/event_detail_view_model.dart';
import 'package:ingv_app/ui/shared/view_models/event_tooltip_helper.dart';

class EventDetailHeader extends StatelessWidget {
  final EventModel event;
  final EventDetailViewModel viewModel;
  final VoidCallback onDismiss;
  final VoidCallback? onEdit;

  const EventDetailHeader({
    super.key,
    required this.event,
    required this.viewModel,
    required this.onDismiss,
    this.onEdit,
  });

  static IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Volcanic':
        return Icons.casino;
      case 'Earthquake':
        return Icons.festival;
      case 'Hydrological':
        return Icons.water_drop;
      case 'Meteorological':
        return Icons.cloud;
      case 'Geological':
        return Icons.landscape;
      case 'Atmospheric':
        return Icons.air;
      default:
        return Icons.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 920;
          final overviewBlock = _OverviewPanel(viewModel: viewModel);

          final titleBlock = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: viewModel.categoryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  _getCategoryIcon(event.category),
                  color: viewModel.categoryColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        Text(
                          event.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        _Badge(
                          label: event.category,
                          background: viewModel.categoryColor.withValues(
                            alpha: 0.1,
                          ),
                          borderColor: viewModel.categoryColor.withValues(
                            alpha: 0.25,
                          ),
                          textColor: viewModel.categoryColor,
                        ),
                        _StatusBadge(viewModel: viewModel),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _MetadataChip(
                          label: 'Duration',
                          value: viewModel.eventDuration,
                        ),
                        _MetadataChip(label: 'Initiator', value: event.author),
                        _MetadataChip(
                          label: 'Team',
                          value: viewModel.groupName ?? 'N/A',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );

          final actions = Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.end,
            children: [
              TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Edit'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: viewModel.isExporting
                    ? null
                    : () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final exportPath = await viewModel
                            .exportSelectedEvent();
                        if (!context.mounted) {
                          return;
                        }

                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              exportPath?.isNotEmpty == true
                                  ? 'Event PDF exported: $exportPath'
                                  : (viewModel.errorMessage ??
                                        'Failed to export event PDF.'),
                            ),
                          ),
                        );
                      },
                icon: viewModel.isExporting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.picture_as_pdf, size: 16),
                label: const Text('PDF'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: viewModel.isExporting
                    ? null
                    : () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final exportPath = await viewModel
                            .exportSelectedEventAsZip();
                        if (!context.mounted) {
                          return;
                        }

                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              exportPath?.isNotEmpty == true
                                  ? 'Event ZIP exported: $exportPath'
                                  : (viewModel.errorMessage ??
                                        'Failed to export event ZIP.'),
                            ),
                          ),
                        );
                      },
                icon: viewModel.isExporting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.folder_zip, size: 16),
                label: const Text('ZIP'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          );

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                titleBlock,
                const SizedBox(height: 10),
                overviewBlock,
                const SizedBox(height: 10),
                Align(alignment: Alignment.centerLeft, child: actions),
              ],
            );
          }

          return Stack(
            alignment: Alignment.center,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: titleBlock),
                  const SizedBox(width: 12),
                  const Spacer(flex: 5),
                  const SizedBox(width: 12),
                  actions,
                ],
              ),
              IgnorePointer(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 620),
                    child: overviewBlock,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color background;
  final Color borderColor;
  final Color textColor;

  const _Badge({
    required this.label,
    required this.background,
    required this.borderColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final EventDetailViewModel viewModel;

  const _StatusBadge({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final color = viewModel.isEventEnded ? Colors.green : Colors.orange;
    return _Badge(
      label: viewModel.eventStatusLabel,
      background: color.withValues(alpha: 0.1),
      borderColor: color.withValues(alpha: 0.25),
      textColor: color.shade700,
    );
  }
}

class _OverviewPanel extends StatelessWidget {
  final EventDetailViewModel viewModel;

  const _OverviewPanel({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Overview',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade900,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: _OverviewPill(
                  label: 'Start',
                  value: formatDateTimeLocal(viewModel.selectedEvent?.startDt),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: _OverviewPill(
                  label: 'End',
                  value: viewModel.selectedEvent?.endDt != null
                      ? formatDateTimeLocal(viewModel.selectedEvent!.endDt!)
                      : 'Ongoing',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: _OverviewPill(
                  label: 'Duration',
                  value: viewModel.eventDuration,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: _OverviewPill(
                  label: 'Location',
                  value: viewModel.eventLocationDisplay,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: _OverviewPill(
                  label: 'Status',
                  value: viewModel.eventStatusLabel,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OverviewPill extends StatelessWidget {
  final String label;
  final String value;

  const _OverviewPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 0),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _MetadataChip extends StatelessWidget {
  final String label;
  final String value;

  const _MetadataChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
          Flexible(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
