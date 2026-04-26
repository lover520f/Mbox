import 'dart:convert';
import 'package:collection/collection.dart';
import '../utils/log_utils.dart';

/// 广告拦截器
class AdBlocker {
  static late List<String> _domains = [];
  static late Map<String, RegExp> _regexRules = {};
  static late List<String> _blockedRequests = [];

  /// 初始化
  static Future<void> init(List<String> ads) async {
    _domains.clear();
    _regexRules.clear();
    
    for (final ad in ads) {
      if (ad.startsWith('/') && ad.endsWith('/')) {
        // 正则表达式规则
        try {
          final regex = RegExp(ad.substring(1, ad.length - 1));
          _regexRules[ad] = regex;
        } catch (e) {
          Log.e('Invalid regex rule: $ad');
        }
      } else {
        // 域名规则
        _domains.add(ad.toLowerCase());
      }
    }
    
    Log.d('AdBlocker initialized: ${_domains.length} domains, ${_regexRules.length} regex rules');
  }

  /// 检查 URL 是否应该被拦截
  static bool shouldBlock(String url) {
    try {
      final uri = Uri.parse(url);
      final hostname = uri.host.toLowerCase();
      
      // 检查域名黑名单
      for (final domain in _domains) {
        if (hostname == domain || hostname.endsWith('.$domain')) {
          Log.d('Ad blocked (domain): $url');
          _blockedRequests.add(url);
          return true;
        }
      }
      
      // 检查正则规则
      for (final regex in _regexRules.values) {
        if (regex.hasMatch(url)) {
          Log.d('Ad blocked (regex): $url');
          _blockedRequests.add(url);
          return true;
        }
      }
      
      return false;
    } catch (e) {
      // URL 解析失败，不拦截
      return false;
    }
  }

  /// 检查主机名是否应该被拦截
  static bool shouldBlockHost(String hostname) {
    hostname = hostname.toLowerCase();
    
    for (final domain in _domains) {
      if (hostname == domain || hostname.endsWith('.$domain')) {
        return true;
      }
    }
    
    return false;
  }

  /// 添加拦截规则
  static void addRule(String rule) {
    if (rule.startsWith('/') && rule.endsWith('/')) {
      try {
        final regex = RegExp(rule.substring(1, rule.length - 1));
        _regexRules[rule] = regex;
      } catch (e) {
        Log.e('Failed to add regex rule: $e');
      }
    } else {
      _domains.add(rule.toLowerCase());
    }
  }

  /// 移除拦截规则
  static void removeRule(String rule) {
    _domains.remove(rule.toLowerCase());
    _regexRules.remove(rule);
  }

  /// 获取统计信息
  static Map<String, dynamic> getStats() {
    return {
      'domains': _domains.length,
      'regex_rules': _regexRules.length,
      'blocked_requests': _blockedRequests.length,
      'blocked_sample': _blockedRequests.take(10).toList(),
    };
  }

  /// 清除拦截历史
  static void clearHistory() {
    _blockedRequests.clear();
  }

  /// 重置规则
  static void reset(List<String> ads) {
    _domains.clear();
    _regexRules.clear();
    _blockedRequests.clear();
    
    for (final ad in ads) {
      addRule(ad);
    }
  }
}
