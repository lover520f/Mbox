import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

/// 设备工具类
class DeviceUtils {
  static bool? _isTV;
  
  /// 检查是否为 TV 设备
  static Future<bool> isTV() async {
    if (_isTV != null) return _isTV!;
    
    try {
      if (Platform.isAndroid) {
        final deviceInfo = DeviceInfoPlugin();
        final androidInfo = await deviceInfo.androidInfo;
        
        // 检测设备类型
        final isTvFeature = androidInfo.systemFeatures?.contains('android.software.leanback');
        final isAmazonFireTV = androidInfo.brand?.toLowerCase().contains('amazon') ?? false;
        
        // 检测是否有触摸屏（TV 通常没有）
        final hasTouchScreen = androidInfo.systemFeatures?.contains('android.hardware.touchscreen');
        
        _isTV = isTvFeature == true || 
                isAmazonFireTV || 
                hasTouchScreen == false;
        
        return _isTV!;
      } else if (Platform.isIOS) {
        // iOS TV 检测
        final deviceInfo = DeviceInfoPlugin();
        final iosInfo = await deviceInfo.iosInfo;
        
        // Apple TV 的标识符
        _isTV = iosInfo.model.contains('AppleTV');
        return _isTV!;
      }
      
      _isTV = false;
      return _isTV!;
    } catch (e) {
      _isTV = false;
      return _isTV!;
    }
  }

  /// 获取设备型号
  static Future<String> getModel() async {
    if (Platform.isAndroid) {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      return '${androidInfo.brand} ${androidInfo.model}';
    } else if (Platform.isIOS) {
      final deviceInfo = DeviceInfoPlugin();
      final iosInfo = await deviceInfo.iosInfo;
      return iosInfo.model;
    }
    return 'Unknown';
  }

  /// 获取 Android 版本
  static Future<int> getAndroidVersion() async {
    if (Platform.isAndroid) {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.version.sdkInt;
    }
    return 0;
  }

  /// 检查是否支持 Leanback
  static Future<bool> supportsLeanback() async {
    if (Platform.isAndroid) {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.systemFeatures?.contains('android.software.leanback') == true;
    }
    return false;
  }
}
