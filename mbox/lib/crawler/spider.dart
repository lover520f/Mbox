import 'dart:convert';
import '../models/vod.dart';
import '../models/vod_config.dart';
import '../network/okhttp_client.dart';
import '../utils/log_utils.dart';

/// Spider 抽象基类
/// 参考 SPIDER.md 中的规格实现
abstract class Spider {
  String siteKey = '';

  /// 初始化
  /// 在 Spider 实例创建后调用一次
  Future<void> init(dynamic context, String extend) async {
    Log.d('Spider init: extend=$extend');
  }

  /// 首页分类
  /// 用户进入首页时调用
  Future<Map<String, dynamic>> homeContent(bool filter) async {
    return {'class': [], 'filters': {}};
  }

  /// 首页推荐影片
  /// 首页分类加载完成后调用
  Future<Map<String, dynamic>> homeVideoContent() async {
    return {'list': []};
  }

  /// 分类列表
  /// 用户点击分类或切换筛选条件时调用
  Future<Map<String, dynamic>> categoryContent(
    String tid,
    String pg,
    bool filter,
    Map<String, String> extend,
  ) async {
    return {'list': [], 'pagecount': 1};
  }

  /// 影片详情
  /// 用户点击影片卡片时调用
  Future<Map<String, dynamic>> detailContent(List<String> ids) async {
    return {'list': []};
  }

  /// 搜索
  /// 用户输入关键字搜索时调用
  Future<Map<String, dynamic>> searchContent(
    String key,
    bool quick, {
    String? pg,
  }) async {
    return {'list': []};
  }

  /// 播放解析
  /// 用户选择集数准备播放时调用
  Future<Map<String, dynamic>> playerContent(
    String flag,
    String id,
    List<String> vipFlags,
  ) async {
    return {'url': '', 'parse': 0};
  }

  /// 直播频道列表
  /// 加载直播源时调用
  Future<String> liveContent(String url) async {
    return '';
  }

  /// 本地代理
  /// 本地 HTTP 代理服务器收到请求时调用
  Future<List<dynamic>> proxy(Map<String, String> params) async {
    return [];
  }

  /// 自定义动作
  /// UI 层调用特定自定义指令时调用
  Future<Map<String, dynamic>> action(String actionStr) async {
    return {};
  }

  /// 手动检查视频格式
  /// 返回 true 时，框架会在 WebView 中拦截 URL 后调用 isVideoFormat
  Future<bool> manualVideoCheck() async {
    return false;
  }

  /// 检查是否为视频格式
  /// 判断指定 URL 是否为有效的直接媒体 URL
  Future<bool> isVideoFormat(String url) async {
    // 常见的视频格式
    final videoPatterns = [
      r'\.m3u8',
      r'\.mp4',
      r'\.flv',
      r'\.avi',
      r'\.mkv',
      r'\.wmv',
      r'\.mov',
      r'\.webm',
      r'\.mpd',
    ];
    
    for (var pattern in videoPatterns) {
      if (RegExp(pattern, caseSensitive: false).hasMatch(url)) {
        return true;
      }
    }
    
    return false;
  }

  /// 销毁
  /// 配置重新加载或应用清理缓存时调用
  Future<void> destroy() async {
    Log.d('Spider destroy');
  }

  /// 辅助方法：将结果转换为 JSON 字符串
  String toJson(Map<String, dynamic> data) {
    return json.encode(data);
  }

  /// 辅助方法：从 JSON 字符串解析
  Map<String, dynamic> fromJson(String jsonStr) {
    return json.decode(jsonStr);
  }

  /// 辅助方法：创建 Vod 对象
  Map<String, dynamic> createVod({
    required String vodId,
    required String vodName,
    String? vodPic,
    String? vodRemarks,
    String? typeName,
    String? vodYear,
    String? vodArea,
    String? vodDirector,
    String? vodActor,
    String? vodContent,
    String? vodPlayFrom,
    String? vodPlayUrl,
    String? vodTag,
  }) {
    return {
      'vod_id': vodId,
      'vod_name': vodName,
      'vod_pic': vodPic,
      'vod_remarks': vodRemarks,
      'type_name': typeName,
      'vod_year': vodYear,
      'vod_area': vodArea,
      'vod_director': vodDirector,
      'vod_actor': vodActor,
      'vod_content': vodContent,
      'vod_play_from': vodPlayFrom,
      'vod_play_url': vodPlayUrl,
      'vod_tag': vodTag,
    };
  }

  /// 辅助方法：创建 Class 对象
  Map<String, dynamic> createClass({
    required String typeId,
    required String typeName,
    String? typeFlag,
  }) {
    return {
      'type_id': typeId,
      'type_name': typeName,
      'type_flag': typeFlag,
    };
  }

  /// 辅助方法：创建 Filter 对象
  Map<String, dynamic> createFilter({
    required String key,
    required String name,
    required List<Map<String, dynamic>> value,
    String? init,
  }) {
    return {
      'key': key,
      'name': name,
      'value': value,
      'init': init,
    };
  }

  /// 辅助方法：繁简转换（如果需要）
  Future<String> traditionalToSimplified(String text) async {
    // TODO: 集成繁简转换库
    return text;
  }

  /// 辅助方法：网络请求
  Future<String> fetch(String url, {Map<String, String>? headers}) async {
    return await OkHttpUtils.get(url, headers: headers);
  }
}
