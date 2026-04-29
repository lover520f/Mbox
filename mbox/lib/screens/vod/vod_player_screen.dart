import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart' as video;
import '../../models/vod.dart' hide Sub, Danmaku;
import '../../models/sub.dart';
import '../../models/danmaku.dart';
import '../../provider/player_provider.dart';
import '../../utils/device_utils.dart';
import '../../utils/log_utils.dart';
import '../../utils/danmaku_controller.dart';
import '../../widgets/danmaku_overlay.dart';
import '../../widgets/danmaku_settings.dart';

/// 点播播放器页面
class VodPlayerScreen extends StatefulWidget {
  const VodPlayerScreen({super.key});

  @override
  State<VodPlayerScreen> createState() => _VodPlayerScreenState();
}

class _VodPlayerScreenState extends State<VodPlayerScreen> {
  video.VideoController? _videoController;
  Player? _player;
  
  Vod? _vod;
  int _episodeIndex = 0;
  String? _videoUrl;
  
  // 弹幕控制器
  DanmakuController? _danmakuController;
  
  bool _showControls = true;
  Timer? _hideTimer;
  bool _isBuffering = true;
  String? _errorMessage;
  
  // 播放控制
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  double _volume = 1.0;
  double _brightness = 1.0;
  double _playbackSpeed = 1.0;
  
  // 字幕和弹幕
  List<Sub> _subtitles = [];
  List<Danmaku> _danmakus = [];
  bool _showSubtitles = true;
  bool _showDanmakus = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = Get.arguments as Map<String, dynamic>?;
    if (args != null) {
      _vod = args['vod'] as Vod?;
      _episodeIndex = args['episodeIndex'] as int? ?? 0;
      _videoUrl = args['url'] as String?;
    }
    
    if (_videoUrl != null) {
      _initPlayer();
    }
  }

  Future<void> _initPlayer() async {
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

      _player!.stream.buffer.listen((duration) {
        setState(() {
          _isBuffering = duration != Duration.zero;
        });
      });

      _player!.stream.position.listen((position) {
        setState(() {
          _position = position;
        });
        // 同步弹幕进度
        _danmakuController?.seekTo(position.inMilliseconds / 1000.0);
      });

      _player!.stream.duration.listen((duration) {
        setState(() {
          _duration = duration;
        });
      });

      // 开始播放
      await _player!.open(
        Media(_videoUrl!),
        play: true,
      );
      
      // 设置弹幕屏幕尺寸
      final size = MediaQuery.of(context).size;
      _danmakuController?.setScreenSize(size.width, size.height);
      
      // 启动弹幕
      _danmakuController?.play();
      
      // 加载弹幕（如果有）
      _loadDanmaku();

      _startHideTimer();
    } catch (e) {
      setState(() {
        _errorMessage = '播放失败：$e';
      });
      Log.e('Player init error: $e');
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
      _danmakuController?.pause();
    } else {
      await _player!.play();
      _danmakuController?.play();
    }
    _startHideTimer();
  }

  Future<void> _seek(Duration position) async {
    if (_player == null) return;
    await _player!.seek(position);
    _startHideTimer();
  }

  Future<void> _skip({bool forward = true}) async {
    final skipDuration = const Duration(seconds: 10);
    final newPosition = forward 
        ? _position + skipDuration 
        : _position - skipDuration;
    await _seek(newPosition < Duration.zero ? Duration.zero : (newPosition > _duration ? _duration : newPosition));
  }

  void _nextEpisode() {
    final args = Get.arguments as Map<String, dynamic>?;
    final episodeCount = args?['episodeCount'] as int? ?? 1;
    
    if (_episodeIndex < episodeCount - 1) {
      // 切换到下一集
      final nextIndex = _episodeIndex + 1;
      // TODO: 获取下一集的 URL 并重新加载
      Get.snackbar('提示', '切换到第${nextIndex + 1}集');
    } else {
      Get.snackbar('提示', '已经是最新一集');
    }
  }

  void _prevEpisode() {
    if (_episodeIndex > 0) {
      // 切换到上一集
      final prevIndex = _episodeIndex - 1;
      // TODO: 获取上一集的 URL 并重新加载
      Get.snackbar('提示', '切换到第${prevIndex + 1}集');
    } else {
      Get.snackbar('提示', '已经是第一集');
    }
  }

  void _showSpeedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('播放速度'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [0.5, 0.75, 1.0, 1.25, 1.5, 2.0, 2.5, 3.0, 4.0, 5.0, 6.0, 8.0, 10.0].map((speed) {
            return ListTile(
              title: Text('${speed}x'),
              onTap: () {
                _player?.setRate(speed);
                setState(() {
                  _playbackSpeed = speed;
                });
                Get.back();
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showSubtitleDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('字幕'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('关闭'),
              onTap: () {
                setState(() {
                  _showSubtitles = false;
                });
                Get.back();
              },
            ),
            ..._subtitles.map((sub) => ListTile(
              title: Text(sub.label ?? '字幕'),
              onTap: () {
                // TODO: 切换字幕
                setState(() {
                  _showSubtitles = true;
                });
                Get.back();
              },
            )),
          ],
        ),
      ),
    );
  }

  void _showDanmakuDialog() async {
    if (_danmakuController == null) return;
    
    final result = await showDialog<DanmakuConfig>(
      context: context,
      builder: (context) => DanmakuSettingsDialog(
        config: _danmakuController!.configCopy,
      ),
    );
    
    if (result != null) {
      _danmakuController!.setConfig(result);
    }
  }
  
  void _loadDanmaku() async {
    if (_danmakuController == null || _videoUrl == null) return;
    
    // TODO: 从播放器 URL 推断弹幕 URL，或从配置中获取
    // 示例：https://example.com/video.mp4 -> https://example.com/danmaku.xml
    try {
      final danmakuUrl = _videoUrl!.replaceAll('.mp4', '.xml').replaceAll('.m3u8', '.xml');
      await _danmakuController!.loadFromUrl(danmakuUrl);
      
      if (mounted) {
        Get.snackbar('弹幕', '加载了${_danmakuController!.danmakuCount}条弹幕');
      }
    } catch (e) {
      Log.e('Load danmaku error: $e');
      // 静默失败，不显示错误
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isTV = false; // DeviceUtils 已移除
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: _videoUrl == null
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)))
              : Stack(
                  children: [
                    // 视频画面
                    Center(
                      child: _videoController != null
                          ? Stack(
                              children: [
                                video.Video(controller: _videoController!),
                                // 弹幕覆盖层
                                DanmakuOverlay(controller: _danmakuController!),
                              ],
                            )
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
                        onDoubleTap: () {
                          // 双击快进/快退逻辑可以在这里实现
                        },
                        child: Container(
                          color: Colors.transparent,
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
                      
                      // 底部控制栏
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: _buildBottomBar(isTV),
                      ),
                      
                      // 左侧暂停按钮
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
                  _vod?.name ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '第${_episodeIndex + 1}集',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(_showDanmakus ? Icons.live_tv : Icons.live_tv_outlined),
            color: Colors.white,
            onPressed: () {
              if (_danmakuController != null && !_danmakuController!.isLoaded) {
                _loadDanmaku();
              } else {
                _showDanmakuDialog();
              }
            },
          ),
          IconButton(
            icon: Icon(_showSubtitles ? Icons.subtitles : Icons.subtitles_outlined),
            color: Colors.white,
            onPressed: _showSubtitleDialog,
          ),
          IconButton(
            icon: Icon(Icons.settings),
            color: Colors.white,
            onPressed: _showSpeedDialog,
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 进度条
          _buildProgressBar(),
          const SizedBox(height: 8),
          
          // 控制按钮
          Row(
            children: [
              // 上一集
              IconButton(
                icon: const Icon(Icons.skip_previous),
                color: Colors.white,
                iconSize: 32,
                onPressed: _prevEpisode,
              ),
              
              // 播放/暂停
              IconButton(
                icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                color: Colors.white,
                iconSize: 40,
                onPressed: _togglePlay,
              ),
              
              // 下一集
              IconButton(
                icon: const Icon(Icons.skip_next),
                color: Colors.white,
                iconSize: 32,
                onPressed: _nextEpisode,
              ),
              
              const SizedBox(width: 16),
              
              // 快退
              IconButton(
                icon: const Icon(Icons.replay_10),
                color: Colors.white,
                iconSize: 28,
                onPressed: () => _skip(forward: false),
              ),
              
              // 快进
              IconButton(
                icon: const Icon(Icons.forward_10),
                color: Colors.white,
                iconSize: 28,
                onPressed: () => _skip(forward: true),
              ),
              
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // 字幕
                    IconButton(
                      icon: Icon(_showSubtitles ? Icons.subtitles : Icons.subtitles_off),
                      color: Colors.white,
                      onPressed: _showSubtitleDialog,
                    ),
                    
                    // 弹幕
                    IconButton(
                      icon: Icon(_showDanmakus ? Icons.comment : Icons.chat_bubble_outline),
                      color: Colors.white,
                      onPressed: _showDanmakuDialog,
                    ),
                    
                    // 播放速度
                    PopupMenuButton<double>(
                      icon: const Icon(Icons.speed, color: Colors.white),
                      onSelected: (speed) {
                        _player?.setRate(speed);
                        setState(() {
                          _playbackSpeed = speed;
                        });
                      },
                      itemBuilder: (context) => [0.5, 0.75, 1.0, 1.25, 1.5, 2.0]
                          .map((speed) => PopupMenuItem(
                                value: speed,
                                child: Text('${speed}x'),
                              ))
                          .toList(),
                    ),
                    
                    // 选集
                    IconButton(
                      icon: const Icon(Icons.list),
                      color: Colors.white,
                      onPressed: _showEpisodeList,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Row(
      children: [
        Text(
          _formatDuration(_position),
          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              activeTrackColor: Theme.of(context).primaryColor,
              inactiveTrackColor: Colors.white.withOpacity(0.3),
              thumbColor: Theme.of(context).primaryColor,
            ),
            child: Slider(
              value: _position.inSeconds.toDouble(),
              min: 0,
              max: _duration.inSeconds.toDouble().clamp(1, double.infinity),
              onChanged: (value) {
                setState(() {
                  _position = Duration(seconds: value.toInt());
                });
              },
              onChangeEnd: (value) {
                _seek(Duration(seconds: value.toInt()));
              },
            ),
          ),
        ),
        Text(
          _formatDuration(_duration),
          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
        ),
      ],
    );
  }

  void _showEpisodeList() {
    // TODO: 显示选集列表
    Get.snackbar('提示', '选集列表开发中');
  }

  @override
  void initState() {
    super.initState();
    _danmakuController = DanmakuController();
  }
  
  @override
  void dispose() {
    _hideTimer?.cancel();
    _danmakuController?.dispose();
    _player?.dispose();
    _videoController = null;
    super.dispose();
  }
}
