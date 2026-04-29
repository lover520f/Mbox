import 'dart:convert';

/// 弹幕数据类型
enum DanmakuMode {
  rtl,      // 从右向左滚动
  ltr,      // 从左向右滚动
  top,      // 顶部固定
  bottom,   // 底部固定
  special,  // 特殊效果弹幕
}

/// 弹幕对象
class Danmaku {
  final double time;          // 弹幕出现时间 (秒)
  final String text;          // 弹幕内容
  final DanmakuMode mode;     // 弹幕类型
  final int color;            // 弹幕颜色 (ARGB)
  final String? userId;       // 发送用户 ID
  final double? fontSize;     // 字体大小
  final double? duration;     // 显示持续时间 (秒)
  final String? url;          // 弹幕来源 URL

  Danmaku({
    required this.time,
    required this.text,
    this.mode = DanmakuMode.rtl,
    this.color = 0xFFFFFFFF,
    this.userId,
    this.fontSize,
    this.duration,
    this.url,
  });

  /// 从 XML 弹幕行解析 (Bilibili 格式)
  factory Danmaku.fromXml(String line) {
    // 格式：<d p="time,mode,size,color,timestamp,userId,hash,other">text</d>
    try {
      final start = line.indexOf('<d p="') + 5;
      final end = line.indexOf('">');
      final textStart = end + 2;
      final textEnd = line.lastIndexOf('</d>');
      
      if (start < 0 || end < 0 || textEnd < 0) {
        throw FormatException('Invalid XML format');
      }
      
      final params = line.substring(start, end).split(',');
      final text = line.substring(textStart, textEnd);
      
      final time = double.tryParse(params[0]) ?? 0;
      final mode = _parseMode(params[1]);
      final fontSize = double.tryParse(params[2]) ?? 25;
      final color = int.tryParse(params[3]) ?? 0xFFFFFFFF;
      final timestamp = int.tryParse(params[4]);
      final userId = params.length > 5 ? params[5] : null;
      
      return Danmaku(
        time: time,
        text: text,
        mode: mode,
        color: color | 0xFF000000, // 确保 alpha=255
        userId: userId,
        fontSize: fontSize,
      );
    } catch (e) {
      throw FormatException('Parse danmaku failed: $e');
    }
  }

  /// 从 JSON 解析
  factory Danmaku.fromJson(Map<String, dynamic> json) {
    return Danmaku(
      time: (json['time'] as num?)?.toDouble() ?? 0,
      text: json['text'] as String? ?? '',
      mode: _parseMode(json['mode']?.toString() ?? '1'),
      color: (json['color'] as int?) ?? 0xFFFFFFFF,
      userId: json['user_id'] as String?,
      fontSize: (json['font_size'] as num?)?.toDouble(),
      duration: (json['duration'] as num?)?.toDouble(),
      url: json['url'] as String?,
    );
  }

  /// 批量从 JSON 列表解析
  static List<Danmaku> fromJsonList(List<dynamic> list) {
    return list.whereType<Map<String, dynamic>>().map((json) => Danmaku.fromJson(json)).toList();
  }

  /// 从弹幕文本解析 (每行一条)
  static List<Danmaku> fromText(String text) {
    final lines = text.split('\n');
    final danmakus = <Danmaku>[];
    
    for (final line in lines) {
      if (line.trim().isEmpty) continue;
      try {
        danmakus.add(Danmaku.fromXml(line.trim()));
      } catch (e) {
        // 跳过无效行
      }
    }
    
    return danmakus;
  }

  Map<String, dynamic> toJson() => {
    'time': time,
    'text': text,
    'mode': mode.index.toString(),
    'color': color,
    'user_id': userId,
    'font_size': fontSize,
    'duration': duration,
    'url': url,
  };

  static DanmakuMode _parseMode(String mode) {
    switch (mode) {
      case '1': return DanmakuMode.rtl;
      case '2': return DanmakuMode.rtl;
      case '3': return DanmakuMode.rtl;
      case '4': return DanmakuMode.bottom;
      case '5': return DanmakuMode.top;
      case '6': return DanmakuMode.special;
      case '-1': return DanmakuMode.ltr;
      default: return DanmakuMode.rtl;
    }
  }
}

/// 弹幕轨道管理类
class DanmakuTrack {
  final int trackIndex;
  final Danmaku danmaku;
  double x;           // 当前 X 位置
  bool isVisible;     // 是否可见
  double progress;    // 动画进度 0-1

  DanmakuTrack({
    required this.trackIndex,
    required this.danmaku,
    this.x = 0,
    this.isVisible = true,
    this.progress = 0,
  });
}

/// 弹幕配置
class DanmakuConfig {
  bool enabled;             // 是否启用
  int alpha;                // 透明度 0-255
  double fontSize;          // 字体大小
  double speed;             // 滚动速度
  double topMargin;         // 顶部占据比例 (0-1)
  double bottomMargin;      // 底部占据比例 (0-1)
  bool showTop;            // 显示顶部弹幕
  bool showBottom;         // 显示底部弹幕
  bool showSpecial;        // 显示特殊弹幕

  DanmakuConfig({
    this.enabled = true,
    this.alpha = 255,
    this.fontSize = 25,
    this.speed = 1.0,
    this.topMargin = 0.5,
    this.bottomMargin = 0.3,
    this.showTop = true,
    this.showBottom = true,
    this.showSpecial = false,
  });

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'alpha': alpha,
    'font_size': fontSize,
    'speed': speed,
    'top_margin': topMargin,
    'bottom_margin': bottomMargin,
    'show_top': showTop,
    'show_bottom': showBottom,
    'show_special': showSpecial,
  };
}

