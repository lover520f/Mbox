import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import '../utils/log_utils.dart';

/// 爬虫引擎 - 统一接口
class SpiderEngine {
  static const MethodChannel _channel = MethodChannel('com.mbox.android/main');
  
  static bool _initialized = false;
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
  
  /// 初始化 JS 爬虫
  static Future<void> initJsSpider(String path) async {
    try {
      await _channel.invokeMethod('jsSpiderInit', {'path': path});
      Log.d('JS spider initialized: $path');
    } catch (e) {
      Log.e('JS spider init error: $e');
      rethrow;
    }
  }
  
  /// 调用 JS 爬虫方法
  static Future<dynamic> invokeJsSpider(String func, String params) async {
    try {
      final result = await _channel.invokeMethod('jsSpiderInvoke', {
        'func': func,
        'params': params,
      });
      return result;
    } catch (e) {
      Log.e('JS spider invoke error: $e');
      return null;
    }
  }
  
  /// 获取首页内容
  static Future<Map<String, dynamic>> home(String content) async {
    try {
      final result = await invokeJsSpider('home', content);
      if (result is String && result.isNotEmpty) {
        return json.decode(result) as Map<String, dynamic>;
      }
      return {'class': []};
    } catch (e) {
      Log.e('Home error: $e');
      return {'class': []};
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
      final params = json.encode({
        'tid': tid,
        'page': pg,
        'filter': filter == '1' || filter == 'true',
        'extend': extend ?? '',
      });
      final result = await invokeJsSpider('category', params);
      if (result is String && result.isNotEmpty) {
        return json.decode(result) as Map<String, dynamic>;
      }
      return {'list': [], 'page': 1, 'pagecount': 1, 'limit': 20, 'total': 0};
    } catch (e) {
      Log.e('Category error: $e');
      return {'list': [], 'page': 1, 'pagecount': 1, 'limit': 20, 'total': 0};
    }
  }
  
  /// 获取详情
  static Future<Map<String, dynamic>> detail(String flag, String id) async {
    try {
      final params = json.encode({'flag': flag, 'id': id});
      final result = await invokeJsSpider('detail', params);
      if (result is String && result.isNotEmpty) {
        final data = json.decode(result) as Map<String, dynamic>;
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
      final params = json.encode({'flag': flag, 'id': id, 'vipFlags': vipFlags});
      final result = await invokeJsSpider('play', params);
      if (result is String && result.isNotEmpty) {
        return json.decode(result) as Map<String, dynamic>;
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
      final params = json.encode({'quick': quick, 'wd': wd});
      final result = await invokeJsSpider('search', params);
      if (result is String && result.isNotEmpty) {
        return json.decode(result) as Map<String, dynamic>;
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
