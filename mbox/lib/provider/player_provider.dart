import 'package:flutter/material.dart';
import '../player/mbox_player_controller.dart';
import '../models/vod.dart' hide Sub, Danmaku;
import '../models/drm.dart';
import '../models/sub.dart' as sub;
import '../models/danmaku.dart' as danmaku;
import '../utils/log_utils.dart';

/// 播放器状态管理
class PlayerProvider extends ChangeNotifier {
  MBoxPlayerController? _controller;
  Vod? _currentVod;
  String? _currentUrl;
  int _currentEpisodeIndex = 0;
  bool _isPlaying = false;
  bool _isLoading = false;
  String? _error;

  MBoxPlayerController? get controller => _controller;
  Vod? get currentVod => _currentVod;
  String? get currentUrl => _currentUrl;
  int get currentEpisodeIndex => _currentEpisodeIndex;
  bool get isPlaying => _isPlaying;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// 初始化播放器控制器
  void initController() {
    _controller = MBoxPlayerController();
    
    _controller!.onStateChanged = (state) {
      _isPlaying = state == PlayerState.playing;
      notifyListeners();
    };
    
    _controller!.onError = (message) {
      _error = message;
      _isLoading = false;
      notifyListeners();
    };
    
    notifyListeners();
  }

  /// 播放视频
  Future<void> play({
    required String url,
    required Vod vod,
    String? userAgent,
    Map<String, String>? headers,
    List<sub.Sub>? subtitles,
    List<danmaku.Danmaku>? danmakus,
    Drm? drm,
  }) async {
    try {
      if (_controller == null) {
        initController();
      }
      
      _isLoading = true;
      _error = null;
      _currentUrl = url;
      _currentVod = vod;
      notifyListeners();

      await _controller!.play(
        url: url,
        userAgent: userAgent,
        headers: headers,
        subtitles: subtitles,
        danmakus: danmakus,
        drm: drm,
      );
      
      _isLoading = false;
      notifyListeners();
      
      Log.d('Playing: $url');
    } catch (e) {
      _error = '播放失败：$e';
      _isLoading = false;
      notifyListeners();
      Log.e('Failed to play: $e');
    }
  }

  /// 暂停播放
  Future<void> pause() async {
    await _controller?.pause();
  }

  /// 恢复播放
  Future<void> resume() async {
    await _controller?.resume();
  }

  /// 停止播放
  Future<void> stop() async {
    await _controller?.stop();
    _currentUrl = null;
    _currentVod = null;
    _isPlaying = false;
    notifyListeners();
  }

  /// 跳转到指定位置
  Future<void> seek(Duration position) async {
    await _controller?.seek(position);
  }

  /// 设置播放速度
  Future<void> setSpeed(double speed) async {
    await _controller?.setSpeed(speed);
  }

  /// 播放下一集
  Future<void> next() async {
    await _controller?.next();
  }

  /// 播放上一集
  Future<void> prev() async {
    await _controller?.prev();
  }

  /// 重新播放
  Future<void> replay() async {
    await _controller?.replay();
  }

  /// 切换循环播放
  Future<void> toggleRepeat() async {
    await _controller?.toggleRepeat();
  }

  /// 释放资源
  Future<void> dispose() async {
    await _controller?.dispose();
    _controller = null;
    _currentVod = null;
    _currentUrl = null;
    _isPlaying = false;
    notifyListeners();
  }

  /// 设置当前集数索引
  void setCurrentEpisodeIndex(int index) {
    _currentEpisodeIndex = index;
    notifyListeners();
  }
}
