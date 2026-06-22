/// Shared helpers for formatting event metadata in tooltips and UI.
/// Keeps Map and Timeline consistent.
library;

/// Formats a duration between [start] and [end].
///
/// Returns:
///   - `'Ongoing'` if [end] is null
///   - `'45m'` for less than 1 hour
///   - `'2h'` for exact hours
///   - `'2h 30m'` when both hours and minutes exist
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

/// Formats latitude and longitude into a `Location: lat, lng` string.
String formatLocation(double lat, double lng) {
  return 'Location: ${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}';
}

/// Formats a DateTime into a short local date string (yyyy-MM-dd).
String formatDateShort(DateTime? dt) {
  if (dt == null) return '—';
  return dt.toLocal().toString().split(' ')[0];
}

/// Formats a DateTime into a local date + time string.
String formatDateTimeLocal(DateTime? dt) {
  if (dt == null) return '—';
  final s = dt.toLocal().toString().split(' ');
  if (s.length >= 2) return '${s[0]} ${s[1]}';
  return s[0];
}

/// Formats a DateTime into a tooltip-friendly string like "May 30, 16:41".
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
