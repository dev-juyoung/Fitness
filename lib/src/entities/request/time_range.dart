import 'package:meta/meta.dart';

class TimeRange {
  final DateTime start;
  final DateTime end;

  TimeRange({
    @required this.start,
    @required this.end,
  })  : assert(start != null, 'start is cannot be null'),
        assert(end != null, 'end is cannot be null'),
        assert(start.isBefore(end), 'start must be less than end.');

  @override
  String toString() => 'TimeRange(start: $start, end: $end)';
}
