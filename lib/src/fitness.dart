import 'dart:async';

import 'package:flutter/services.dart';

import 'types/types.dart';
import 'entities/entities.dart';
import 'extensions/extensions.dart';

class Fitness {
  const Fitness._();

  static const MethodChannel _channel = const MethodChannel(
    'plugins.juyoung.dev/fitness',
  );

  static Future<bool> hasPermission() async {
    return await _channel.invokeMethod('hasPermission') ?? false;
  }

  static Future<bool> requestPermission() async {
    return await _channel.invokeMethod('requestPermission') ?? false;
  }

  static Future<bool> revokePermission() async {
    return await _channel.invokeMethod('revokePermission') ?? false;
  }

  static Future<List<DataPoint>> read({
    TimeRange? timeRange,
    int bucketByTime = 1,
    TimeUnit timeUnit = TimeUnit.days,
  }) async {
    return _channel.invokeListMethod('read', {
      'date_from': timeRange != null
          ? timeRange.start.millisecondsSinceEpoch
          : DateTime.now().min,
      'date_to': timeRange != null
          ? timeRange.end.millisecondsSinceEpoch
          : DateTime.now().max,
      'bucket_by_time': bucketByTime,
      'time_unit': timeUnit.value,
    }).then(
      (response) => response!
          .map((data) => DataPoint.fromJson(Map<String, dynamic>.from(data)))
          .toList(),
    );
  }
}
