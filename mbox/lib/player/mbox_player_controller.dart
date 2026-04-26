import 'dart:io';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart' as video;
import 'package:flutter/material.dart';
import '../models/sub.dart';
import '../models/danmaku.dart';
import '../models/drm.dart';
import '../utils/log_utils.dart';

/// 播放器状态枚举
enum PlayerState {
  idle,
  loading,
  buffering,
  ready,
  playing,
  paused,
  completed,
  error,
}

/// 播放器控制器
class MBoxPlayerController {
  late Player _player;
  late video.VideoController _videoController;
  
  PlayerState _state = PlayerState.idle;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  Duration _buffered = Duration.zero;
  double _speed = 1.0;
  
  // 弹幕控制器
  // DanmakuController? _danmakuController;
  
  // 当前字幕列表
  final List<Sub> _subtitles = [];
  int _currentSubtitleIndex = -1;
  
  // 回调函数
  Function(PlayerState)? onStateChanged;
  Function(Duration)? onPositionChanged;
  Function(Duration)? onDurationChanged;
  Function(String)? onError;
  Function()? onCompletion;

  /// 初始化播放器
  MBoxPlayerController() {
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    MediaKit.ensureInitialized();
    
    _player = Player();
    
    _videoController = video.VideoController(
      _player,
      configuration: const video.VideoControllerConfiguration(
        enableHardwareAcceleration: true,
      ),
    );
    
    // 监听播放器状态
    _player.stream.playing.listen((playing) {
      _updateState(state);
    });
    
    _player.stream.position.listen((position) {
      _position = position;
      onPositionChanged?.call(position);
    });
    
    _player.stream.duration.listen((duration) {
      _duration = duration;
      onDurationChanged?.call(duration);
    });
    
    _player.stream.buffer.listen((buffer) {
      _buffered = buffer;
    });
  }

  void _updateState(dynamic state) {
    Log.d('Player state changed: $state');
    
    // 根据 media_kit 的状态映射到我们的状态
    // TODO: 完善状态映射逻辑
    
    onStateChanged?.call(_state);
  }

  /// 播放视频
  Future<void> play({
    required String url,
    String? userAgent,
    Map<String, String>? headers,
    List<Sub>? subtitles,
    List<Danmaku>? danmakus,
    Drm? drm,
  }) async {
    try {
      _state = PlayerState.loading;
      onStateChanged?.call(_state);
      
      // 设置 HTTP 头
      final httpHeaders = <String, String>{};
      if (userAgent != null) {
        httpHeaders['User-Agent'] = userAgent;
      }
      if (headers != null) {
        httpHeaders.addAll(headers);
      }
      
      // 播放媒体
      await _player.open(
        Media(url, httpHeaders: httpHeaders),
      );
      
      // 设置字幕
      if (subtitles != null && subtitles.isNotEmpty) {
        _subtitles.clear();
        _subtitles.addAll(subtitles);
        // TODO: 加载字幕
      }
      
      // 设置弹幕
      // if (danmakus != null && danmakus.isNotEmpty) {
      //   await _initDanmaku(danmakus);
      // }
      
      _state = PlayerState.playing;
      onStateChanged?.call(_state);
      
      Log.d('Playing: $url');
    } catch (e) {
      _state = PlayerState.error;
      onStateChanged?.call(_state);
      onError?.call('播放失败：$e');
      Log.e('Failed to play: $e');
    }
  }

  /// 暂停播放
  Future<void> pause() async {
    await _player.pause();
    _state = PlayerState.paused;
    onStateChanged?.call(_state);
  }

  /// 恢复播放
  Future<void> resume() async {
    await _player.play();
    _state = PlayerState.playing;
    onStateChanged?.call(_state);
  }

  /// 停止播放
  Future<void> stop() async {
    await _player.stop();
    _state = PlayerState.idle;
    onStateChanged?.call(_state);
  }

  /// 跳转到指定位置
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  /// 设置播放速度
  Future<void> setSpeed(double speed) async {
    await _player.setRate(speed);
    _speed = speed;
  }

  /// 获取播放器视图
  video.VideoController get videoController => _videoController;
  
  /// 获取当前状态
  PlayerState get state => _state;
  
  /// 获取当前位置
  Duration get position => _position;
  
  /// 获取总时长
  Duration get duration => _duration;
  
  /// 获取缓冲进度
  Duration get buffered => _buffered;
  
  /// 获取播放速度
  double get speed => _speed;
  
  /// 检查是否正在播放
  bool get isPlaying => _state == PlayerState.playing;
  
  /// 检查是否有下一集
  bool get hasNext => false; // TODO: 实现播放列表
  
  /// 检查是否有上一集
  bool get hasPrev => false; // TODO: 实现播放列表
  
  /// 播放下一集
  Future<void> next() async {
    // TODO: 实现
  }
  
  /// 播放上一集
  Future<void> prev() async {
    // TODO: 实现
  }
  
  /// 重新播放
  Future<void> replay() async {
    await seek(Duration.zero);
  }

  /// 切换循环播放
  Future<void> toggleRepeat() async {
    // TODO: 实现循环播放
  }

  /// 释放资源
  Future<void> dispose() async {
    await _player.dispose();
    // _danmakuController?.dispose();
    Log.d('Player disposed');
  }
}
