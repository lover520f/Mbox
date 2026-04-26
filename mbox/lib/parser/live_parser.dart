import 'dart:convert';
import 'package:xml/xml.dart';
import '../models/vod_config.dart';
import '../utils/log_utils.dart';

/// 直播解析器
/// 支持 M3U、TXT、JSON 三种格式
class LiveParser {
  
  /// 解析直播源
  /// [content] - 直播源内容
  /// [format] - 指定格式（可选，自动检测）
  static Future<List<Group>> parse(String content, {String? format}) async {
    try {
      content = content.trim();
      
      // 自动检测格式
      final detectedFormat = format ?? _detectFormat(content);
      
      Log.d('Parsing live content, format: $detectedFormat');
      
      switch (detectedFormat) {
        case 'json':
          return _parseJson(content);
        case 'm3u':
          return _parseM3u(content);
        case 'txt':
          return _parseTxt(content);
        default:
          throw Exception('Unknown format: $detectedFormat');
      }
    } catch (e) {
      Log.e('Failed to parse live content: $e');
      return [];
    }
  }

  /// 自动检测格式
  static String _detectFormat(String content) {
    if (content.startsWith('[')) {
      return 'json';
    } else if (content.contains('#EXTM3U') && !content.contains('#genre#')) {
      return 'm3u';
    } else {
      return 'txt';
    }
  }

  /// 解析 JSON 格式
  static Future<List<Group>> _parseJson(String content) async {
    final List<dynamic> jsonData = json.decode(content);
    return jsonData.map((g) => Group.fromJson(g as Map<String, dynamic>)).toList();
  }

  /// 解析 M3U 格式
  static Future<List<Group>> _parseM3u(String content) async {
    final groups = <Group>[];
    final lines = content.split('\n');
    
    String currentGroupName = '默认';
    final channels = <Channel>[];
    
    // M3U 全局属性
    String? globalCatchupType;
    String? globalCatchupSource;
    String? globalCatchupReplace;
    String? tvgUrl;
    
    // 当前频道属性
    Map<String, String>? currentChannelAttrs;
    String? currentChannelName;
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      
      // 解析 #EXTM3U 行
      if (line.startsWith('#EXTM3U')) {
        final attrs = _parseM3uAttributes(line);
        globalCatchupType = attrs['catchup'];
        globalCatchupSource = attrs['catchup-source'];
        globalCatchupReplace = attrs['catchup-replace'];
        tvgUrl = attrs['tvg-url'] ?? attrs['url-tvg'];
        continue;
      }
      
      // 解析 #EXTINF 行
      if (line.startsWith('#EXTINF:')) {
        final attrs = _parseExtInfAttributes(line);
        currentChannelAttrs = attrs;
        // 获取频道名称（逗号后的内容）
        final commaIndex = line.lastIndexOf(',');
        if (commaIndex != -1 && commaIndex < line.length - 1) {
          currentChannelName = line.substring(commaIndex + 1).trim();
        }
        continue;
      }
      
      // 解析频道指令
      if (line.startsWith('#EXTHTTP:') || 
          line.startsWith('#EXTVLCOPT:') || 
          line.startsWith('#KODIPROP:')) {
        // 暂不处理，后续添加到 channel attrs
        continue;
      }
      
      // 解析其他指令（catchup, format 等）
      if (line.startsWith('#') && !line.startsWith('#EXT')) {
        // 可能是自定义指令
        continue;
      }
      
      // URL 行
      if (line.contains('://') || line.startsWith('http')) {
        if (currentChannelName != null) {
          // 解析 URL 和行内标头
          final urlParts = line.split('|');
          final url = urlParts.first;
          Map<String, String>? headers;
          
          if (urlParts.length > 1) {
            headers = _parseInlineHeaders(urlParts.sublist(1).join('|'));
          }
          
          final channel = Channel(
            name: currentChannelName!,
            urls: [url],
            logo: currentChannelAttrs?['tvg-logo'],
            tvgId: currentChannelAttrs?['tvg-id'],
            tvgName: currentChannelAttrs?['tvg-name'],
            ua: currentChannelAttrs?['http-user-agent'] ?? 
                currentChannelAttrs?['http-user-agent'],
            catchup: _parseCatchup(
              currentChannelAttrs,
              globalCatchupType,
              globalCatchupSource,
              globalCatchupReplace,
            ),
            header: headers,
          );
          
          channels.add(channel);
          currentChannelName = null;
          currentChannelAttrs = null;
        }
      }
      
      // 解析分组（group-title 属性）
      if (currentChannelAttrs != null && currentChannelAttrs!.containsKey('group-title')) {
        currentGroupName = currentChannelAttrs!['group-title']!;
      }
    }
    
    // 创建分组
    if (channels.isNotEmpty) {
      groups.add(Group(
        name: currentGroupName,
        channel: channels,
      ));
    }
    
    return groups;
  }

  /// 解析 TXT 格式
  static Future<List<Group>> _parseTxt(String content) async {
    final groups = <Group>[];
    final lines = content.split('\n');
    
    String currentGroupName = '默认';
    String? currentGroupPass;
    final channels = <Channel>[];
    
    // 全局指令
    Map<String, String> globalHeaders = {};
    
    for (final line in lines) {
      final trimmedLine = line.trim();
      if (trimmedLine.isEmpty) continue;
      
      // 分组行
      if (trimmedLine.contains('#genre#')) {
        // 保存之前的分组
        if (channels.isNotEmpty) {
          groups.add(Group(
            name: currentGroupName,
            pass: currentGroupPass,
            channel: List.from(channels),
          ));
          channels.clear();
        }
        
        // 解析新分组
        final parts = trimmedLine.split(',');
        final groupNamePart = parts.first.trim();
        
        // 检查是否有密码（使用_分隔）
        final nameParts = groupNamePart.split('_');
        if (nameParts.length >= 2) {
          currentGroupName = nameParts.sublist(0, nameParts.length - 1).join('_');
          currentGroupPass = nameParts.last;
        } else {
          currentGroupName = groupNamePart;
          currentGroupPass = null;
        }
        
        continue;
      }
      
      // 指令行（不含 ://）
      if (!trimmedLine.contains('://')) {
        if (trimmedLine.startsWith('ua=')) {
          globalHeaders['User-Agent'] = trimmedLine.substring(3);
        } else if (trimmedLine.startsWith('origin=')) {
          globalHeaders['Origin'] = trimmedLine.substring(7);
        } else if (trimmedLine.startsWith('referer=')) {
          globalHeaders['Referer'] = trimmedLine.substring(8);
        } else if (trimmedLine.startsWith('header=')) {
          // 解析 JSON 格式的 header
          try {
            final headerJson = json.decode(trimmedLine.substring(7)) as Map<String, dynamic>;
            globalHeaders.addAll(headerJson.map((k, v) => MapEntry(k, v.toString())));
          } catch (e) {
            Log.e('Failed to parse header: $e');
          }
        } else if (trimmedLine.startsWith('format=')) {
          // format 指令
        } else if (trimmedLine.startsWith('parse=')) {
          // parse 指令
        } else if (trimmedLine.startsWith('click=')) {
          // click 指令
        }
        continue;
      }
      
      // 频道行
      final parts = trimmedLine.split(',');
      if (parts.length >= 2) {
        final name = parts.first.trim();
        final urlsPart = parts.sublist(1).join(',').trim();
        
        // 解析多线路（#分隔）
        final urlStrings = urlsPart.split('#');
        final urls = <String>[];
        
        for (final urlStr in urlStrings) {
          // 解析 URL 和行内标头
          final urlParts = urlStr.split('|');
          urls.add(urlParts.first);
          
          if (urlParts.length > 1) {
            // 行内标头
            final headers = _parseInlineHeaders(urlParts.sublist(1).join('|'));
            // 应用到全局 headers
            globalHeaders.addAll(headers);
          }
        }
        
        final channel = Channel(
          name: name,
          urls: urls,
          header: Map.from(globalHeaders),
        );
        
        channels.add(channel);
      }
    }
    
    // 保存最后一个分组
    if (channels.isNotEmpty) {
      groups.add(Group(
        name: currentGroupName,
        pass: currentGroupPass,
        channel: channels,
      ));
    }
    
    return groups;
  }

  /// 解析 M3U 属性
  static Map<String, String> _parseM3uAttributes(String line) {
    final attrs = <String, String>{};
    final regex = RegExp(r'(\S+?)="(.*?)"');
    
    for (final match in regex.allMatches(line)) {
      attrs[match.group(1)!] = match.group(2)!;
    }
    
    return attrs;
  }

  /// 解析 #EXTINF 属性
  static Map<String, String> _parseExtInfAttributes(String line) {
    final attrs = <String, String>{};
    final regex = RegExp(r'(\S+?)="(.*?)"');
    
    for (final match in regex.allMatches(line)) {
      attrs[match.group(1)!] = match.group(2)!;
    }
    
    return attrs;
  }

  /// 解析行内标头
  static Map<String, String> _parseInlineHeaders(String headerStr) {
    final headers = <String, String>{};
    final pairs = headerStr.split('&');
    
    for (final pair in pairs) {
      final kv = pair.split('=');
      if (kv.length == 2) {
        headers[kv.first.trim()] = kv.last.trim();
      }
    }
    
    return headers;
  }

  /// 解析追看配置
  static Catchup? _parseCatchup(
    Map<String, String>? channelAttrs,
    String? globalType,
    String? globalSource,
    String? globalReplace,
  ) {
    final type = channelAttrs?['catchup'] ?? globalType;
    final source = channelAttrs?['catchup-source'] ?? globalSource;
    final replace = channelAttrs?['catchup-replace'] ?? globalReplace;
    
    if (type == null && source == null) {
      return null;
    }
    
    return Catchup(
      type: type ?? 'append',
      source: source,
      replace: replace,
    );
  }
}
