import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'log_utils.dart';

/// 权限工具类
class PermissionUtils {
  /// 请求存储权限
  static Future<bool> requestStoragePermission() async {
    try {
      if (Platform.isAndroid) {
        final status = await Permission.storage.status;
        
        if (status.isGranted) {
          Log.d('Storage permission granted');
          return true;
        } else if (status.isDenied) {
          // 请求权限
          final newStatus = await Permission.storage.request();
          if (newStatus.isGranted) {
            Log.d('Storage permission granted after request');
            return true;
          } else {
            Log.w('Storage permission denied');
            return false;
          }
        } else if (status.isPermanentlyDenied) {
          // 权限被永久拒绝，需要去设置页面
          Log.w('Storage permission permanently denied');
          await openAppSettings();
          return false;
        }
      }
      return true;
    } catch (e) {
      Log.e('Request storage permission failed: $e');
      return false;
    }
  }

  /// 请求网络权限
  static Future<bool> requestNetworkPermission() async {
    try {
      if (Platform.isAndroid) {
        final status = await Permission.storage.status;
        
        if (status.isGranted) {
          return true;
        } else if (status.isDenied) {
          final newStatus = await Permission.storage.request();
          return newStatus.isGranted;
        }
      }
      return true;
    } catch (e) {
      Log.e('Request network permission failed: $e');
      return false;
    }
  }

  /// 请求媒体库权限（Android 13+）
  static Future<bool> requestMediaPermission() async {
    try {
      if (Platform.isAndroid && Platform.version.contains('level 33')) {
        final photosStatus = await Permission.photos.status;
        final videosStatus = await Permission.videos.status;
        final audioStatus = await Permission.audio.status;
        
        if (photosStatus.isGranted && videosStatus.isGranted && audioStatus.isGranted) {
          return true;
        }
        
        final photos = await Permission.photos.request();
        final videos = await Permission.videos.request();
        final audio = await Permission.audio.request();
        
        return photos.isGranted && videos.isGranted && audio.isGranted;
      }
      return true;
    } catch (e) {
      Log.e('Request media permission failed: $e');
      return false;
    }
  }

  /// 检查所有必要权限
  static Future<Map<String, bool>> checkAllPermissions() async {
    return {
      'storage': await Permission.storage.status.isGranted,
      'network': true, // INTERNET 权限是安装时授予的
    };
  }
}
