class DataPoint {
  final num value;
  final DateTime dateFrom;
  final DateTime dateTo;
  final String source;

  DataPoint(
    this.value,
    this.dateFrom,
    this.dateTo,
    this.source,
  );

  factory DataPoint.fromJson(Map<String, dynamic> json) {
    return DataPoint(
      json['value'],
      DateTime.fromMillisecondsSinceEpoch(json['date_from']),
      DateTime.fromMillisecondsSinceEpoch(json['date_to']),
      json['source'],
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'value': value,
      'date_from': dateFrom.millisecondsSinceEpoch,
      'date_to': dateTo.millisecondsSinceEpoch,
      'source': source,
    };
  }

  @override
  String toString() =>
      'DataPoint(value: $value, dateFrom: $dateFrom, dateTo: $dateTo, source: $source)';
}
