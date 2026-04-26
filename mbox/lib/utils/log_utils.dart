/// 日志工具类
class Log {
  static const _enableLog = true;
  static const _tag = 'MBox';

  static void d(String message) {
    if (_enableLog) {
      print('[$_tag/D] $message');
    }
  }

  static void i(String message) {
    if (_enableLog) {
      print('[$_tag/I] $message');
    }
  }

  static void w(String message) {
    if (_enableLog) {
      print('[$_tag/W] $message');
    }
  }

  static void e(String message) {
    if (_enableLog) {
      print('[$_tag/E] $message');
    }
  }
}
