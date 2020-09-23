# Fitness

[![pub package](https://img.shields.io/pub/v/fitness)](https://pub.dartlang.org/packages/fitness)

Flutter plugin for reading step count data. Wraps HealthKit on iOS and GoogleFit on Android.

## Related Document

:point_right: [Korean](README-KR.md)

## Getting Started

Check out the example directory for a sample app.

#### Add pubspec.yaml

To use this plugin, add `fitness` as a [dependency in your pubspec.yaml file](https://flutter.io/platform-plugins/).

#### Android Integration

[Enable Fitness API](https://developers.google.com/fit/android/get-started) and obtain an OAuth 2.0 client ID.

#### iOS Integration

[Enable HealthKit](https://developer.apple.com/documentation/healthkit/setting_up_healthkit) and add NSHealthShareUsageDescription key to the Info.plist file.

## Usage

#### Fitness.hasPermission

Check if the user has previously granted the necessary data access.

> Note:
> Quite rightly so, Apple deems even the information as to whether a user accepted or denied the read permission for HealthKit as sensitive information.
> For this reason, HealthKit does not have a clear way to check permissions.
>
> As a workaround, it checks whether you can read data within the last month or not to see if you actually have read access.

```dart
void _hasPermission() async {
  final result = await Fitness.hasPermission();
}
```

#### Fitness.requestPermission

Initiate the authorization flow.

- Android: Request OAuth permission and request permission to read step count history from Google Fit. It also creates a subscription to synchronize step count data.

- iOS: Request permission to read step count history from Health Kit. Since it returns whether the request for `HKHealthStore.requestAuthorization` was successful or not, it is recommended to use `Fitness.hasPermission` in the case of iOS to check if there is permission again.


```dart
void _requestPermission() async {
  final result = await Fitness.requestPermission();
}
```

#### Fitness.revokePermission

- Android: All OAuth permissions granted to Googlt Fit are revoked and all subscriptions created in the app are removed.

- iOS: Feature is not supported, so it always returns true.

```dart
void _revokePermission() async {
  final result = await Fitness.revokePermission();
}
```

#### Fitness.read

Requests user's step data with Google Fit or Health Kit.

When requested without any arguments, the daily step count is requested by default.

##### Parameters
- timeRange
  - **defaults:** from 00:00:00 to 23:59:59
  - **type**: `TimeRange` [class]
- bucketByTime
  - **defaults:** 1
  - **type**: `int`
- timeUnit
  - **defaults:** TimeUnit.day
  - **type**: `TimeUnit` [enum]

```dart
// Request data for the last 7 days.
void _read() async {
  final now = DateTime.now();
  final results = await Fitness.read(
    timeRange: TimeRange(
      start: now.subtract(const Duration(days: 7)),
      end: now,
    ),
    bucketByTime: 1,
    timeUnit: TimeUnit.days,
  );
}
```
