import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart' as video;
import '../../models/live.dart';
import '../../utils/device_utils.dart';
import '../../utils/log_utils.dart';

/// 直播播放器页面
class LivePlayerScreen extends StatefulWidget {
  const LivePlayerScreen({super.key});

  @override
  State<LivePlayerScreen> createState() => _LivePlayerScreenState();
}

class _LivePlayerScreenState extends State<LivePlayerScreen> {
  video.VideoController? _videoController;
  Player? _player;
  
  Channel? _channel;
  Group? _group;
  
  bool _showControls = true;
  Timer? _hideTimer;
  bool _isBuffering = true;
  String? _errorMessage;
  
  // 播放控制
  bool _isPlaying = false;
  int _currentUrlIndex = 0;
  List<String>? _currentUrls;
  
  // EPG 信息
  bool _showEPG = false;
  String? _currentProgram;
  String? _nextProgram;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = Get.arguments as Map<String, dynamic>?;
    if (args != null) {
      _channel = args['channel'] as Channel?;
      _group = args['group'] as Group?;
      
      if (_channel != null) {
        _currentUrls = _channel!.urls;
        if (_currentUrls != null && _currentUrls!.isNotEmpty) {
          _initPlayer();
        }
      }
    }
  }

  Future<void> _initPlayer() async {
    if (_currentUrls == null || _currentUrls!.isEmpty) {
      setState(() {
        _errorMessage = '无播放地址';
      });
      return;
    }

    try {
      _player = Player();

      _videoController = video.VideoController(
        _player!,
        configuration: const video.VideoControllerConfiguration(
          enableHardwareAcceleration: true,
        ),
      );

      // 设置监听器
      _player!.stream.playing.listen((playing) {
        setState(() {
          _isPlaying = playing;
        });
      });

      _player!.stream.buffer.listen((buffering) {
        setState(() {
          _isBuffering = buffering;
        });
      });

      // 开始播放
      final url = _currentUrls![_currentUrlIndex];
      await _player!.open(
        Media(url),
        play: true,
      );

      _startHideTimer();
      _parseEPG();
    } catch (e) {
      setState(() {
        _errorMessage = '播放失败：$e';
      });
      Log.e('Live player init error: $e');
    }
  }

  void _parseEPG() {
    // TODO: 解析 EPG 信息
    if (_channel?.epg != null) {
      setState(() {
        _currentProgram = _channel!.epg;
      });
    }
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    setState(() {
      _showControls = true;
    });
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls) {
      _startHideTimer();
    } else {
      _hideTimer?.cancel();
    }
  }

  Future<void> _togglePlay() async {
    if (_player == null) return;
    
    if (_isPlaying) {
      await _player!.pause();
    } else {
      await _player!.play();
    }
    _startHideTimer();
  }

  void _switchSource() {
    if (_currentUrls == null || _currentUrls!.length <= 1) {
      Get.snackbar('提示', '只有一个播放源');
      return;
    }
    
    setState(() {
      _currentUrlIndex = (_currentUrlIndex + 1) % _currentUrls!.length;
      _isBuffering = true;
    });
    
    // 重新加载
    _player?.open(
      Media(_currentUrls![_currentUrlIndex]),
      play: true,
    );
    
    Get.snackbar(
      '切换线路',
      '已切换到线路 ${_currentUrlIndex + 1}',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _nextChannel() {
    if (_group == null || _group!.channel == null) return;
    
    final channels = _group!.channel!;
    final currentIndex = channels.indexWhere((c) => c.name == _channel?.name);
    
    if (currentIndex < 0 || currentIndex >= channels.length - 1) {
      Get.snackbar('提示', '已经是最后一个频道');
      return;
    }
    
    final nextChannel = channels[currentIndex + 1];
    Navigator.pop(context);
    
    // 跳转到下一个频道播放
    Get.toNamed('/live/player', arguments: {
      'channel': nextChannel,
      'group': _group,
    });
  }

  void _prevChannel() {
    if (_group == null || _group!.channel == null) return;
    
    final channels = _group!.channel!;
    final currentIndex = channels.indexWhere((c) => c.name == _channel?.name);
    
    if (currentIndex <= 0) {
      Get.snackbar('提示', '已经是第一个频道');
      return;
    }
    
    final prevChannel = channels[currentIndex - 1];
    Navigator.pop(context);
    
    Get.toNamed('/live/player', arguments: {
      'channel': prevChannel,
      'group': _group,
    });
  }

  void _toggleEPG() {
    setState(() {
      _showEPG = !_showEPG;
    });
    _startHideTimer();
  }

  @override
  Widget build(BuildContext context) {
    final isTV = false; // DeviceUtils.isTV() 是异步的，已经移除此功能
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: _channel == null
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)))
              : Stack(
                  children: [
                    // 视频画面
                    Center(
                      child: _videoController != null
                          ? video.Video(controller: _videoController!)
                          : const CircularProgressIndicator(),
                    ),
                    
                    // 加载指示
                    if (_isBuffering)
                      const Center(
                        child: CircularProgressIndicator(),
                      ),
                    
                    // 点击热区
                    Positioned.fill(
                      child: GestureDetector(
                        onTap: _toggleControls,
                        child: Container(
                          color: Colors.transparent,
                        ),
                      ),
                    ),
                    
                    // EPG 信息覆盖层
                    if (_showEPG && _currentProgram != null)
                      Positioned(
                        top: isTV ? 80 : 60,
                        left: 16,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _channel!.name ?? '',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '正在播放：$_currentProgram',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 14,
                                ),
                              ),
                              if (_nextProgram != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  '接下来：$_nextProgram',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    
                    // 控制栏
                    if (_showControls) ...[
                      // 顶部栏
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: _buildTopBar(isTV),
                      ),
                      
                      // 底部信息栏
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: _buildBottomBar(isTV),
                      ),
                      
                      // 中央播放按钮
                      if (!_isPlaying)
                        Positioned.fill(
                          child: Center(
                            child: IconButton(
                              icon: const Icon(Icons.play_arrow, size: 64),
                              color: Colors.white,
                              onPressed: _togglePlay,
                            ),
                          ),
                        ),
                    ],
                    
                    // 线路切换提示
                    Positioned(
                      top: isTV ? 80 : 60,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '线路 ${_currentUrlIndex + 1}/${_currentUrls?.length ?? 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildTopBar(bool isTV) {
    return Container(
      padding: EdgeInsets.only(
        top: isTV ? 32 : 16,
        left: 16,
        right: 16,
        bottom: 8,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.8),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            color: Colors.white,
            onPressed: () => Get.back(),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _channel?.name ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_currentProgram != null)
                  Text(
                    _currentProgram!,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(_showEPG ? Icons.info : Icons.info_outline),
            color: Colors.white,
            onPressed: _toggleEPG,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(bool isTV) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: isTV ? 32 : 16,
        top: 8,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withOpacity(0.8),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        children: [
          // 上一频道
          IconButton(
            icon: const Icon(Icons.skip_previous),
            color: Colors.white,
            iconSize: 32,
            onPressed: _prevChannel,
          ),
          
          // 播放/暂停
          IconButton(
            icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
            color: Colors.white,
            iconSize: 40,
            onPressed: _togglePlay,
          ),
          
          // 下一频道
          IconButton(
            icon: const Icon(Icons.skip_next),
            color: Colors.white,
            iconSize: 32,
            onPressed: _nextChannel,
          ),
          
          const Spacer(),
          
          // 切换线路
          if (_currentUrls != null && _currentUrls!.length > 1)
            ElevatedButton.icon(
              icon: const Icon(Icons.swap_horiz),
              label: Text('线路 ${_currentUrlIndex + 1}'),
              onPressed: _switchSource,
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _player?.dispose();
    super.dispose();
  }
}
