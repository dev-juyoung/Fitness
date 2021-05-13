class TimeRange {
  final DateTime start;
  final DateTime end;

  TimeRange({
    required this.start,
    required this.end,
  })  : assert(start.isBefore(end), 'start must be less than end.');

  @override
  String toString() => 'TimeRange(start: $start, end: $end)';
}
