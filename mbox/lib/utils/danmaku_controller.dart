import 'package:flutter/material.dart';
import 'dart:async';
import '../models/danmaku.dart';
import '../network/okhttp_client.dart';
import '../utils/log_utils.dart';

/// 弹幕控制器
class DanmakuController extends ChangeNotifier {
  final List<Danmaku> _danmakus = [];
  final List<DanmakuTrack> _activeTracks = [];
  final List<DanmakuTrack> _topTracks = [];
  final List<DanmakuTrack> _bottomTracks = [];
  
  DanmakuConfig _config = DanmakuConfig();
  Timer? _timer;
  
  double _currentPosition = 0; // 当前播放位置 (秒)
  bool _isPlaying = false;
  
  double _screenWidth = 0;
  double _screenHeight = 0;
  
  double get screenHeight => _screenHeight;
  
  /// 是否已加载弹幕
  bool get isLoaded => _danmakus.isNotEmpty;
  
  /// 获取弹幕数量
  int get danmakuCount => _danmakus.length;
  
  /// 获取当前配置
  DanmakuConfig get config => _config;
  
  /// 获取当前播放位置
  double get currentPosition => _currentPosition;
  
  /// 获取配置副本以便修改
  DanmakuConfig get configCopy => DanmakuConfig(
    enabled: _config.enabled,
    alpha: _config.alpha,
    fontSize: _config.fontSize,
    speed: _config.speed,
    topMargin: _config.topMargin,
    bottomMargin: _config.bottomMargin,
    showTop: _config.showTop,
    showBottom: _config.showBottom,
    showSpecial: _config.showSpecial,
  );
  
  /// 设置弹幕配置
  void setConfig(DanmakuConfig config) {
    _config = config;
    notifyListeners();
  }
  
  /// 从 URL 加载弹幕
  Future<void> loadFromUrl(String url) async {
    try {
      Log.d('Loading danmaku from: $url');
      final response = await OkHttpUtils.get(url);
      _parseDanmaku(response);
      
      if (_isPlaying) {
        play(); // 重新开始
      }
      
      notifyListeners();
      Log.d('Loaded ${_danmakus.length} danmakus');
    } catch (e) {
      Log.e('Load danmaku error: $e');
      rethrow;
    }
  }
  
  /// 从 XML 字符串解析弹幕
  void parseXml(String xmlContent) {
    _parseDanmaku(xmlContent);
    notifyListeners();
  }
  
  /// 解析弹幕 XML
  void _parseDanmaku(String xmlContent) {
    try {
      final lines = xmlContent.split('\n');
      _danmakus.clear();
      
      for (final line in lines) {
        if (line.trim().isEmpty || !line.contains('<d p="')) continue;
        try {
          _danmakus.add(Danmaku.fromXml(line.trim()));
        } catch (e) {
          // 跳过无效行
        }
      }
      
      // 按时间排序
      _danmakus.sort((a, b) => a.time.compareTo(b.time));
    } catch (e) {
      Log.e('Parse danmaku error: $e');
      rethrow;
    }
  }
  
  /// 设置屏幕尺寸
  void setScreenSize(double width, double height) {
    _screenWidth = width;
    _screenHeight = height;
  }
  
  /// 开始播放
  void play() {
    if (_isPlaying) return;
    
    _isPlaying = true;
    _startTimer();
  }
  
  /// 暂停播放
  void pause() {
    _isPlaying = false;
    _timer?.cancel();
  }
  
  /// 停止并重置
  void stop() {
    pause();
    _timer?.cancel();
    _activeTracks.clear();
    _topTracks.clear();
    _bottomTracks.clear();
    _currentPosition = 0;
  }
  
  /// 跳转到指定位置
  void seekTo(double seconds) {
    _currentPosition = seconds;
    
    // 清除已过期的弹幕
    _cleanupExpiredDanmakus();
    
    // 加载当前帧的弹幕
    _loadDanmakusForFrame();
    
    notifyListeners();
  }
  
  /// 清理过期的弹幕
  void _cleanupExpiredDanmakus() {
    _activeTracks.removeWhere((track) {
      return track.danmaku.time + (track.danmaku.duration ?? 5) < _currentPosition;
    });
    _topTracks.removeWhere((track) {
      return track.danmaku.time + (track.danmaku.duration ?? 5) < _currentPosition;
    });
    _bottomTracks.removeWhere((track) {
      return track.danmaku.time + (track.danmaku.duration ?? 5) < _currentPosition;
    });
  }
  
  /// 启动定时器
  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      _update();
    });
  }
  
  /// 更新弹幕状态
  void _update() {
    if (!_isPlaying || _screenWidth == 0) return;
    
    _currentPosition += 0.016; // ~60fps
    
    // 加载新弹幕
    _loadDanmakusForFrame();
    
    // 更新滚动弹幕位置
    for (final track in _activeTracks) {
      if (!track.isVisible) continue;
      
      // 计算滚动速度
      final speed = _config.speed * 150 * 0.016;
      
      if (track.danmaku.mode == DanmakuMode.ltr) {
        track.x += speed;
      } else {
        track.x -= speed;
      }
      
      // 检查是否移出屏幕
      if (track.danmaku.mode == DanmakuMode.ltr) {
        if (track.x > _screenWidth * 1.3) {
          track.isVisible = false;
        }
      } else {
        if (track.x < -_screenWidth * 0.5) {
          track.isVisible = false;
        }
      }
    }
    
    // 更新固定弹幕的可见性
    for (final track in _topTracks) {
      if (track.danmaku.time + (track.danmaku.duration ?? 5) < _currentPosition) {
        track.isVisible = false;
      }
    }
    for (final track in _bottomTracks) {
      if (track.danmaku.time + (track.danmaku.duration ?? 5) < _currentPosition) {
        track.isVisible = false;
      }
    }
    
    // 清理不可见弹幕
    _activeTracks.removeWhere((track) => !track.isVisible);
    _topTracks.removeWhere((track) => !track.isVisible);
    _bottomTracks.removeWhere((track) => !track.isVisible);
    
    notifyListeners();
  }
  
  /// 加载当前帧的弹幕
  void _loadDanmakusForFrame() {
    final loadRange = 0.5; // 提前加载 0.5 秒的弹幕
    
    for (final danmaku in _danmakus) {
      if (danmaku.time >= _currentPosition && 
          danmaku.time <= _currentPosition + loadRange &&
          !_isDanmakuActive(danmaku)) {
        
        if (!_config.enabled) continue;
        
        _addDanmaku(danmaku);
      }
    }
  }
  
  /// 检查弹幕是否已在轨道上
  bool _isDanmakuActive(Danmaku danmaku) {
    for (final track in _activeTracks) {
      if (identical(track.danmaku, danmaku)) return true;
    }
    for (final track in _topTracks) {
      if (identical(track.danmaku, danmaku)) return true;
    }
    for (final track in _bottomTracks) {
      if (identical(track.danmaku, danmaku)) return true;
    }
    return false;
  }
  
  /// 添加弹幕到轨道
  void _addDanmaku(Danmaku danmaku) {
    switch (danmaku.mode) {
      case DanmakuMode.rtl:
      case DanmakuMode.ltr:
        _addRtlDanmaku(danmaku);
        break;
      case DanmakuMode.top:
        if (_config.showTop) _addFixedDanmaku(danmaku, _topTracks);
        break;
      case DanmakuMode.bottom:
        if (_config.showBottom) _addFixedDanmaku(danmaku, _bottomTracks);
        break;
      case DanmakuMode.special:
        if (_config.showSpecial) _addSpecialDanmaku(danmaku);
        break;
    }
  }
  
  /// 添加滚动弹幕
  void _addRtlDanmaku(Danmaku danmaku) {
    // 查找空闲轨道
    final trackIndex = _findFreeTrack(_activeTracks);
    final yPosition = _config.topMargin * _screenHeight + 
                      trackIndex * 40.0;
    
    // 检查该轨道是否有弹幕即将到达
    final collision = _checkCollision(trackIndex, yPosition, danmaku);
    if (collision != null && collision > _currentPosition) {
      return; // 避免碰撞
    }
    
    final track = DanmakuTrack(
      trackIndex: trackIndex,
      danmaku: danmaku,
      x: danmaku.mode == DanmakuMode.ltr ? -_screenWidth * 0.3 : _screenWidth,
      isVisible: true,
    );
    
    _activeTracks.add(track);
  }
  
  /// 添加固定弹幕（顶部/底部）
  void _addFixedDanmaku(Danmaku danmaku, List<DanmakuTrack> tracks) {
    final trackIndex = _findFreeTrack(tracks);
    
    final track = DanmakuTrack(
      trackIndex: trackIndex,
      danmaku: danmaku,
      x: _screenWidth / 2,
      isVisible: true,
    );
    
    tracks.add(track);
  }
  
  /// 添加特殊弹幕
  void _addSpecialDanmaku(Danmaku danmaku) {
    // TODO: 实现特殊效果弹幕
  }
  
  /// 查找空闲轨道
  int _findFreeTrack(List<DanmakuTrack> tracks) {
    if (tracks.isEmpty) return 0;
    
    // 简单的轨道选择：选择轨道索引最小的可用轨道
    final trackIndex = tracks.fold<int>(0, (prev, track) {
      return track.trackIndex > prev ? track.trackIndex : prev;
    });
    
    return (trackIndex + 1) % 10; // 最多 10 个轨道，循环使用
  }
  
  /// 检查轨道碰撞
  double? _checkCollision(int trackIndex, double y, Danmaku danmaku) {
    // TODO: 实现精确碰撞检测
    return null;
  }
  
  /// 获取当前可见的弹幕
  List<DanmakuTrack> get visibleTracks {
    if (!_config.enabled) return [];
    return [..._activeTracks, ..._topTracks, ..._bottomTracks]
        .where((t) => t.isVisible)
        .toList();
  }
  
  /// 更新配置
  void updateConfig(void Function(DanmakuConfig) updater) {
    updater(_config);
    notifyListeners();
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
