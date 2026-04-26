import 'dart:convert';
import 'dart:io';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import '../models/vod_config.dart';
import '../network/okhttp_client.dart';
import '../utils/log_utils.dart';

/// 应用配置管理类
class AppConfig {
  staticlate String boxName = 'app_config';
  staticlate late Box _box;
  staticlate String? _configPath;
  staticlate VodConfig? _currentConfig;
  
  // HTTP 服务器相关
  staticlate int _serverPort = 9978;
  staticlate Server? _httpServer;

  /// 初始化配置
  static Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox(boxName);
    
    // 获取应用目录
    final appDir = await getApplicationDocumentsDirectory();
    _configPath = '${appDir.path}/config';
    
    // 创建配置目录
    await Directory(_configPath!).create(recursive: true);
    
    Log.d('AppConfig initialized, path: $_configPath');
  }

  /// 加载配置
  static Future<VodConfig?> loadConfig(String source, {String? name}) async {
    try {
      String configStr;
      
      // 判断是 URL 还是本地路径
      if (source.startsWith('http://') || source.startsWith('https://')) {
        configStr = await OkHttpUtils.get(source);
      } else if (source.endsWith('.json')) {
        configStr = await File(source).readAsString();
      } else {
        // 直接是 JSON 字符串
        configStr = source;
      }
      
      // 解析配置
      final jsonMap = json.decode(configStr) as Map<String, dynamic>;
      _currentConfig = VodConfig.fromJson(jsonMap);
      
      // 保存到本地
      if (name != null) {
        await saveConfig(name, configStr);
      }
      
      // 保存到 Hive
      await _box.put('current_config', jsonMap);
      await _box.put('config_name', name ?? 'Unnamed');
      
      Log.d('Config loaded: ${_currentConfig?.sites.length} sites, ${_currentConfig?.lives.length} lives');
      
      return _currentConfig;
    } catch (e) {
      Log.e('Failed to load config: $e');
      return null;
    }
  }

  /// 保存配置到本地
  static Future<void> saveConfig(String name, String content) async {
    final file = File('$_configPath/$name.json');
    await file.writeAsString(content);
    Log.d('Config saved: $name');
  }

  /// 获取当前配置
  static VodConfig? get currentConfig => _currentConfig;

  /// 获取配置名称
  static String? get configName => _box.get('config_name') as String?;

  /// 启动 HTTP 服务器
  static Future<void> startHttpServer() async {
    if (_httpServer != null) return;

    final handler = Pipeline()
        .addMiddleware(logRequests())
        .addHandler(_handleRequest);

    // 从 9978 到 9998 寻找可用端口
    for (int port = 9978; port <= 9998; port++) {
      try {
        _httpServer = await shelf_io.serve(handler, InternetAddress.anyIPv4, port);
        _serverPort = port;
        Log.d('HTTP server started on port $port');
        break;
      } catch (e) {
        Log.d('Port $port is busy, trying next...');
      }
    }

    if (_httpServer == null) {
      Log.e('Failed to start HTTP server, no available port');
    }
  }

  /// HTTP 请求处理
  static Response _handleRequest(Request request) {
    final path = request.url.path;
    final params = request.url.queryParameters;

    Log.d('HTTP Request: ${request.method} $path, params: $params');

    // TODO: 实现各个端点的处理逻辑
    // 参考 LOCAL.md 中的 API 规范

    return Response.ok('OK');
  }

  /// 获取 HTTP 服务器端口
  static int get serverPort => _serverPort;

  /// 获取 HTTP 服务器地址
  static String get serverAddress => 'http://${OkHttpUtils.localIp}:$_serverPort';

  /// 停止 HTTP 服务器
  static Future<void> stopHttpServer() async {
    await _httpServer?.close();
    _httpServer = null;
    Log.d('HTTP server stopped');
  }
}
