import 'package:fitness/fitness.dart';

extension DateTimeExtensions on DateTime {
  TimeRange daily() {
    final dateFrom = DateTime(year, month, day);
    final dateTo = DateTime(
        year,
        month,
        day,
        23,
        59,
        59,
        999,
        999);

    return TimeRange(start: dateFrom, end: dateTo);
  }

  TimeRange weekly() {
    final dateFrom = this.subtract(Duration(days: weekday));
    final dateTo = dateFrom.add(Duration(
      days: 6,
      hours: 23,
      minutes: 59,
      milliseconds: 999,
      microseconds: 999,
    ));

    return TimeRange(start: dateFrom, end: dateTo);
  }

  TimeRange monthly() {
    final dateFrom = DateTime(year, month);
    final dateTo = DateTime(
        year,
        month + 1,
        0,
        23,
        59,
        59,
        999,
        999);

    return TimeRange(start: dateFrom, end: dateTo);
  }
}
