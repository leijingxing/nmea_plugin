import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'nmea_plugin_platform_interface.dart';

/// An implementation of [NmeaPluginPlatform] that uses method channels.
class MethodChannelNmeaPlugin extends NmeaPluginPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('nmea_plugin');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
