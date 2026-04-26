import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import '../utils/log_utils.dart';

/// Platform Channel - 调用 Android 原生功能
class NativeChannel {
  static final NativeChannel _instance = NativeChannel._internal();
  factory NativeChannel() => _instance;
  NativeChannel._internal();

  final MethodChannel _nativeChannel = const MethodChannel('com.mbox.android/native');
  final MethodChannel _spiderChannel = const MethodChannel('com.mbox.android/spider');
  final MethodChannel _dlnaChannel = const MethodChannel('com.mbox.android/dlna');
  
  final StreamController<Map<String, dynamic>> _eventController = 
      StreamController<Map<String, dynamic>>.broadcast();
  
  bool _initialized = false;

  /// 初始化
  Future<void> initialize() async {
    if (_initialized) return;
    
    // 设置方法调用处理器
    _nativeChannel.setMethodCallHandler(_handleMethodCall);
    _spiderChannel.setMethodCallHandler(_handleMethodCall);
    _dlnaChannel.setMethodCallHandler(_handleMethodCall);
    
    _initialized = true;
    Log.d('NativeChannel initialized');
  }

  /// 处理方法调用
  Future<dynamic> _handleMethodCall(MethodCall call) async {
    Log.d('Method call: ${call.method}, args: ${call.arguments}');
    
    _eventController.add({
      'channel': 'native',
      'method': call.method,
      'arguments': call.arguments,
    });
    
    switch (call.method) {
      case 'permissionsGranted':
        Log.i('Permissions granted');
        break;
      case 'permissionsDenied':
        Log.w('Permissions denied');
        break;
      case 'drmPrepared':
        Log.i('DRM prepared');
        break;
      case 'drmError':
        Log.e('DRM error: ${call.arguments}');
        break;
      case 'onPlay':
      case 'onPause':
      case 'onResume':
      case 'onStop':
      case 'onSeek':
      case 'onSpeed':
      case 'onPush':
      case 'onSetConfig':
      case 'onClearConfig':
      case 'onClearCache':
        // 播放器事件
        break;
      case 'deviceFound':
        Log.i('DLNA device found: ${call.arguments}');
        break;
    }
  }

  /// 事件流
  Stream<Map<String, dynamic>> get events => _eventController.stream;

  // ===================== 基础功能 =====================

  /// 检查权限
  Future<bool> checkPermissions() async {
    try {
      final result = await _nativeChannel.invokeMethod('checkPermissions');
      return result == true;
    } catch (e) {
      Log.e('Check permissions error: $e');
      return false;
    }
  }

  /// 请求权限
  Future<void> requestPermissions() async {
    try {
      await _nativeChannel.invokeMethod('requestPermissions');
    } catch (e) {
      Log.e('Request permissions error: $e');
    }
  }

  /// 获取设备信息
  Future<Map<String, dynamic>> getDeviceInfo() async {
    try {
      final result = await _nativeChannel.invokeMethod('getDeviceInfo');
      return Map<String, dynamic>.from(result ?? {});
    } catch (e) {
      Log.e('Get device info error: $e');
      return {};
    }
  }

  /// 获取 IP 地址
  Future<String> getIpAddress() async {
    try {
      final result = await _nativeChannel.invokeMethod('getIpAddress');
      return result as String? ?? '127.0.0.1';
    } catch (e) {
      Log.e('Get IP address error: $e');
      return '127.0.0.1';
    }
  }

  // ===================== HTTP 服务器 =====================

  /// 启动 HTTP 服务器
  Future<void> startHttpServer({int port = 9978}) async {
    try {
      await _nativeChannel.invokeMethod('startHttpServer', {'port': port});
      Log.d('HTTP server started on port $port');
    } catch (e) {
      Log.e('Start HTTP server error: $e');
      rethrow;
    }
  }

  /// 停止 HTTP 服务器
  Future<void> stopHttpServer() async {
    try {
      await _nativeChannel.invokeMethod('stopHttpServer');
      Log.d('HTTP server stopped');
    } catch (e) {
      Log.e('Stop HTTP server error: $e');
    }
  }

  // ===================== DLNA =====================

  /// 启动 DLNA
  Future<void> startDlna() async {
    try {
      await _nativeChannel.invokeMethod('startDlna');
      Log.d('DLNA started');
    } catch (e) {
      Log.e('Start DLNA error: $e');
    }
  }

  /// 停止 DLNA
  Future<void> stopDlna() async {
    try {
      await _nativeChannel.invokeMethod('stopDlna');
      Log.d('DLNA stopped');
    } catch (e) {
      Log.e('Stop DLNA error: $e');
    }
  }

  /// 搜索 DLNA 设备
  Future<List<Map<String, String>>> searchDlnaDevices() async {
    try {
      await _nativeChannel.invokeMethod('searchDlnaDevices');
      // 结果将通过 event 返回
      return [];
    } catch (e) {
      Log.e('Search DLNA devices error: $e');
      return [];
    }
  }

  /// 投屏视频
  Future<void> castVideo({
    required String deviceId,
    required String videoUrl,
    String? title,
    String? poster,
  }) async {
    try {
      await _nativeChannel.invokeMethod('castVideo', {
        'deviceId': deviceId,
        'videoUrl': videoUrl,
        'title': title ?? '',
        'poster': poster ?? '',
      });
      Log.d('Cast video to $deviceId');
    } catch (e) {
      Log.e('Cast video error: $e');
      rethrow;
    }
  }

  /// DLNA 控制
  Future<void> controlDlna({
    required String deviceId,
    required String action,
  }) async {
    try {
      await _nativeChannel.invokeMethod('control', {
        'deviceId': deviceId,
        'action': action,
      });
    } catch (e) {
      Log.e('Control DLNA error: $e');
      rethrow;
    }
  }

  // ===================== DRM =====================

  /// 加载 DRM
  Future<void> loadDrm({
    required String drmType,
    required String licenseUrl,
    Map<String, String>? headers,
  }) async {
    try {
      await _nativeChannel.invokeMethod('loadDrm', {
        'drmType': drmType,
        'licenseUrl': licenseUrl,
        'headers': headers ?? {},
      });
      Log.d('DRM loaded: $drmType');
    } catch (e) {
      Log.e('Load DRM error: $e');
      rethrow;
    }
  }

  /// 卸载 DRM
  Future<void> unloadDrm() async {
    try {
      await _nativeChannel.invokeMethod('unloadDrm');
      Log.d('DRM unloaded');
    } catch (e) {
      Log.e('Unload DRM error: $e');
    }
  }

  // ===================== Spider (JAR) =====================

  /// 加载 JAR
  Future<void> loadJar({required String key, required String jarPath}) async {
    try {
      await _spiderChannel.invokeMethod('loadJar', {
        'key': key,
        'jarPath': jarPath,
      });
      Log.d('JAR loaded: $key -> $jarPath');
    } catch (e) {
      Log.e('Load JAR error: $e');
      rethrow;
    }
  }

  /// 调用 Spider
  Future<String?> callSpider({
    required String key,
    required String method,
    String? arg,
  }) async {
    try {
      final result = await _spiderChannel.invokeMethod<String>('callSpider', {
        'key': key,
        'method': method,
        'arg': arg,
      });
      return result;
    } catch (e) {
      Log.e('Call spider error: $e');
      return null;
    }
  }

  /// 卸载 JAR
  Future<void> unloadJar({required String key}) async {
    try {
      await _spiderChannel.invokeMethod('unloadJar', {'key': key});
      Log.d('JAR unloaded: $key');
    } catch (e) {
      Log.e('Unload JAR error: $e');
    }
  }

  /// 清理资源
  Future<void> dispose() async {
    await _eventController.close();
    await stopHttpServer();
    await stopDlna();
    await unloadDrm();
    Log.d('NativeChannel disposed');
  }
}
