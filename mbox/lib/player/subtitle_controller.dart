import 'dart:convert';
import 'dart:io';
import '../models/sub.dart';
import '../network/okhttp_utils.dart';
import '../utils/log_utils.dart';

/// 字幕数据项
class SubtitleItem {
  final Duration startTime;     // 开始时间
  final Duration endTime;       // 结束时间
  final String text;            // 字幕文本
  final List<String>? styles;   // 样式

  SubtitleItem({
    required this.startTime,
    required this.endTime,
    required this.text,
    this.styles,
  });

  /// 检查是否在指定时间显示
  bool isActiveAt(Duration position) {
    return position >= startTime && position <= endTime;
  }
}

/// 字幕解析器
class SubtitleParser {
  /// 解析字幕
  static Future<List<SubtitleItem>> parse({
    required String url,
    String? format,
  }) async {
    try {
      String content;
      
      // 如果是本地文件
      if (url.startsWith('/')) {
        content = await File(url).readAsString();
      } else {
        // 网络 URL
        content = await OkHttpUtils.getText(url) ?? '';
      }

      if (content.isEmpty) {
        return [];
      }

      // 自动检测或通过参数指定格式
      final detectedFormat = format ?? _detectFormat(url, content);
      
      switch (detectedFormat) {
        case 'srt':
          return _parseSRT(content);
        case 'ass':
        case 'ssa':
          return _parseASS(content);
        case 'vtt':
          return _parseVTT(content);
        default:
          Log.w('Unknown subtitle format: $detectedFormat');
          return [];
      }
    } catch (e) {
      Log.e('Subtitle parse error: $e');
      return [];
    }
  }

  /// 检测字幕格式
  static String _detectFormat(String url, String content) {
    // 通过扩展名检测
    if (url.endsWith('.srt')) return 'srt';
    if (url.endsWith('.ass')) return 'ass';
    if (url.endsWith('.ssa')) return 'ssa';
    if (url.endsWith('.vtt')) return 'vtt';

    // 通过内容检测
    if (content.contains('WEBVTT')) return 'vtt';
    if (content.contains('[Script Info]')) return 'ass';
    if (content.contains('[V4+ Styles]')) return 'ass';
    
    // 默认 SRT
    return 'srt';
  }

  /// 解析 SRT 格式
  static List<SubtitleItem> _parseSRT(String content) {
    final List<SubtitleItem> items = [];
    
    // SRT 格式:
    // 1
    // 00:00:01,000 --> 00:00:04,000
    // 字幕文本
    
    final blocks = content.split('\n\n');
    
    for (var block in blocks) {
      final lines = block.trim().split('\n');
      if (lines.length < 3) continue;
      
      // 解析时间行
      final timeMatch = RegExp(r'(\d{2}):(\d{2}):(\d{2}),(\d{3})\s*-->\s*(\d{2}):(\d{2}):(\d{2}),(\d{3})')
          .firstMatch(lines[1]);
      
      if (timeMatch == null) continue;
      
      final startMs = _parseTimeSrt(lines[0], lines[1]);
      final endMs = _parseTimeSrt(lines[0], lines[1], isEnd: true);
      
      if (startMs == null || endMs == null) continue;
      
      // 合并多行文本
      final text = lines.sublist(2).join('\n');
      
      items.add(SubtitleItem(
        startTime: Duration(milliseconds: startMs),
        endTime: Duration(milliseconds: endMs),
        text: text,
      ));
    }

    return items;
  }

  /// 解析 SSA/ASS 格式
  static List<SubtitleItem> _parseASS(String content) {
    final List<SubtitleItem> items = [];
    
    // ASS 格式较为复杂，这里简化处理
    // [Events]
    // Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
    // Dialogue: 0,0:00:01.00,0:00:04.00,Default,,0,0,0,,字幕文本
    
    final eventsIndex = content.indexOf('[Events]');
    if (eventsIndex == -1) return [];

    final eventsContent = content.substring(eventsIndex);
    final lines = eventsContent.split('\n');
    
    bool inEvents = false;
    for (var line in lines) {
      line = line.trim();
      
      if (line.startsWith('Format:')) {
        inEvents = true;
        continue;
      }
      
      if (!inEvents || !line.startsWith('Dialogue:')) continue;
      
      // 解析对话行
      final parts = _splitAssLine(line.substring('Dialogue:'.length));
      
      if (parts.length < 10) continue;
      
      try {
        final startMs = _parseTimeAss(parts[1]);
        final endMs = _parseTimeAss(parts[2]);
        final text = parts[9].replaceAll('\\N', '\n');
        
        items.add(SubtitleItem(
          startTime: Duration(milliseconds: startMs),
          endTime: Duration(milliseconds: endMs),
          text: text,
          styles: [parts[3]], // Style name
        ));
      } catch (e) {
        Log.e('Parse ASS line error: $e');
      }
    }

    return items;
  }

  /// 解析 VTT 格式
  static List<SubtitleItem> _parseVTT(String content) {
    final List<SubtitleItem> items = [];
    
    // 移除 WEBVTT 头部
    final webvttIndex = content.indexOf('WEBVTT');
    if (webvttIndex >= 0) {
      content = content.substring(webvttIndex + 6);
    }
    
    final blocks = content.split('\n\n');
    
    for (var block in blocks) {
      final lines = block.trim().split('\n');
      if (lines.isEmpty) continue;
      
      // 跳过序号
      int lineIndex = 0;
      if (lines.length > 1 && RegExp(r'^\d+$').hasMatch(lines[0].trim())) {
        lineIndex = 1;
      }
      
      if (lineIndex >= lines.length) continue;
      
      // 解析时间行
      final timeMatch = RegExp(r'(\d{2}):(\d{2}):(\d{2})\.(\d{3})\s*-->\s*(\d{2}):(\d{2}):(\d{2})\.(\d{3})')
          .firstMatch(lines[lineIndex]);
      
      if (timeMatch == null) continue;
      
      final startMs = _parseTimeVtt(lines[lineIndex]);
      final endMs = _parseTimeVtt(lines[lineIndex], isEnd: true);
      
      if (startMs == null || endMs == null) continue;
      
      // 获取文本
      final text = lines.sublist(lineIndex + 1).join('\n');
      
      items.add(SubtitleItem(
        startTime: Duration(milliseconds: startMs),
        endTime: Duration(milliseconds: endMs),
        text: text,
      ));
    }

    return items;
  }

  /// 解析 SRT 时间戳
  static int? _parseTimeSrt(String index, String timeLine, {bool isEnd = false}) {
    try {
      final match = RegExp(r'(\d{2}):(\d{2}):(\d{2}),(\d{3})\s*-->\s*(\d{2}):(\d{2}):(\d{2}),(\d{3})')
          .firstMatch(timeLine);
      
      if (match == null) return null;
      
      final groups = match.groups([1, 2, 3, 4, 5, 6, 7, 8]);
      final offset = isEnd ? 4 : 0;
      
      final hours = int.parse(groups[offset]!);
      final minutes = int.parse(groups[offset + 1]!);
      final seconds = int.parse(groups[offset + 2]!);
      final milliseconds = int.parse(groups[offset + 3]!);
      
      return hours * 3600000 + minutes * 60000 + seconds * 1000 + milliseconds;
    } catch (e) {
      return null;
    }
  }

  /// 解析 ASS 时间戳
  static int _parseTimeAss(String timeStr) {
    // 格式：H:MM:SS.cc 或 H:MM:SS.cc
    final match = RegExp(r'(\d+):(\d{2}):(\d{2})\.(\d{2})').firstMatch(timeStr);
    if (match == null) {
      // 尝试毫秒格式
      final match2 = RegExp(r'(\d+):(\d{2}):(\d{2})\.(\d{3})').firstMatch(timeStr);
      if (match2 != null) {
        return int.parse(match2.group(1)!) * 3600000 +
               int.parse(match2.group(2)!) * 60000 +
               int.parse(match2.group(3)!) * 1000 +
               int.parse(match2.group(4)!);
      }
      return 0;
    }
    
    final hours = int.parse(match.group(1)!);
    final minutes = int.parse(match.group(2)!);
    final seconds = int.parse(match.group(3)!);
    final centiseconds = int.parse(match.group(4)!);
    
    return hours * 3600000 + minutes * 60000 + seconds * 1000 + centiseconds * 10;
  }

  /// 解析 VTT 时间戳
  static int? _parseTimeVtt(String timeLine, {bool isEnd = false}) {
    try {
      final match = RegExp(r'(\d{2}):(\d{2}):(\d{2})\.(\d{3})\s*-->\s*(\d{2}):(\d{2}):(\d{2})\.(\d{3})')
          .firstMatch(timeLine);
      
      if (match == null) return null;
      
      final groups = match.groups([1, 2, 3, 4, 5, 6, 7, 8]);
      final offset = isEnd ? 4 : 0;
      
      final hours = int.parse(groups[offset]!);
      final minutes = int.parse(groups[offset + 1]!);
      final seconds = int.parse(groups[offset + 2]!);
      final milliseconds = int.parse(groups[offset + 3]!);
      
      return hours * 3600000 + minutes * 60000 + seconds * 1000 + milliseconds;
    } catch (e) {
      return null;
    }
  }

  /// 分割 ASS 行（处理逗号分隔）
  static List<String> _splitAssLine(String line) {
    // ASS 格式可能包含逗号，需要特殊处理
    // 简单实现：直接按逗号分割
    return line.split(',');
  }

  /// 在指定时间获取字幕
  static String? getSubtitleAt(Duration position, List<SubtitleItem> items) {
    for (final item in items) {
      if (item.isActiveAt(position)) {
        return item.text;
      }
    }
    return null;
  }
}

/// 字幕控制器
class SubtitleController {
  List<SubtitleItem> _subtitles = [];
  String? _currentSubtitle;
  Function(String?)? onSubtitleChanged;
  Duration _currentPosition = Duration.zero;

  /// 加载字幕
  Future<void> load(List<SubtitleItem> items) async {
    _subtitles = items;
  }

  /// 跳转到指定位置
  void seek(Duration position) {
    _currentPosition = position;
    _updateSubtitle();
  }

  /// 设置当前字幕
  void setSubtitle(String? subtitle) {
    _currentSubtitle = subtitle;
    onSubtitleChanged?.call(subtitle);
  }

  /// 获取当前字幕
  String? get currentSubtitle => _currentSubtitle;

  /// 获取所有字幕项
  List<SubtitleItem> get subtitles => _subtitles;

  /// 更新字幕
  void _updateSubtitle() {
    final subtitle = SubtitleParser.getSubtitleAt(_currentPosition, _subtitles);
    if (subtitle != _currentSubtitle) {
      setSubtitle(subtitle);
    }
  }

  /// 检查字幕列表是否为空
  bool get isEmpty => _subtitles.isEmpty;

  /// 检查是否有多个字幕
  bool get hasMultiple => _subtitles.length > 1;
}
