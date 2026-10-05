const _kMonths = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// Short "Mon D" date label shared by every trend summary sentence
/// (e.g. "high of 150 bpm on Sep 5").
String formatTrendShortDate(DateTime date) {
  final local = date.toLocal();
  return '${_kMonths[local.month - 1]} ${local.day}';
}

/// "Mon D, YYYY" date label used for the chart card's date-range subtitle
/// (e.g. "Sep 3, 2026").
String formatTrendLongDate(DateTime date) {
  final local = date.toLocal();
  return '${_kMonths[local.month - 1]} ${local.day}, ${local.year}';
}
