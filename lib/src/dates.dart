final DateTime epochBase = DateTime.utc(1899, 12, 30);

double serialFromDate(int year, int month, int day) {
  final date = DateTime.utc(year, month, day);
  return date.difference(epochBase).inDays.toDouble();
}

DateTime dateFromSerial(double serial) =>
    epochBase.add(Duration(days: serial.floor()));

double serialFromDateTime(DateTime date) {
  final asUtcMidnight = DateTime.utc(date.year, date.month, date.day);
  return asUtcMidnight.difference(epochBase).inDays.toDouble();
}

double todaySerial() => serialFromDateTime(DateTime.now());

int daysInMonth(int year, int month) {
  final firstOfNext = month == 12 ? DateTime.utc(year + 1, 1, 1) : DateTime.utc(year, month + 1, 1);
  return firstOfNext.subtract(const Duration(days: 1)).day;
}

double edate(double serial, int monthOffset) {
  final base = dateFromSerial(serial);
  var year = base.year;
  var month = base.month + monthOffset;
  while (month > 12) {
    month -= 12;
    year++;
  }
  while (month < 1) {
    month += 12;
    year--;
  }
  final day = base.day < daysInMonth(year, month) ? base.day : daysInMonth(year, month);
  return serialFromDate(year, month, day);
}

int datedif(double startSerial, double endSerial, String unit) {
  final start = dateFromSerial(startSerial);
  final end = dateFromSerial(endSerial);
  switch (unit.toUpperCase()) {
    case 'D':
      return endSerial.floor() - startSerial.floor();
    case 'M':
      return _fullMonths(start, end);
    case 'Y':
      return _fullMonths(start, end) ~/ 12;
    case 'MD':
      final anchor = DateTime.utc(end.year, end.month, start.day);
      final adjusted = anchor.isAfter(end)
          ? DateTime.utc(end.year, end.month - 1, start.day)
          : anchor;
      return end.difference(adjusted).inDays;
    case 'YM':
      return _fullMonths(start, end) % 12;
    case 'YD':
      final anchor = DateTime.utc(end.year, start.month, start.day);
      final adjusted = anchor.isAfter(end)
          ? DateTime.utc(end.year - 1, start.month, start.day)
          : anchor;
      return end.difference(adjusted).inDays;
    default:
      throw ArgumentError('Unknown DATEDIF unit: $unit');
  }
}

int _fullMonths(DateTime start, DateTime end) {
  var months = (end.year - start.year) * 12 + (end.month - start.month);
  if (end.day < start.day) months--;
  return months;
}

int weekday(double serial, {int mode = 1}) {
  final isoWeekday = dateFromSerial(serial).weekday;
  switch (mode) {
    case 1:
      return isoWeekday % 7 + 1;
    case 2:
      return isoWeekday;
    case 3:
      return isoWeekday - 1;
    default:
      return isoWeekday % 7 + 1;
  }
}
