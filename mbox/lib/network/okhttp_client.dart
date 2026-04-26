import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../utils/log_utils.dart';

/// 网络工具类
/// 封装 HTTP 请求，支持代理、DoH、Hosts 等功能
class OkHttpUtils {
  static late Dio? _dio;
  static late String? _proxyUrl;
  static late Map<String, String> _hosts = {};
  static late String _localIp = '127.0.0.1';
  
  /// 初始化
  static Future<void> init() async {
    _dio = Dio();
    
    // 配置默认选项
    _dio!.options = BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      },
    );
    
    // 添加拦截器
    _dio!.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        // 应用代理规则
        _applyProxy(options);
        
        // 应用 Hosts 覆盖
        _applyHosts(options);
        
        // 应用自定义头
        _applyCustomHeaders(options);
        
        Log.d('Request: ${options.method} ${options.uri}');
        return handler.next(options);
      },
      onResponse: (response, handler) {
        Log.d('Response: ${response.statusCode} ${response.requestOptions.uri}');
        return handler.next(response);
      },
      onError: (error, handler) {
        Log.e('Error: ${error.message} ${error.requestOptions.uri}');
        return handler.next(error);
      },
    ));
    
    // 获取本地 IP
    _localIp = await _getLocalIp();
    
    Log.d('OkHttpUtils initialized, local IP: $_localIp');
  }

  /// 获取本地 IP 地址
  static Future<String> _getLocalIp() async {
    try {
      final interfaces = await NetworkInterface.list(
        includeLinkLocal: true,
        includeLoopback: false,
      );
      
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          if (addr.type == InternetAddressType.IPv4) {
            return addr.address;
          }
        }
      }
    } catch (e) {
      Log.e('Failed to get local IP: $e');
    }
    
    return '127.0.0.1';
  }

  /// 应用代理规则
  static void _applyProxy(RequestOptions options) {
    // TODO: 根据配置中的 proxy 规则匹配
    // 如果匹配成功，设置代理
    
    if (_proxyUrl != null) {
      // 解析代理 URL
      // 格式：scheme://username:password@host:port
      try {
        final uri = Uri.parse(_proxyUrl!);
        // TODO: 配置代理到 Dio
        Log.d('Using proxy: ${uri.host}:${uri.port}');
      } catch (e) {
        Log.e('Invalid proxy URL: $e');
      }
    }
  }

  /// 应用 Hosts 覆盖
  static void _applyHosts(RequestOptions options) {
    final host = options.uri.host;
    
    if (_hosts.containsKey(host)) {
      // 替换 hostname
      Log.d('Host override: $host -> ${_hosts[host]}');
      // 需要修改 URI
    } else {
      // 检查通配符匹配
      for (final entry in _hosts.entries) {
        if (entry.key.contains('*')) {
          // 通配符匹配逻辑
          // TODO: 实现通配符匹配
        }
      }
    }
  }

  /// 应用自定义响应头
  static void _applyCustomHeaders(RequestOptions options) {
    // TODO: 根据配置中的 headers 规则注入自定义头
  }

  /// GET 请求
  static Future<String> get(
    String url, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio!.get(
        url,
        headers: headers,
        queryParameters: queryParameters,
      );
      
      if (response.statusCode == 200) {
        return response.data is String 
            ? response.data 
            : json.encode(response.data);
      } else {
        throw Exception('HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      Log.e('GET request failed: $e');
      rethrow;
    }
  }

  /// POST 请求
  static Future<String> post(
    String url, {
    dynamic data,
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio!.post(
        url,
        data: data,
        headers: headers,
        queryParameters: queryParameters,
      );
      
      if (response.statusCode == 200) {
        return response.data is String 
            ? response.data 
            : json.encode(response.data);
      } else {
        throw Exception('HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      Log.e('POST request failed: $e');
      rethrow;
    }
  }

  /// 设置代理
  static void setProxy(String? proxyUrl) {
    _proxyUrl = proxyUrl;
    Log.d('Proxy set: ${proxyUrl ?? "null"}');
  }

  /// 设置 Hosts
  static void setHosts(Map<String, String> hosts) {
    _hosts.clear();
    _hosts.addAll(hosts);
    Log.d('Hosts set: ${hosts.length} entries');
  }

  /// 获取本地 IP
  static String get localIp => _localIp;

  /// 重置配置
  static void reset() {
    _proxyUrl = null;
    _hosts.clear();
  }
}
