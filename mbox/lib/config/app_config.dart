import 'dart:convert';
import 'dart:io';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf/shelf_io.dart';
import '../models/vod_config.dart';
import '../network/okhttp_client.dart';
import '../utils/log_utils.dart';

/// 应用配置管理类
class AppConfig {
  static late String boxName = 'app_config';
  static late Box _box;
  static late String? _configPath;
  static late VodConfig? _currentConfig;
  
  // HTTP 服务器相关
  static late int _serverPort = 9978;
  static late HttpServer? _httpServer;

  /// 初始化配置
  static Future<void> init() async {
    final directory = await getApplicationDocumentsDirectory();
    Hive.init(directory.path);
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
        Log.d('Loading config from URL: $source');
        configStr = await OkHttpUtils.get(source, headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          'Accept': 'application/json',
        });
        Log.d('Config loaded, length: ${configStr.length}');
      } else if (source.endsWith('.json')) {
        Log.d('Loading config from file: $source');
        configStr = await File(source).readAsString();
      } else {
        // 直接是 JSON 字符串
        Log.d('Parsing JSON config string');
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
    } catch (e, stackTrace) {
      Log.e('Failed to load config: $e');
      Log.e('Stack trace: $stackTrace');
      rethrow;
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
