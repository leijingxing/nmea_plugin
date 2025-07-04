# NMEA Plugin

[![pub version](https://img.shields.io/pub/v/nmea_plugin.svg)](https://pub.dev/packages/nmea_plugin)
[![license](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![platforms](https://img.shields.io/badge/platforms-android-green.svg)]()

一个 Flutter 插件，用于从 Android 设备的 GPS 硬件直接监听和解析原始的 NMEA (National Marine Electronics Association) 消息。它提供了一个简单的 Dart Stream，可以轻松获取到如 GGA, GSA, GSV 等格式的 NMEA 数据。

## 特性

- ✅ **原生性能**: 直接使用 Android 的 `OnNmeaMessageListener`，高效且低延迟。
- ✅ **自动权限处理**: 插件会自动处理 `ACCESS_FINE_LOCATION` 权限的请求。
- ✅ **易于使用**: 提供一个简单的 `Stream<NmeaMessage>`，无需关心平台通道的细节。
- ✅ **内置解析器**: 自带一个轻量级的 NMEA 解析器，可将原始字符串转换为结构化的 Dart 对象 (`GgaMessage`, `GsaMessage`, `GsvMessage` 等)。
- ✅ **类型安全**: 解析后的消息是强类型的，可以安全地访问特定属性（如 HDOP, 卫星数量等）。
- ✅ **后台安全**: 正确处理 Activity 生命周期，避免内存泄漏。

## 平台支持

| Android | iOS |
| :---: |:---:|
|   ✅   |  ❌  |

> **注意**: 此插件目前仅支持 Android 平台，因为它依赖于 Android 特有的 `LocationManager.addNmeaListener` API。iOS 平台不提供直接访问 NMEA 数据的公共 API。

## 开始使用

### 1. 添加依赖

将插件添加到你的项目的 `pubspec.yaml` 文件中:

```yaml
dependencies:
  nmea_plugin: ^1.0.0 # 替换为最新版本
```

### 2.配置 Android
插件会自动将其所需的权限添加到你的应用的 AndroidManifest.xml 中。你只需要确保你的应用已经准备好处理运行时权限。

### 3.在 Dart 中使用
使用插件非常简单。只需实例化 NmeaPlugin 并监听其提供的流即可。
```dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:nmea_plugin/nmea_plugin.dart';

class NmeaListenerScreen extends StatefulWidget {
  const NmeaListenerScreen({Key? key}) : super(key: key);

  @override
  _NmeaListenerScreenState createState() => _NmeaListenerScreenState();
}

class _NmeaListenerScreenState extends State<NmeaListenerScreen> {
  StreamSubscription<NmeaMessage>? _nmeaSubscription;
  String _latestNmeaMessage = 'Waiting for NMEA messages...';
  int _satellitesInUse = 0;
  double? _hdop;

  @override
  void initState() {
    super.initState();
    startListening();
  }

  void startListening() {
    // 防止重复监听
    _nmeaSubscription?.cancel();

    // 监听 NMEA 消息流
    _nmeaSubscription = NmeaPlugin().getNmeaMessageStream().listen(
      (NmeaMessage message) {
        // 在 UI 上显示最新的原始消息
        setState(() {
          _latestNmeaMessage = message.raw; // message 基类有 raw 属性
        });

        // 根据消息类型处理数据
        if (message is GgaMessage) {
          // GGA 句子通常包含定位质量和卫星数量
          setState(() {
            _satellitesInUse = (message.fixQuality ?? 0) > 0 
                ? message.numberOfSatellites ?? 0 
                : 0;
          });
        } else if (message is GsaMessage) {
          // GSA 句子包含精度因子 (DOP)
          setState(() {
            _hdop = message.hdop;
          });
        }
      },
      onError: (error) {
        // 处理流中可能出现的错误
        print('Error listening to NMEA stream: $error');
        setState(() {
          _latestNmeaMessage = 'Error: $error';
        });
      },
      onDone: () {
        // 当流关闭时调用
        print('NMEA stream is done.');
      },
    );
  }

  @override
  void dispose() {
    // 在 widget 销毁时取消订阅，防止内存泄漏
    _nmeaSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NMEA Plugin Example'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Satellites in use:', style: Theme.of(context).textTheme.headline6),
            Text('$_satellitesInUse', style: Theme.of(context).textTheme.headline5),
            const SizedBox(height: 16),
            Text('HDOP (Horizontal Dilution of Precision):', style: Theme.of(context).textTheme.headline6),
            Text(_hdop?.toStringAsFixed(2) ?? 'N/A', style: Theme.of(context).textTheme.headline5),
            const SizedBox(height: 24),
            Text('Latest Raw NMEA Message:', style: Theme.of(context).textTheme.caption),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8.0),
                color: Colors.grey[200],
                child: Text(_latestNmeaMessage),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```