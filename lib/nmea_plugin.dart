import 'dart:async';
import 'package:flutter/services.dart';
import 'package:nmea_plugin/nmea_models.dart'; // 导入模型文件

import 'nmea_decoder.dart';

export 'package:nmea_plugin/nmea_models.dart'; // 将模型导出，方便使用者引用

/// NmeaPlugin provides a stream of parsed NMEA messages from the device's location services.
class NmeaPlugin {
  // 定义与原生代码通信的 MethodChannel
  static const _nmeaChannel = MethodChannel('com.hyzh.location_test/nmea');

  // 单例模式，确保只有一个实例和 StreamController
  static final NmeaPlugin _instance = NmeaPlugin._internal();
  factory NmeaPlugin() => _instance;

  NmeaPlugin._internal() {
    _init();
  }

  // 使用 StreamController 将 MethodChannel 的回调转换为 Dart Stream
  final _nmeaController = StreamController<NmeaMessage>.broadcast();

  // NMEA 解析器实例
  final NmeaDecoder _decoder = NmeaDecoder();

  /// 对外暴露的 NMEA 消息流
  ///
  /// Usage:
  /// ```dart
  /// _subscription = NmeaPlugin().getNmeaMessageStream().listen((message) {
  ///   // process message
  /// });
  /// ```
  Stream<NmeaMessage> getNmeaMessageStream() {
    return _nmeaController.stream;
  }

  /// 初始化 MethodChannel 监听
  void _init() {
    _nmeaChannel.setMethodCallHandler((call) async {
      if (call.method == 'onNmeaMessage') {
        final String? nmeaString = call.arguments as String?;
        if (nmeaString == null || nmeaString.isEmpty) return;

        try {
          final List<NmeaMessage> messages = _decoder.decode(nmeaString);
          for (final message in messages) {
            _nmeaController.add(message); // 将解析出的消息添加到流中
          }
        } catch (e) {
          // 在生产环境中，你可能希望使用更成熟的日志记录
          print('Error processing NMEA string "$nmeaString": $e');
        }
      }
      // 你还可以在这里处理 'onPermissionDenied' 等回调
    });
  }

  /// 应该在不再需要流时调用，但这对于单例来说很少见。
  /// 对于应用级的服务，通常不需要手动 dispose。
  void dispose() {
    _nmeaController.close();
  }
}