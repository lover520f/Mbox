import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/vod_config.dart';
import '../models/vod.dart';
import '../config/app_config.dart';
import '../utils/log_utils.dart';
import '../crawler/spider_engine.dart';

/// 配置状态管理
class ConfigProvider extends ChangeNotifier {
  VodConfig? _config;
  String? _configName;
  bool _isLoading = false;
  String? _error;
  final List<Map<String, String>> _configHistory = [];

  VodConfig? get config => _config;
  String? get configName => _configName;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Map<String, String>> get configHistory => _configHistory;
  int get siteCount => _config?.sites.length ?? 0;
  int get liveCount => _config?.lives.length ?? 0;

  /// 加载配置
  Future<bool> loadConfig(String source, {String? name}) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final config = await AppConfig.loadConfig(source, name: name);
      
      if (config != null) {
        _config = config;
        _configName = AppConfig.configName;
        _isLoading = false;
        notifyListeners();
        
        Log.d('Config loaded: ${config.sites.length} sites');
        return true;
      } else {
        _error = 'Failed to load config';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error: $e';
      _isLoading = false;
      notifyListeners();
      Log.e('Failed to load config: $e');
      return false;
    }
  }

  /// 解析 JSON 配置字符串
  Future<bool> parseConfigString(String jsonString) {
    try {
      final jsonMap = json.decode(jsonString) as Map<String, dynamic>;
      _config = VodConfig.fromJson(jsonMap);
      notifyListeners();
      return Future.value(true);
    } catch (e) {
      _error = '解析失败：$e';
      notifyListeners();
      return Future.value(false);
    }
  }

  /// 清除配置
  void clearConfig() {
    _config = null;
    _configName = null;
    notifyListeners();
  }
  
  /// 加载直播配置
  Future<VodConfig?> loadLive() async {
    return _config;
  }
  
  /// 获取详情
  Future<Vod?> getDetail(String siteId, String vodId) async {
    try {
      if (_config == null) return null;
      
      Log.d('Getting detail: siteId=$siteId, vodId=$vodId');
      
      // 调用爬虫详情接口
      final result = await SpiderEngine.detail(siteId, vodId);
      
      if (result['list'] != null && result['list'] is List && (result['list'] as List).isNotEmpty) {
        final data = result['list'][0] as Map<String, dynamic>;
        final vod = Vod.fromJson(data);
        Log.d('Detail loaded: ${vod.vodName}');
        return vod;
      }
      
      return null;
    } catch (e) {
      Log.e('Get detail error: $e');
      return null;
    }
  }

  /// 获取播放地址
  Future<String?> getPlayUrl(String siteId, String episodeUrl, String flag) async {
    try {
      if (_config == null) return null;
      
      Log.d('Getting play URL: siteId=$siteId, episodeUrl=$episodeUrl, flag=$flag');
      
      // 调用爬虫播放接口
      final result = await SpiderEngine.play(siteId, episodeUrl, flag);
      
      if (result['url'] != null && result['url'] is String) {
        final url = result['url'] as String;
        Log.d('Play URL: $url');
        return url;
      }
      
      return null;
    } catch (e) {
      Log.e('Get play URL error: $e');
      return null;
    }
  }

  /// 搜索
  Future<List<Vod>> search(String siteId, String keyword, {bool quick = false}) async {
    try {
      if (_config == null) return [];
      
      Log.d('Searching: siteId=$siteId, keyword=$keyword, quick=$quick');
      
      // 调用爬虫搜索接口
      final result = await SpiderEngine.search(quick, keyword);
      
      if (result['list'] != null && result['list'] is List) {
        final list = result['list'] as List;
        final vods = list.map((item) => Vod.fromJson(item as Map<String, dynamic>)).toList();
        Log.d('Search results: ${vods.length} items');
        return vods;
      }
      
      return [];
    } catch (e) {
      Log.e('Search error: $e');
      return [];
    }
  }

  /// 获取分类内容
  Future<Map<String, dynamic>> getCategoryContent(
    String siteId,
    String typeId,
    String page, {
    String filter = '1',
    String? extend,
  }) async {
    try {
      if (_config == null) return {'list': [], 'page': 1, 'pagecount': 1, 'limit': 20, 'total': 0};
      
      Log.d('Getting category: siteId=$siteId, typeId=$typeId, page=$page');
      
      // 调用爬虫分类接口
      final result = await SpiderEngine.category(
        tid: siteId,
        pg: page,
        filter: filter,
        extend: extend,
      );
      
      Log.d('Category results: page=${result['page']}, list=${(result['list'] as List?)?.length ?? 0}');
      return result;
    } catch (e) {
      Log.e('Get category error: $e');
      return {'list': [], 'page': 1, 'pagecount': 1, 'limit': 20, 'total': 0};
    }
  }
}
