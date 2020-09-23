# Fitness

[![pub package](https://img.shields.io/pub/v/fitness)](https://pub.dartlang.org/packages/fitness)

걸음 수 데이터를 읽기 위한 Flutter 플러그인. iOS에서는 HealthKit을, Android에서는 GoogleFit을 래핑 합니다.

## Related Document

:point_right: [English](README.md)

## Getting Started

자세한 사용법은 샘플 앱을 참고하세요.

#### Add pubspec.yaml

해당 플러그인을 사용하려면 `fitness`를 [dependency in your pubspec.yaml file](https://flutter.io/platform-plugins/) 문서를 참고하여 추가하세요.

#### Android Integration

[Fitness API 활성화](https://developers.google.com/fit/android/get-started) 문서를 참고하여 OAuth 2.0 Client ID를 얻습니다.

#### iOS Integration

[HealthKit 활성화](https://developer.apple.com/documentation/healthkit/setting_up_healthkit) 문서를 참고하여 HealthKit을 활성화하고 Info.plist에 NSHealthShareUsageDescription 키를 추가하여 권한 획득에 관한 설명을 설정하세요.

## Usage

#### Fitness.hasPermission

사용자가 필요한 데이터 권한을 획득했는지 확인합니다.

> Note:
> HealthKit에서는 읽기 권한 여부에 대한 정보조차도 민감한 정보로 간주합니다.
> 이러한 이유로 인해 HealthKit에서 권한을 확인하기 위한 명확한 방법이 없습니다.
>
> 해당 문제를 해결하기 위해 최근 1달 동안의 걸음 수 데이터가 있는지 확인하여 실제로 읽기 권한이 있는지 확인합니다.

```dart
void _hasPermission() async {
  final result = await Fitness.hasPermission();
}
```

#### Fitness.requestPermission

권한 획득 Flow를 실행합니다.

- Android: Google Fit에 OAuth 권한을 요청하고 걸음 수 읽기 권한을 요청합니다. 또한 걸음 수 데이터를 Google Fit과 동기화하기 위한 구독을 생성합니다.

- iOS: HealthKit에 걸음 수 읽기 권한을 요청합니다. HealthKit의 `HKHealthStore.requestAuthorization` 메서드는 단순히 해당 요청이 성공했는지에 대한 결과를 반환하므로 iOS의 경우 `Fitness.hasPermission` 메서드를 사용하여 권한이 실제로 존재하는지 다시 한번 확인하는 것이 좋습니다.

```dart
void _requestPermission() async {
  final result = await Fitness.requestPermission();
}
```

#### Fitness.revokePermission

- Android: Google Fit에 부여된 모든 OAuth 권한을 취소하고 앱에서 생성한 모든 구독을 제거합니다.

- iOS: HealthKit은 해당 기능을 지원하지 않습니다. iOS에서 요청 시 항상 `true`를 반환합니다.

```dart
void _revokePermission() async {
  final result = await Fitness.revokePermission();
}
```

#### Fitness.read

Google Fit 또는 HealthKit으로 사용자의 걸음 수 데이터를 요청합니다.

아무런 매개변수를 사용하지 않으면 기본적으로 오늘 하루 동안의 걸음 수 데이터를 요청합니다.

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
