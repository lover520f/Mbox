import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/vod_config.dart';
import '../models/vod.dart';
import '../config/app_config.dart';
import '../utils/log_utils.dart';

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
    // TODO: 实现获取详情逻辑
    return null;
  }
}
