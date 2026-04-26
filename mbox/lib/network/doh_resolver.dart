import 'dart:convert';
import 'package:dio/dio.dart';
import '../models/vod_config.dart';
import '../utils/log_utils.dart';

/// DNS over HTTPS 解析器
class DoHResolver {
  static late Dio? _dio;
  static late List<Doh> _servers = [];
  static late Map<String, String> _cache = {};
  static const int _cacheTTL = 300;
  static late Map<String, int> _cacheTime = {};

  /// 初始化
  static Future<void> init(List<Doh> servers) async {
    _servers = servers;
    
    _dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'accept': 'application/dns-json',
      },
    ));
    
    Log.d('DoH initialized with ${servers.length} servers');
  }

  /// 解析域名
  static Future<List<String>> resolve(String hostname) async {
    // 检查缓存
    final cacheKey = hostname.toLowerCase();
    if (_cache.containsKey(cacheKey)) {
      final cacheAge = DateTime.now().millisecondsSinceEpoch ~/ 1000 - 
                       (_cacheTime[cacheKey] ?? 0);
      if (cacheAge < _cacheTTL) {
        Log.d('DoH cache hit: $hostname -> ${_cache[cacheKey]}');
        return [_cache[cacheKey]!];
      } else {
        _cache.remove(cacheKey);
        _cacheTime.remove(cacheKey);
      }
    }
    
    // 依次尝试每个 DoH 服务器
    for (final server in _servers) {
      try {
        final ips = await _queryServer(server, hostname);
        if (ips.isNotEmpty) {
          // 缓存结果
          _cache[cacheKey] = ips.first;
          _cacheTime[cacheKey] = DateTime.now().millisecondsSinceEpoch ~/ 1000;
          Log.d('DoH resolved: $hostname -> ${ips.first}');
          return ips;
        }
      } catch (e) {
        Log.w('DoH server ${server.name} failed: $e');
        continue;
      }
    }
    
    Log.e('DoH failed to resolve: $hostname');
    return [];
  }

  /// 查询单个 DoH 服务器
  static Future<List<String>> _queryServer(Doh server, String hostname) async {
    try {
      // 如果有 bootstrap IPs，先尝试解析服务器本身
      if (server.ips.isNotEmpty) {
        for (final ip in server.ips) {
          // 用 IP 访问 DoH 服务器
          final url = server.url.replaceFirst(
            RegExp(r'https?://[^/]+'),
            'https://$ip',
          );
          
          final result = await _doQuery(url, hostname);
          if (result.isNotEmpty) {
            return result;
          }
        }
      }
      
      // 直接查询
      return await _doQuery(server.url, hostname);
    } catch (e) {
      Log.e('DoH query failed: $e');
      return [];
    }
  }

  /// 执行 DNS 查询
  static Future<List<String>> _doQuery(String baseUrl, String hostname) async {
    final response = await _dio!.get(
      baseUrl,
      queryParameters: {
        'name': hostname,
        'type': 'A',
      },
    );
    
    if (response.statusCode == 200) {
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final answers = data['Answer'] as List?;
        if (answers != null) {
          return answers
              .where((a) => a['type'] == 1) // A record
              .map((a) => a['data'] as String)
              .toList();
        }
      }
    }
    
    return [];
  }

  /// 清除缓存
  static void clearCache() {
    _cache.clear();
    _cacheTime.clear();
    Log.d('DoH cache cleared');
  }

  /// 获取缓存统计
  static Map<String, dynamic> getCacheStats() {
    return {
      'entries': _cache.length,
      'servers': _servers.length,
    };
  }
}
