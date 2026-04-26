import 'dart:convert';
import 'package:xml/xml.dart';
import '../utils/log_utils.dart';

/// EPG 节目信息
class EpgProgram {
  final String? title;
  final String? desc;
  final DateTime? start;
  final DateTime? end;
  final String? icon;
  final List<String> categories;

  EpgProgram({
    this.title,
    this.desc,
    this.start,
    this.end,
    this.icon,
    this.categories = const [],
  });

  bool get isLive {
    if (start == null || end == null) return false;
    final now = DateTime.now();
    return now.isAfter(start!) && now.isBefore(end!);
  }

  String get duration {
    if (start == null || end == null) return '--:--';
    final diff = end!.difference(start!);
    final hours = diff.inHours.toString().padLeft(2, '0');
    final minutes = (diff.inMinutes % 60).toString().padLeft(2, '0');
    return '$hours:$minutes';
  }
}

/// EPG 频道信息
class EpgChannel {
  final String id;
  final String name;
  final String? icon;
  final List<EpgProgram> programs;

  EpgChannel({
    required this.id,
    required this.name,
    this.icon,
    this.programs = const [],
  });

  EpgProgram? getCurrentProgram() {
    final now = DateTime.now();
    for (final program in programs) {
      if (program.start != null && 
          program.end != null && 
          now.isAfter(program.start!) && 
          now.isBefore(program.end!)) {
        return program;
      }
    }
    return null;
  }

  EpgProgram? getProgramAt(DateTime time) {
    for (final program in programs) {
      if (program.start != null && 
          program.end != null && 
          time.isAfter(program.start!) && 
          time.isBefore(program.end!)) {
        return program;
      }
    }
    return null;
  }
}

/// EPG 解析器
/// 支持 XMLTV 格式
class EpgParser {
  
  /// 解析 XMLTV 格式的 EPG 数据
  static Future<List<EpgChannel>> parseXmltv(String content) async {
    try {
      final document = XmlDocument.parse(content);
      final channels = <EpgChannel>[];
      final programs = <EpgProgram>[];
      
      // 解析频道
      final tvElements = document.findAllElements('tv');
      for (final tvElem in tvElements) {
        for (final channelElem in tvElem.findAllElements('channel')) {
          final channelId = channelElem.getAttribute('id') ?? '';
          final displayName = channelElem
              .findElements('display-name')
              .firstWhere((e) => e.text.isNotEmpty, orElse: () => XmlElement(XmlName('display-name')))
              .text;
          
          final icon = channelElem
              .findElements('icon')
              .firstWhere((e) => e.getAttribute('src') != null, orElse: () => XmlElement(XmlName('icon')))
              .getAttribute('src');
          
          channels.add(EpgChannel(
            id: channelId,
            name: displayName,
            icon: icon,
          ));
        }
        
        // 解析节目
        for (final programmeElem in tvElem.findAllElements('programme')) {
          final channel = programmeElem.getAttribute('channel') ?? '';
          final start = _parseXmltvDate(programmeElem.getAttribute('start'));
          final stop = _parseXmltvDate(programmeElem.getAttribute('stop'));
          
          final title = programmeElem
              .findElements('title')
              .firstWhere((e) => e.text.isNotEmpty, orElse: () => XmlElement(XmlName('title')))
              .text;
          
          final desc = programmeElem
              .findElements('desc')
              .firstWhere((e) => e.text.isNotEmpty, orElse: () => XmlElement(XmlName('desc')))
              .text;
          
          final icon = programmeElem
              .findElements('icon')
              .firstWhere((e) => e.getAttribute('src') != null, orElse: () => XmlElement(XmlName('icon')))
              .getAttribute('src');
          
          final categories = programmeElem
              .findElements('category')
              .map((e) => e.text)
              .toList();
          
          programs.add(EpgProgram(
            start: start,
            end: stop,
            title: title.isNotEmpty ? title : null,
            desc: desc.isNotEmpty ? desc : null,
            icon: icon,
            categories: categories,
          ));
        }
      }
      
      // 将节目关联到频道
      final channelMap = {for (var c in channels) c.id: c};
      final result = <EpgChannel>[];
      
      for (final channel in channels) {
        final channelPrograms = programs
            .where((p) => true) // 简化处理，所有节目都添加
            .toList();
        
        result.add(EpgChannel(
          id: channel.id,
          name: channel.name,
          icon: channel.icon,
          programs: channelPrograms,
        ));
      }
      
      Log.d('Parsed ${result.length} EPG channels with ${programs.length} programs');
      return result;
    } catch (e) {
      Log.e('Failed to parse XMLTV: $e');
      return [];
    }
  }

  /// 解析 JSON 格式的 EPG 数据
  static Future<List<EpgChannel>> parseJson(String content) async {
    try {
      final jsonData = json.decode(content);
      final channels = <EpgChannel>[];
      
      for (final channelData in jsonData) {
        final programs = <EpgProgram>[];
        
        if (channelData['epg_data'] != null) {
          for (final programData in channelData['epg_data']) {
            programs.add(EpgProgram(
              title: programData['title'],
              desc: programData['desc'],
              start: programData['start_time'] != null 
                  ? DateTime.fromMillisecondsSinceEpoch(programData['start_time'] * 1000) 
                  : null,
              end: programData['end_time'] != null 
                  ? DateTime.fromMillisecondsSinceEpoch(programData['end_time'] * 1000) 
                  : null,
              icon: programData['icon'],
              categories: programData['category'] != null 
                  ? List<String>.from(programData['category']) 
                  : [],
            ));
          }
        }
        
        channels.add(EpgChannel(
          id: channelData['id'] ?? channelData['channel_id'] ?? '',
          name: channelData['name'] ?? channelData['channel_name'] ?? '',
          icon: channelData['icon'],
          programs: programs,
        ));
      }
      
      Log.d('Parsed ${channels.length} EPG channels from JSON');
      return channels;
    } catch (e) {
      Log.e('Failed to parse JSON EPG: $e');
      return [];
    }
  }

  /// 解析 XMLTV 日期格式
  static DateTime? _parseXmltvDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    
    try {
      // XMLTV 格式：20240101120000 +0000
      // 或：2024-01-01T12:00:00Z
      if (dateStr.contains('T')) {
        return DateTime.parse(dateStr);
      } else {
        final basicPattern = RegExp(r'(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})');
        final match = basicPattern.firstMatch(dateStr);
        if (match != null) {
          return DateTime(
            int.parse(match.group(1)!),
            int.parse(match.group(2)!),
            int.parse(match.group(3)!),
            int.parse(match.group(4)!),
            int.parse(match.group(5)!),
            int.parse(match.group(6)!),
          );
        }
      }
    } catch (e) {
      Log.e('Failed to parse date: $dateStr, error: $e');
    }
    
    return null;
  }

  /// 搜索频道
  static EpgChannel? findChannel(List<EpgChannel> channels, String channelId) {
    for (final channel in channels) {
      if (channel.id == channelId || channel.name == channelId) {
        return channel;
      }
    }
    return null;
  }

  /// 根据频道名称搜索
  static List<EpgChannel> findChannelsByName(List<EpgChannel> channels, String name) {
    return channels
        .where((c) => c.name.toLowerCase().contains(name.toLowerCase()))
        .toList();
  }
}
