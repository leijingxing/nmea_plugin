import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'nmea_plugin_method_channel.dart';

abstract class NmeaPluginPlatform extends PlatformInterface {
  /// Constructs a NmeaPluginPlatform.
  NmeaPluginPlatform() : super(token: _token);

  static final Object _token = Object();

  static NmeaPluginPlatform _instance = MethodChannelNmeaPlugin();

  /// The default instance of [NmeaPluginPlatform] to use.
  ///
  /// Defaults to [MethodChannelNmeaPlugin].
  static NmeaPluginPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [NmeaPluginPlatform] when
  /// they register themselves.
  static set instance(NmeaPluginPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
