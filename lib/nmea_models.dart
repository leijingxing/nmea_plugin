// lib/app/domain/models/nmea_message.dart

// 抽象基类
abstract class NmeaMessage {
  final String talkerId;
  final String sentenceType;
  NmeaMessage(this.talkerId, this.sentenceType);
}

// GSA 消息类
class GsaMessage extends NmeaMessage {
  final String mode1;
  final int mode2; // 1=未定位, 2=2D, 3=3D
  final List<int> prnNumbers;
  final double? pdop;
  final double? hdop;
  final double? vdop;

  GsaMessage({
    required String talkerId,
    required this.mode1,
    required this.mode2,
    required this.prnNumbers,
    this.pdop,
    this.hdop,
    this.vdop,
  }) : super(talkerId, 'GSA');

  @override
  String toString() {
    return 'GsaMessage(talkerId: $talkerId, mode1: $mode1, mode2: $mode2, hdop: $hdop, vdop: $vdop)';
  }
}

// GGA 消息类
class GgaMessage extends NmeaMessage {
  final DateTime? timestamp;
  final double? latitude;
  final double? longitude;
  final int? fixQuality;
  final int? numberOfSatellites;
  final double? hdop;
  final double? altitude; // 海拔
  final double? geoidSeparation; // 大地水准面分离

  GgaMessage({
    required String talkerId,
    this.timestamp,
    this.latitude,
    this.longitude,
    this.fixQuality,
    this.numberOfSatellites,
    this.hdop,
    this.altitude,
    this.geoidSeparation,
  }) : super(talkerId, 'GGA');

  @override
  String toString() {
    return 'GgaMessage(talkerId: $talkerId, timestamp: $timestamp, lat: $latitude, lon: $longitude, satellites: $numberOfSatellites, fixQuality: $fixQuality)';
  }
}

// 用于存储单颗卫星的信息
class SatelliteInfo {
  final int prn; // 卫星 PRN 号
  final int elevation; // 仰角 (0-90 度)
  final int azimuth; // 方位角 (0-359 度)
  final int? snr; // 信噪比 (0-99 dB)，可能为空

  SatelliteInfo({required this.prn, required this.elevation, required this.azimuth, this.snr});

  @override
  String toString() {
    return 'PRN: $prn, Elev: $elevation, Azim: $azimuth, SNR: $snr';
  }
}

// GSV 消息类
class GsvMessage extends NmeaMessage {
  final int totalMessages;
  final int messageNumber;
  final int satellitesInView;
  final List<SatelliteInfo> satellites;

  GsvMessage({
    required String talkerId,
    required this.totalMessages,
    required this.messageNumber,
    required this.satellitesInView,
    required this.satellites,
  }) : super(talkerId, 'GSV');

  @override
  String toString() {
    return 'GsvMessage(talkerId: $talkerId, msg $messageNumber/$totalMessages, satellitesInView: $satellitesInView, satellites: ${satellites.length})';
  }
}
