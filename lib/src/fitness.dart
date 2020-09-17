import 'dart:async';

import 'package:flutter/services.dart';

class Fitness {
  static const MethodChannel _channel = const MethodChannel(
    'plugins.juyoung.dev/fitness',
  );

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }
}
