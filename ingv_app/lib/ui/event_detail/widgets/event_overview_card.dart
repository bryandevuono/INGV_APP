import 'package:flutter/material.dart';
import 'package:ingv_app/ui/event_detail/view_models/event_detail_view_model.dart';
import 'package:ingv_app/ui/shared/view_models/event_tooltip_helper.dart';

class EventOverviewCard extends StatelessWidget {
  final EventDetailViewModel viewModel;

  const EventOverviewCard({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Overview',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade900,
            ),
          ),
          const SizedBox(height: 12),
          if (viewModel.selectedEvent != null) ...[
            _OverviewRow(
              label: 'Start',
              value: formatDateTimeLocal(viewModel.selectedEvent!.startDt),
            ),
            const SizedBox(height: 8),
            _OverviewRow(
              label: 'End',
              value: viewModel.selectedEvent!.endDt != null
                  ? formatDateTimeLocal(viewModel.selectedEvent!.endDt!)
                  : 'Ongoing',
            ),
            const SizedBox(height: 8),
            _OverviewRow(label: 'Duration', value: viewModel.eventDuration),
            const SizedBox(height: 8),
            _OverviewRow(
              label: 'Location',
              value: viewModel.eventLocationDisplay,
            ),
            const SizedBox(height: 8),
            _OverviewRow(label: 'Status', value: viewModel.eventStatusLabel),
          ],
        ],
      ),
    );
  }
}

class _OverviewRow extends StatelessWidget {
  final String label;
  final String value;

  const _OverviewRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 11, color: Colors.black87),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
