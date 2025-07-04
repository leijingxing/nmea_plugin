import 'package:flutter_test/flutter_test.dart';
import 'package:nmea_plugin/nmea_plugin.dart';
import 'package:nmea_plugin/nmea_plugin_platform_interface.dart';
import 'package:nmea_plugin/nmea_plugin_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockNmeaPluginPlatform
    with MockPlatformInterfaceMixin
    implements NmeaPluginPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final NmeaPluginPlatform initialPlatform = NmeaPluginPlatform.instance;

  test('$MethodChannelNmeaPlugin is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelNmeaPlugin>());
  });

  test('getPlatformVersion', () async {
    NmeaPlugin nmeaPlugin = NmeaPlugin();
    MockNmeaPluginPlatform fakePlatform = MockNmeaPluginPlatform();
    NmeaPluginPlatform.instance = fakePlatform;

  });
}
