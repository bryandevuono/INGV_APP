/// Shared helper functions
library;

String formatDuration(DateTime start, DateTime? end) {
  if (end == null) return 'Ongoing';

  final diff = end.difference(start);
  final hours = diff.inHours;
  final minutes = diff.inMinutes.remainder(60);

  if (hours == 0 && minutes == 0) return '0m';
  if (hours == 0) return '${minutes}m';
  if (minutes == 0) return '${hours}h';
  return '${hours}h ${minutes}m';
}

String formatLocation(double lat, double lng) {
  return 'Location: ${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}';
}

String formatDateShort(DateTime? dt) {
  if (dt == null) return '—';
  return dt.toLocal().toString().split(' ')[0];
}

String formatDateTimeLocal(DateTime? dt) {
  if (dt == null) return '—';
  final s = dt.toLocal().toString().split(' ');
  if (s.length >= 2) return '${s[0]} ${s[1]}';
  return s[0];
}

String formatDateTimeTooltip(DateTime? dt) {
  if (dt == null) return '—';
  final local = dt.toLocal();
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  final day = local.day.toString();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '${months[local.month - 1]} $day, $hour:$minute';
}
