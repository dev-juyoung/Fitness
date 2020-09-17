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
    return _channel.invokeMethod('hasPermission');
  }

  static Future<bool> requestPermission() async {
    return _channel.invokeMethod('requestPermission');
  }

  static Future<bool> revokePermission() async {
    return _channel.invokeMethod('revokePermission');
  }

  static Future<List<DataPoint>> read({
    int dateFrom,
    int dateTo,
    int bucketByTime,
    TimeUnit timeUnit,
  }) async {
    return _channel.invokeListMethod(
      'read',
      {
        'date_from': dateFrom ?? DateTime.now().min,
        'date_to': dateTo ?? DateTime.now().max,
        'bucket_by_time': bucketByTime,
        'time_unit': timeUnit.value,
      },
    ).then(
      (response) => response
          .map((data) => DataPoint.fromJson(Map<String, dynamic>.from(data)))
          .toList(),
    );
  }
}
