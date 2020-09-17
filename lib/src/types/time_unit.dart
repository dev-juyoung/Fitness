enum TimeUnit {
  minutes,
  hours,
  days,
}

extension TimeUnitExtensions on TimeUnit {
  String get value => this.toString().split('.').last;
}
