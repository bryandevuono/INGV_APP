import 'package:flutter/material.dart';
import 'package:ingv_app/data/models/event_model.dart';
import 'package:ingv_app/ui/event_detail/view_models/event_detail_view_model.dart';

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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Volcano icon
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(Icons.terrain, color: Colors.red, size: 20),
              ),
              const SizedBox(width: 12),
              // Title
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        // Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            border: Border.all(
                              color: Colors.red.withValues(alpha: 0.3),
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${event.category} Event',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.red.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Status indicator
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: viewModel.isEventEnded
                                ? Colors.green.withValues(alpha: 0.1)
                                : Colors.orange.withValues(alpha: 0.1),
                            border: Border.all(
                              color: viewModel.isEventEnded
                                  ? Colors.green.withValues(alpha: 0.3)
                                  : Colors.orange.withValues(alpha: 0.3),
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: viewModel.isEventEnded
                                      ? Colors.green
                                      : Colors.orange,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                viewModel.eventStatusLabel,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: viewModel.isEventEnded
                                      ? Colors.green.shade700
                                      : Colors.orange.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  TextButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Edit event'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
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
                                  exportPath != null
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
                    label: const Text('Export PDF'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
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
                                  exportPath != null
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
                    label: const Text('Export ZIP'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Dismiss event panel',
                    onPressed: onDismiss,
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Metadata row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _MetadataChip(
                  label: 'Duration',
                  value: viewModel.eventDuration,
                ),
                const SizedBox(width: 16),
                _MetadataChip(label: 'Initiator', value: event.author),
                const SizedBox(width: 16),
                _MetadataChip(
                  label: 'Team',
                  value: viewModel.groupName ?? 'N/A',
                ),
              ],
            ),
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
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
