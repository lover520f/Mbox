import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import '../utils/log_utils.dart';

/// 爬虫引擎 - 统一接口
/// 支持 TVBox 所有爬虫类型:
/// - Type 0: XML 配置中的 JS 爬虫
/// - Type 1: JSON 配置中的 JS 爬虫
/// - Type 3: JAR 爬虫 (需要 Android 原生)
/// - Type 4: JSON 配置中的 JS 爬虫
class SpiderEngine {
  static const MethodChannel _channel = MethodChannel('com.mbox.android/main');
  
  static bool _initialized = false;
  static int? _currentSpiderType;
  static Map<String, dynamic> _spiderCache = {};
  
  /// 初始化爬虫引擎
  static Future<void> init(String jarPath, String extend) async {
    try {
      await _channel.invokeMethod('init', {
        'jar': jarPath,
        'extend': extend,
      });
      _initialized = true;
      Log.d('Spider engine initialized');
    } catch (e) {
      Log.e('Spider init error: $e');
      rethrow;
    }
  }
  
  /// 初始化 Spider (根据 type 选择 JAR 或 JS)
  static Future<void> initSpider({
    required int type,
    required String path,
    String? extend,
  }) async {
    try {
      _currentSpiderType = type;
      Log.d('Init spider: type=$type, path=$path');
      
      await _channel.invokeMethod('initSpider', {
        'type': type,
        'path': path,
        'extend': extend ?? '',
      });
      
      Log.d('Spider initialized: type=$type');
    } catch (e) {
      Log.e('Spider init error: $e');
      rethrow;
    }
  }
  
  /// 是否为 JAR 爬虫
  static bool get isJarSpider => _currentSpiderType == 3;
  
  /// 是否为 JS 爬虫
  static bool get isJsSpider => _currentSpiderType == 0 || _currentSpiderType == 1 || _currentSpiderType == 4;
  
  /// 获取首页内容
  static Future<Map<String, dynamic>> home(bool filter) async {
    try {
      final result = await _channel.invokeMethod('spiderHome', {
        'filter': filter,
      });
      
      if (result is String && result.isNotEmpty) {
        return json.decode(result) as Map<String, dynamic>;
      } else if (result is Map) {
        return result as Map<String, dynamic>;
      }
      return {'class': [], 'filters': {}};
    } catch (e) {
      Log.e('Home error: $e');
      return {'class': [], 'filters': {}};
    }
  }
  
  /// 获取分类内容
  static Future<Map<String, dynamic>> category({
    required String tid,
    required String pg,
    required String filter,
    String? extend,
  }) async {
    try {
      final result = await _channel.invokeMethod('spiderCategory', {
        'tid': tid,
        'pg': pg,
        'filter': filter == '1' || filter == 'true',
        'extend': extend ?? '',
      });
      
      if (result is String && result.isNotEmpty) {
        return json.decode(result) as Map<String, dynamic>;
      } else if (result is Map) {
        return result as Map<String, dynamic>;
      }
      return {'list': [], 'page': 1, 'pagecount': 1, 'limit': 20, 'total': 0};
    } catch (e) {
      Log.e('Category error: $e');
      return {'list': [], 'page': 1, 'pagecount': 1, 'limit': 20, 'total': 0};
    }
  }
  
  /// 获取详情
  static Future<Map<String, dynamic>> detail(String id) async {
    try {
      final result = await _channel.invokeMethod('spiderDetail', {
        'id': id,
      });
      
      if (result is String && result.isNotEmpty) {
        final data = json.decode(result) as Map<String, dynamic>;
        if (data['list'] is List && (data['list'] as List).isNotEmpty) {
          return data;
        }
      } else if (result is Map) {
        final data = result as Map<String, dynamic>;
        if (data['list'] is List && (data['list'] as List).isNotEmpty) {
          return data;
        }
      }
      return {'list': []};
    } catch (e) {
      Log.e('Detail error: $e');
      return {'list': []};
    }
  }
  
  /// 获取播放地址
  static Future<Map<String, dynamic>> play(String flag, String id, String vipFlags) async {
    try {
      final result = await _channel.invokeMethod('spiderPlay', {
        'flag': flag,
        'id': id,
        'vipFlags': vipFlags,
      });
      
      if (result is String && result.isNotEmpty) {
        return json.decode(result) as Map<String, dynamic>;
      } else if (result is Map) {
        return result as Map<String, dynamic>;
      }
      return {'parse': 0, 'url': ''};
    } catch (e) {
      Log.e('Play error: $e');
      return {'parse': 0, 'url': ''};
    }
  }
  
  /// 搜索
  static Future<Map<String, dynamic>> search(bool quick, String wd) async {
    try {
      final result = await _channel.invokeMethod('spiderSearch', {
        'quick': quick,
        'wd': wd,
      });
      
      if (result is String && result.isNotEmpty) {
        return json.decode(result) as Map<String, dynamic>;
      } else if (result is Map) {
        return result as Map<String, dynamic>;
      }
      return {'list': []};
    } catch (e) {
      Log.e('Search error: $e');
      return {'list': []};
    }
  }
  
  /// 销毁爬虫引擎
  static Future<void> destroy() async {
    try {
      await _channel.invokeMethod('spiderDestroy');
      _initialized = false;
      _currentSpiderType = null;
      _spiderCache.clear();
      Log.d('Spider engine destroyed');
    } catch (e) {
      Log.e('Spider destroy error: $e');
    }
  }
  
  /// 保持屏幕常亮
  static Future<void> keepScreenOn(bool on) async {
    try {
      await _channel.invokeMethod('keepScreenOn', {'keepOn': on});
    } catch (e) {
      Log.e('Keep screen on error: $e');
    }
  }
}
