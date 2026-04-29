import 'dart:convert';
import '../models/vod_config.dart';
import '../utils/log_utils.dart';
import 'spider_engine.dart';

/// 爬虫管理器
/// 管理多个站点的爬虫实例，根据 site 的 type 自动选择合适的爬虫引擎
class SpiderManager {
  static final SpiderManager _instance = SpiderManager._internal();
  factory SpiderManager() => _instance;
  SpiderManager._internal();
  
  /// 当前激活的站点 key
  String? _currentSiteKey;
  
  /// 当前爬虫类型
  int? _currentSpiderType;
  
  /// 当前爬虫路径 (jar 文件路径或 JS 脚本路径)
  String? _currentSpiderPath;
  
  /// 当前扩展参数
  String? _currentExtend;
  
  bool _initialized = false;
  
  /// 初始化引擎
  Future<void> init() async {
    if (_initialized) return;
    await SpiderEngine.init('', '');
    _initialized = true;
    Log.d('Spider manager initialized');
  }
  
  /// 加载站点爬虫
  /// 根据 site 的 type 初始化对应的爬虫
  /// - Type 0: XML 配置中的 JS 爬虫
  /// - Type 1: JSON 配置中的 JS 爬虫
  /// - Type 3: JAR 爬虫
  /// - Type 4: JSON 配置中的 JS 爬虫
  Future<void> loadSite(Site site) async {
    try {
      Log.d('Loading spider for site: ${site.name} (type=${site.type})');
      
      _currentSiteKey = site.key;
      _currentSpiderType = site.type;
      _currentSpiderPath = site.ext ?? '';
      _currentExtend = site.ext ?? '';
      
      // 如果当前爬虫已加载且相同，跳过
      // TODO: 支持爬虫缓存
      
      await SpiderEngine.initSpider(
        type: site.type,
        path: site.ext ?? '',
        extend: site.ext,
      );
      
      Log.d('Spider loaded: key=${site.key}, type=${site.type}');
    } catch (e) {
      Log.e('Load spider error: $e');
      rethrow;
    }
  }
  
  /// 获取当前站点 key
  String? get currentSiteKey => _currentSiteKey;
  
  /// 获取当前爬虫类型
  int? get currentSpiderType => _currentSpiderType;
  
  /// 是否为 JAR 爬虫
  bool get isJarSpider => _currentSpiderType == 3;
  
  /// 是否为 JS 爬虫
  bool get isJsSpider => 
      _currentSpiderType == 0 || 
      _currentSpiderType == 1 || 
      _currentSpiderType == 4;
  
  /// 获取首页内容
  Future<Map<String, dynamic>> home({bool filter = false}) async {
    return await SpiderEngine.home(filter);
  }
  
  /// 获取分类内容
  Future<Map<String, dynamic>> category({
    required String tid,
    required String pg,
    required String filter,
    String? extend,
  }) async {
    return await SpiderEngine.category(
      tid: tid,
      pg: pg,
      filter: filter,
      extend: extend,
    );
  }
  
  /// 获取详情
  Future<Map<String, dynamic>> detail(String id) async {
    return await SpiderEngine.detail(id);
  }
  
  /// 获取播放地址
  Future<Map<String, dynamic>> play(
    String flag,
    String id,
    String vipFlags,
  ) async {
    return await SpiderEngine.play(flag, id, vipFlags);
  }
  
  /// 搜索
  Future<Map<String, dynamic>> search({
    required String key,
    bool quick = false,
  }) async {
    return await SpiderEngine.search(quick, key);
  }
  
  /// 销毁当前爬虫
  Future<void> destroy() async {
    try {
      await SpiderEngine.destroy();
      _currentSiteKey = null;
      _currentSpiderType = null;
      _currentSpiderPath = null;
      _currentExtend = null;
      Log.d('Spider manager destroyed');
    } catch (e) {
      Log.e('Destroy error: $e');
    }
  }
  
  /// 销毁引擎
  Future<void> destroyEngine() async {
    await destroy();
    _initialized = false;
  }
}
