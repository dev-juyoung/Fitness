extension DateTimeExtensions on DateTime {
  int get min {
    return DateTime(year, month, day, 0, 0, 0, 0, 0).millisecondsSinceEpoch;
  }

  int get max {
    return DateTime(year, month, day, 23, 59, 59, 999, 999)
        .millisecondsSinceEpoch;
  }
}
