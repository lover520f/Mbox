import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// 本地化工具类
class LocaleUtils {
  static const _supportedLocales = {
    'zh_CN': Locale('zh', 'CN'),
    'zh_TW': Locale('zh', 'TW'),
    'en_US': Locale('en', 'US'),
  };

  static const _fallbackLocale = Locale('zh', 'CN');

  /// 获取当前语言环境
  static Locale get currentLocale {
    final languageCode = Get.locale?.languageCode ?? 'zh';
    final countryCode = Get.locale?.countryCode ?? 'CN';
    return Locale(languageCode, countryCode);
  }

  /// 切换语言
  static Future<void> changeLocale(String localeCode) async {
    final locale = _supportedLocales[localeCode] ?? _fallbackLocale;
    await Get.updateLocale(locale);
  }

  /// 获取支持的 Locale 列表
  static List<Locale> get supportedLocales => _supportedLocales.values.toList();

  /// 获取语言名称
  static String getLanguageName(String localeCode) {
    switch (localeCode) {
      case 'zh_CN':
        return '简体中文';
      case 'zh_TW':
        return '繁體中文';
      case 'en_US':
        return 'English';
      default:
        return '简体中文';
    }
  }
}
