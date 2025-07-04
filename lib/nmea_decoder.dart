import 'dart:async';
import 'package:flutter/services.dart';

import 'nmea_models.dart';

class NmeaService {
  // 定义与原生代码通信的 MethodChannel
  static const _nmeaChannel = MethodChannel('com.hyzh.location_test/nmea');

  // 使用 StreamController 将 MethodChannel 的回调转换为 Dart Stream
  final _nmeaController = StreamController<NmeaMessage>.broadcast();

  // NMEA 解析器实例
  final NmeaDecoder _decoder = NmeaDecoder();

  NmeaService() {
    _init();
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
          print('Error processing NMEA string "$nmeaString": $e');
        }
      }
    });
  }

  /// 对外暴露的 NMEA 消息流
  Stream<NmeaMessage> getNmeaMessageStream() {
    return _nmeaController.stream;
  }

  /// 关闭流控制器，防止内存泄漏
  void dispose() {
    _nmeaController.close();
  }
}


// --- NMEA 解析器 (内部实现，不对外暴露) ---
// 这部分代码直接从你提供的代码迁移过来，并设为私有类

class NmeaDecoder {
  List<NmeaMessage> decode(String nmeaString) {
    if (nmeaString.isEmpty || !nmeaString.startsWith('\$')) {
      return [];
    }

    // ... (此处省略，直接粘贴你提供的完整 NmeaDecoder 类代码) ...
    // ... 例如：
    final parts = nmeaString.split('*');
    if (parts.length != 2) return [];

    final dataPart = parts[0];
    final rawChecksum = parts[1];

    final calculatedChecksum = _calculateChecksum(dataPart.substring(1));
    if (calculatedChecksum.toUpperCase() != rawChecksum.trim().toUpperCase()) {
      print('Checksum mismatch for: $nmeaString');
      return [];
    }

    final fields = dataPart.substring(1).split(',');
    if (fields.isEmpty) return [];

    final talkerIdAndSentenceType = fields[0];
    String talkerId = '';
    String sentenceType = '';

    if (talkerIdAndSentenceType.length >= 5) {
      talkerId = talkerIdAndSentenceType.substring(0, 2);
      sentenceType = talkerIdAndSentenceType.substring(2, 5);
    } else {
      return [];
    }

    List<NmeaMessage> decodedMessages = [];

    switch ('$talkerId$sentenceType') {
      case 'GNGSA':
      case 'GPGSA':
      case 'GLGSA':
      case 'GBGSA':
        final gsaMessage = _parseGsaMessage(fields);
        if (gsaMessage != null) decodedMessages.add(gsaMessage);
        break;
      case 'GPGGA':
      case 'GNGGA':
        final ggaMessage = _parseGgaMessage(fields);
        if (ggaMessage != null) decodedMessages.add(ggaMessage);
        break;
      case 'GPGSV':
      case 'GLGSV':
      case 'GBGSV':
        final gsvMessage = _parseGsvMessage(fields);
        if (gsvMessage != null) decodedMessages.add(gsvMessage);
        break;
      default:
      // print('Unsupported NMEA sentence: $talkerIdAndSentenceType');
        break;
    }

    return decodedMessages;
  }

  // --- 所有私有解析方法 _parseGsvMessage, _calculateChecksum, 等等 ---
  // --- 也都粘贴在这里 ---
  // ... (完整代码) ...
  String _calculateChecksum(String data) {
    int checksum = 0;
    for (int i = 0; i < data.length; i++) {
      checksum ^= data.codeUnitAt(i);
    }
    return checksum.toRadixString(16).padLeft(2, '0');
  }

  GsaMessage? _parseGsaMessage(List<String> fields) {
    if (fields.length < 18) return null;
    final talkerId = fields[0].substring(0, 2);
    final mode1 = fields[1];
    final mode2 = int.tryParse(fields[2]) ?? 0;
    List<int> prnNumbers = [];
    for (int i = 3; i <= 14; i++) {
      final prn = int.tryParse(fields[i]);
      if (prn != null) prnNumbers.add(prn);
    }
    final pdop = _parseDop(fields[15]);
    final hdop = _parseDop(fields[16]);
    final vdop = _parseDop(fields[17]);
    return GsaMessage(talkerId: talkerId, mode1: mode1, mode2: mode2, prnNumbers: prnNumbers, pdop: pdop, hdop: hdop, vdop: vdop);
  }

  GgaMessage? _parseGgaMessage(List<String> fields) {
    if (fields.length < 15) return null;
    final talkerId = fields[0].substring(0, 2);
    DateTime? timestamp;
    final timeStr = fields[1];
    if (timeStr.isNotEmpty) {
      try {
        final hour = int.parse(timeStr.substring(0, 2));
        final minute = int.parse(timeStr.substring(2, 4));
        final second = double.parse(timeStr.substring(4));
        final ms = ((second - second.truncate()) * 1000).round();
        timestamp = DateTime.utc(1970, 1, 1, hour, minute, second.truncate(), ms);
      } catch (e) {}
    }
    double? latitude = _parseLatitude(fields[2], fields[3]);
    double? longitude = _parseLongitude(fields[4], fields[5]);
    final fixQuality = int.tryParse(fields[6]);
    final numberOfSatellites = int.tryParse(fields[7]);
    final hdop = double.tryParse(fields[8]);
    final altitude = double.tryParse(fields[9]);
    final geoidSeparation = double.tryParse(fields[11]);
    return GgaMessage(talkerId: talkerId, timestamp: timestamp, latitude: latitude, longitude: longitude, fixQuality: fixQuality, numberOfSatellites: numberOfSatellites, hdop: hdop, altitude: altitude, geoidSeparation: geoidSeparation);
  }

  GsvMessage? _parseGsvMessage(List<String> fields) {
    if (fields.length < 4) return null;
    try {
      final talkerId = fields[0].substring(0, 2);
      final totalMessages = int.tryParse(fields[1]) ?? 0;
      final messageNumber = int.tryParse(fields[2]) ?? 0;
      final satellitesInView = int.tryParse(fields[3]) ?? 0;
      final satellites = <SatelliteInfo>[];
      for (int i = 4; i + 3 < fields.length; i += 4) {
        final prn = int.tryParse(fields[i]);
        final elevation = int.tryParse(fields[i + 1]);
        final azimuth = int.tryParse(fields[i + 2]);
        final snr = fields[i + 3].isEmpty ? null : int.tryParse(fields[i + 3]);
        if (prn != null && elevation != null && azimuth != null) {
          satellites.add(SatelliteInfo(prn: prn, elevation: elevation, azimuth: azimuth, snr: snr));
        }
      }
      return GsvMessage(talkerId: talkerId, totalMessages: totalMessages, messageNumber: messageNumber, satellitesInView: satellitesInView, satellites: satellites);
    } catch (e) {
      return null;
    }
  }

  double? _parseLatitude(String latStr, String nsIndicator) {
    if (latStr.isEmpty) return null;
    try {
      final double degrees = double.parse(latStr.substring(0, latStr.indexOf('.') - 2));
      final double minutes = double.parse(latStr.substring(latStr.indexOf('.') - 2));
      double latitude = degrees + (minutes / 60.0);
      if (nsIndicator == 'S') latitude *= -1;
      return latitude;
    } catch (e) {
      return null;
    }
  }

  double? _parseLongitude(String lonStr, String ewIndicator) {
    if (lonStr.isEmpty) return null;
    try {
      final double degrees = double.parse(lonStr.substring(0, lonStr.indexOf('.') - 2));
      final double minutes = double.parse(lonStr.substring(lonStr.indexOf('.') - 2));
      double longitude = degrees + (minutes / 60.0);
      if (ewIndicator == 'W') longitude *= -1;
      return longitude;
    } catch (e) {
      return null;
    }
  }

  double? _parseDop(String dopStr) {
    final value = double.tryParse(dopStr);
    return (value != null && value < 99.0) ? value : null;
  }
}