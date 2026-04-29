import 'dart:convert';
import 'dart:io';
import 'package:xml/xml.dart';
import '../models/vod_config.dart';
import '../models/vod.dart';
import '../network/okhttp_client.dart';
import '../utils/log_utils.dart';

/// TVBox 格式转换器
/// 支持 Type 0 (XML), Type 1 (JSON), Type 4 (JSON+Base64)
class TvBoxParser {
  /// 解析 XML 格式（Type 0）
  static VodConfig parseXml(String xmlContent) {
    try {
      final document = XmlDocument.parse(xmlContent);
      final root = document.rootElement;

      final sites = <Site>[];
      final parses = <Parse>[];
      final lives = <Live>[];

      // 解析站点
      final siteElements = root.findElements('site');
      for (final elem in siteElements) {
        try {
          final site = _parseXmlSite(elem);
          if (site != null) sites.add(site);
        } catch (e) {
          Log.e('Parse XML site error: $e');
        }
      }

      // 解析解析器
      final parseElements = root.findElements('parse');
      for (final elem in parseElements) {
        try {
          final parse = _parseXmlParse(elem);
          if (parse != null) parses.add(parse);
        } catch (e) {
          Log.e('Parse XML parse error: $e');
        }
      }

      // 解析直播
      final liveElements = root.findElements('live');
      for (final elem in liveElements) {
        try {
          final live = _parseXmlLive(elem);
          if (live != null) lives.add(live);
        } catch (e) {
          Log.e('Parse XML live error: $e');
        }
      }

      // 获取 spider
      final spider = root.getElement('spider')?.text;

      return VodConfig(
        spider: spider,
        sites: sites,
        parses: parses,
        lives: lives,
      );
    } catch (e) {
      Log.e('Parse XML error: $e');
      rethrow;
    }
  }

  static Site? _parseXmlSite(XmlElement elem) {
    try {
      final key = elem.getAttribute('key') ?? '';
      final name = elem.getAttribute('name') ?? '';
      final type = int.tryParse(elem.getAttribute('type') ?? '1') ?? 1;
      final api = elem.getAttribute('api') ?? '';
      final ext = elem.getAttribute('ext');
      final jar = elem.getAttribute('jar');
      final searchable = elem.getAttribute('searchable');
      final changeable = elem.getAttribute('changeable');

      return Site(
        key: key,
        name: name,
        type: type,
        api: api,
        ext: ext,
        jar: jar,
        searchable: searchable != null ? int.tryParse(searchable) : null,
        changeable: changeable != null ? int.tryParse(changeable) : null,
      );
    } catch (e) {
      Log.e('Parse XML site error: $e');
      return null;
    }
  }

  static Parse? _parseXmlParse(XmlElement elem) {
    try {
      final name = elem.getAttribute('name') ?? '';
      final type = int.tryParse(elem.getAttribute('type') ?? '0') ?? 0;
      final url = elem.getAttribute('url') ?? '';
      final ext = elem.getAttribute('ext');

      ParseExt? parseExt;
      if (ext != null) {
        parseExt = ParseExt(header: {'User-Agent': USER_AGENT});
      }

      return Parse(
        name: name,
        type: type,
        url: url,
        ext: parseExt,
      );
    } catch (e) {
      Log.e('Parse XML parse error: $e');
      return null;
    }
  }

  static Live? _parseXmlLive(XmlElement elem) {
    try {
      final name = elem.getAttribute('name') ?? '';
      final url = elem.getAttribute('url');

      return Live(
        name: name,
        url: url,
      );
    } catch (e) {
      Log.e('Parse XML live error: $e');
      return null;
    }
  }

  /// 用户代理
  static const String USER_AGENT =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';
}
