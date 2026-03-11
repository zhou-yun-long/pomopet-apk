/// Compute app logical date (YYYY-MM-DD) using a day-cutoff time.
///
/// Example: cutoff "04:00" means 03:30 belongs to previous day.
String logicalDate(DateTime now, {String cutoff = '00:00'}) {
  final parts = cutoff.split(':');
  final hh = int.tryParse(parts.isNotEmpty ? parts[0] : '0') ?? 0;
  final mm = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
  final cutoffToday = DateTime(now.year, now.month, now.day, hh, mm);

  final d = now.isBefore(cutoffToday) ? now.subtract(const Duration(days: 1)) : now;
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}
