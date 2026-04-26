import 'package:flutter/material.dart';

/// 应用级状态管理
class AppProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _loadingMessage;
  bool _isDarkMode = true;
  int? _currentTabIndex;

  bool get isLoading => _isLoading;
  String? get loadingMessage => _loadingMessage;
  bool get isDarkMode => _isDarkMode;
  int? get currentTabIndex => _currentTabIndex;

  /// 显示加载指示器
  void showLoading({String? message}) {
    _isLoading = true;
    _loadingMessage = message;
    notifyListeners();
  }

  /// 隐藏加载指示器
  void hideLoading() {
    _isLoading = false;
    _loadingMessage = null;
    notifyListeners();
  }

  /// 切换暗色模式
  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  /// 设置当前 Tab 索引
  void setCurrentTabIndex(int index) {
    _currentTabIndex = index;
    notifyListeners();
  }
}
