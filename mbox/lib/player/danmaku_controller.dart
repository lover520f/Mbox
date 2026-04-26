import 'dart:async';
import 'dart:convert';
import 'package:danmaku/danmaku.dart';
import '../models/danmaku.dart';
import '../network/okhttp_client.dart';
import '../utils/log_utils.dart';

/// 弹幕数据项
class DanmakuItem {
  final String content;     // 弹幕内容
  final Duration time;      // 出现时间
  final int type;           // 弹幕类型（1:普通，4:底部，5:顶部）
  final String color;       // 颜色
  final String? user;       // 用户

  DanmakuItem({
    required this.content,
    required this.time,
    this.type = 1,
    this.color = 'FFFFFF',
    this.user,
  });

  /// 从 JSON 解析（Bilibili 格式）
  factory DanmakuItem.fromJson(List<dynamic> json) {
    return DanmakuItem(
      content: json[1].toString(),
      time: Duration(milliseconds: (double.parse(json[0].toString()) * 1000).toInt()),
      type: int.parse(json[1].toString().isNotEmpty ? '1' : json.length > 7 ? json[7].toString() : '1'),
      color: json.length > 3 ? json[3].toString() : 'FFFFFF',
      user: json.length > 10 ? json[10].toString() : null,
    );
  }

  /// 转换为 danmaku 库的 Danmaku 对象
  Danmaku toDanmaku() {
    return Danmaku(
      content: content,
      time: time,
      type: DanmakuType.values[type.clamp(0, 2)],
      color: ColorHex(color),
      fontSize: 25,
    );
  }
}

/// 弹幕解析器
class DanmakuParser {
  /// 解析弹幕数据
  static Future<List<DanmakuItem>> parse({
    required String url,
    String? type,
  }) async {
    try {
      final response = await OkHttpUtils.get(url);
      
      if (response == null || response.isEmpty) {
        return [];
      }

      // 根据类型解析不同格式
      if (type == 'json' || url.endsWith('.json')) {
        return _parseJson(response);
      } else if (type == 'xml' || url.endsWith('.xml')) {
        return _parseXml(response);
      } else {
        // 自动检测
        if (response.trim().startsWith('<')) {
          return _parseXml(response);
        } else {
          return _parseJson(response);
        }
      }
    } catch (e) {
      Log.e('Danmaku parse error: $e');
      return [];
    }
  }

  /// 解析 JSON 格式弹幕（Bilibili）
  static List<DanmakuItem> _parseJson(String jsonStr) {
    try {
      final data = json.decode(jsonStr);
      final List<DanmakuItem> items = [];

      if (data is Map && data['body'] != null) {
        for (var item in data['body']) {
          if (item is List && item.isNotEmpty) {
            items.add(DanmakuItem.fromJson(item));
          }
        }
      } else if (data is List) {
        for (var item in data) {
          if (item is List && item.isNotEmpty) {
            items.add(DanmakuItem.fromJson(item));
          }
        }
      }

      return items;
    } catch (e) {
      Log.e('Parse JSON danmaku error: $e');
      return [];
    }
  }

  /// 解析 XML 格式弹幕
  static List<DanmakuItem> _parseXml(String xmlStr) {
    try {
      final List<DanmakuItem> items = [];
      
      // 简单的 XML 解析
      final regex = RegExp(r'<d p="([^"]+)">([^<]+)</d>');
      for (var match in regex.allMatches(xmlStr)) {
        final p = match.group(1)?.split(',') ?? [];
        final content = match.group(2) ?? '';
        
        if (p.length >= 5) {
          items.add(DanmakuItem(
            content: content,
            time: Duration(milliseconds: (double.parse(p[0]) * 1000).toInt()),
            type: _getDanmakuType(int.parse(p[1])),
            color: _colorIntToHex(int.parse(p[2])),
          ));
        }
      }

      return items;
    } catch (e) {
      Log.e('Parse XML danmaku error: $e');
      return [];
    }
  }

  /// 获取弹幕类型
  static int _getDanmakuType(int typeCode) {
    switch (typeCode) {
      case 4: return 1; // 底部
      case 5: return 2; // 顶部
      default: return 0; // 滚动
    }
  }

  /// 颜色整数转十六进制
  static String _colorIntToHex(int color) {
    return (color & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase();
  }
}

/// 弹幕控制器
class DanmakuController {
  final danmaku.DanmakuController? _controller;
  final List<DanmakuItem> _items = [];
  bool _isPlaying = false;
  Duration _ currentPosition = Duration.zero;
  Timer? _timer;

  DanmakuController(this._controller);

  /// 加载弹幕
  Future<void> load(List<DanmakuItem> items) async {
    _items.clear();
    _items.addAll(items);
  }

  /// 开始播放
  void start() {
    _isPlaying = true;
    _startTimer();
  }

  /// 暂停播放
  void pause() {
    _isPlaying = false;
    _timer?.cancel();
  }

  /// 恢复播放
  void resume() {
    _isPlaying = true;
    _startTimer();
  }

  /// 停止播放
  void stop() {
    _isPlaying = false;
    _timer?.cancel();
    _controller?.clear();
  }

  /// 跳转到指定位置
  void seek(Duration position) {
    _currentPosition = position;
    _controller?.seek(position);
  }

  /// 发送弹幕
  void send(String content, {int type = 0, String color = 'FFFFFF'}) {
    final danmaku = Danmaku(
      content: content,
      time: _currentPosition,
      type: DanmakuType.values[type.clamp(0, 2)],
      color: ColorHex(color),
      fontSize: 25,
    );
    _controller?.add(danmaku);
  }

  /// 清除弹幕
  void clear() {
    _controller?.clear();
  }

  /// 显示弹幕
  void show() {
    _controller?.show();
  }

  /// 隐藏弹幕
  void hide() {
    _controller?.hide();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!_isPlaying) return;
      
      // 同步弹幕
      // danmaku 库会自动处理时间同步
    });
  }

  /// 释放资源
  void dispose() {
    _timer?.cancel();
    stop();
  }
}
