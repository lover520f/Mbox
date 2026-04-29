import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/log_utils.dart';

/// 爬虫结果包装类
/// 参考 FongMi/TV 的 Result 结构
class SpiderResult {
  /// 首页分类
  static Map<String, dynamic> home({
    required List<Map<String, dynamic>> classes,
    Map<String, List<Map<String, dynamic>>>? filters,
  }) {
    return {
      'class': classes,
      if (filters != null) 'filters': filters,
    };
  }

  /// 首页推荐/分类内容/搜索
  static Map<String, dynamic> videoList({
    required List<Map<String, dynamic>> list,
    int? page,
    int? pageCount,
    int? limit,
    int? total,
  }) {
    return {
      'list': list,
      if (page != null) 'page': page,
      if (pageCount != null) 'pagecount': pageCount,
      if (limit != null) 'limit': limit,
      if (total != null) 'total': total,
    };
  }

  /// 详情
  static Map<String, dynamic> detail({
    required List<Map<String, dynamic>> list,
  }) {
    return {
      'list': list,
    };
  }

  /// 播放
  static Map<String, dynamic> play({
    required String url,
    int parse = 0,
    String? header,
    String? flag,
    String? parseUrl,
  }) {
    return {
      'url': url,
      'parse': parse,
      if (header != null) 'header': header,
      if (flag != null) 'flag': flag,
      if (parseUrl != null) 'parseUrl': parseUrl,
    };
  }

  /// 转换为 JSON 字符串
  static String toJson(Map<String, dynamic> data) {
    return json.encode(data);
  }
}

/// HTTP 爬虫基类
/// 用于 Type 0 (XML) 和 Type 1/4 (JSON)
abstract class HttpSpider {
  final String siteKey;
  final String api;
  final String? ext;
  final Map<String, String> headers;

  HttpSpider({
    required this.siteKey,
    required this.api,
    this.ext,
    this.headers = const {},
  });

  /// GET 请求
  Future<String> fetch(String url, {Map<String, String>? headers}) async {
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {...this.headers, ...?headers},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return response.body;
      } else {
        Log.e('HTTP error: ${response.statusCode} $url');
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      Log.e('Fetch error: $e');
      rethrow;
    }
  }

  /// 首页内容
  Future<Map<String, dynamic>> homeContent(bool filter);

  /// 分类内容
  Future<Map<String, dynamic>> categoryContent({
    required String tid,
    required String pg,
    required bool filter,
    Map<String, String>? extend,
  });

  /// 详情
  Future<Map<String, dynamic>> detailContent(String id);

  /// 搜索
  Future<Map<String, dynamic>> searchContent({
    required String wd,
    bool quick = false,
  });

  /// 播放
  Future<Map<String, dynamic>> playerContent({
    required String flag,
    required String id,
    required List<String> vipFlags,
  });
}

/// XML 爬虫 (Type 0)
class XmlSpider extends HttpSpider {
  XmlSpider({
    required super.siteKey,
    required super.api,
    super.ext,
    super.headers,
  });

  @override
  Future<Map<String, dynamic>> homeContent(bool filter) async {
    try {
      final url = '$api?ac=videolist';
      final xml = await fetch(url);
      return parseXmlResponse(xml);
    } catch (e) {
      Log.e('XML home error: $e');
      return SpiderResult.videoList(list: []);
    }
  }

  @override
  Future<Map<String, dynamic>> categoryContent({
    required String tid,
    required String pg,
    required bool filter,
    Map<String, String>? extend,
  }) async {
    try {
      final url = '$api?ac=videolist&t=$tid&pg=$pg';
      final xml = await fetch(url);
      return parseXmlResponse(xml);
    } catch (e) {
      Log.e('XML category error: $e');
      return SpiderResult.videoList(list: []);
    }
  }

  @override
  Future<Map<String, dynamic>> detailContent(String id) async {
    try {
      final url = '$api?ac=detail&ids=$id';
      final xml = await fetch(url);
      return parseXmlResponse(xml);
    } catch (e) {
      Log.e('XML detail error: $e');
      return SpiderResult.detail(list: []);
    }
  }

  @override
  Future<Map<String, dynamic>> searchContent({
    required String wd,
    bool quick = false,
  }) async {
    try {
      final url = '$api?ac=detail&wd=$wd';
      final xml = await fetch(url);
      return parseXmlResponse(xml);
    } catch (e) {
      Log.e('XML search error: $e');
      return SpiderResult.videoList(list: []);
    }
  }

  @override
  Future<Map<String, dynamic>> playerContent({
    required String flag,
    required String id,
    required List<String> vipFlags,
  }) async {
    // XML 类型直接返回 URL
    return SpiderResult.play(url: id, parse: 0);
  }

  /// 解析 XML 响应
  Map<String, dynamic> parseXmlResponse(String xml) {
    // TODO: 实现 XML 解析
    // 这里简化实现，返回空列表
    return SpiderResult.videoList(list: []);
  }
}

/// JSON 爬虫 (Type 1/4)
class JsonSpider extends HttpSpider {
  final bool useBase64Ext;

  JsonSpider({
    required super.siteKey,
    required super.api,
    super.ext,
    super.headers,
    this.useBase64Ext = false,
  });

  @override
  Future<Map<String, dynamic>> homeContent(bool filter) async {
    try {
      String url = api;
      if (useBase64Ext && ext != null) {
        url += (url.contains('?') ? '&' : '?') + 'f=$ext';
      }
      
      final jsonStr = await fetch(url);
      return json.decode(jsonStr) as Map<String, dynamic>;
    } catch (e) {
      Log.e('JSON home error: $e');
      return SpiderResult.videoList(list: []);
    }
  }

  @override
  Future<Map<String, dynamic>> categoryContent({
    required String tid,
    required String pg,
    required bool filter,
    Map<String, String>? extend,
  }) async {
    try {
      String url = '$api?ac=videolist&t=$tid&pg=$pg';
      
      if (filter && extend != null && extend.isNotEmpty) {
        // 添加筛选参数
        final extendStr = json.encode(extend);
        if (useBase64Ext) {
          // Base64 编码
          final base64Ext = base64Encode(utf8.encode(extendStr));
          url += '&f=$base64Ext';
        } else {
          url += '&f=$extendStr';
        }
      }
      
      final jsonStr = await fetch(url);
      return json.decode(jsonStr) as Map<String, dynamic>;
    } catch (e) {
      Log.e('JSON category error: $e');
      return SpiderResult.videoList(list: []);
    }
  }

  @override
  Future<Map<String, dynamic>> detailContent(String id) async {
    try {
      final url = '$api?ac=detail&ids=$id';
      final jsonStr = await fetch(url);
      return json.decode(jsonStr) as Map<String, dynamic>;
    } catch (e) {
      Log.e('JSON detail error: $e');
      return SpiderResult.detail(list: []);
    }
  }

  @override
  Future<Map<String, dynamic>> searchContent({
    required String wd,
    bool quick = false,
  }) async {
    try {
      final url = '$api?ac=detail&wd=$wd';
      final jsonStr = await fetch(url);
      return json.decode(jsonStr) as Map<String, dynamic>;
    } catch (e) {
      Log.e('JSON search error: $e');
      return SpiderResult.videoList(list: []);
    }
  }

  @override
  Future<Map<String, dynamic>> playerContent({
    required String flag,
    required String id,
    required List<String> vipFlags,
  }) async {
    // JSON 类型直接返回 URL
    return SpiderResult.play(url: id, parse: 0);
  }
}
