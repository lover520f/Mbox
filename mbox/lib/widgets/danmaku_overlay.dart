import 'package:flutter/material.dart';
import '../utils/danmaku_controller.dart';
import '../models/danmaku.dart';

/// 弹幕覆盖层
class DanmakuOverlay extends StatelessWidget {
  final DanmakuController controller;
  
  const DanmakuOverlay({super.key, required this.controller});
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        if (!controller.config.enabled) {
          return const SizedBox.shrink();
        }
        
        final tracks = controller.visibleTracks;
        
        return Stack(
          clipBehavior: Clip.none,
          children: tracks.map((track) {
            return _buildDanmaku(track, controller);
          }).toList(),
        );
      },
    );
  }
  
  /// 构建弹幕 Widget
  Widget _buildDanmaku(DanmakuTrack track, DanmakuController controller) {
    final danmaku = track.danmaku;
    final config = controller.config;
    
    // 计算 Y 位置
    final y = _calculateY(track, config, controller.screenHeight);
    
    // 计算弹幕颜色（应用透明度）
    final baseColor = Color(danmaku.color);
    final color = baseColor.withAlpha(config.alpha);
    
    // 计算字体大小（应用配置）
    final fontSize = (config.fontSize * (danmaku.fontSize ?? 25) / 25);
    
    return Positioned(
      left: track.x,
      top: y,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.4),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: Colors.black.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Text(
          danmaku.text,
          style: TextStyle(
            fontSize: fontSize,
            fontFamily: 'sans-serif',
            color: color,
            fontWeight: FontWeight.bold,
            height: 1.2,
            shadows: [
              Shadow(
                offset: const Offset(1, 1),
                blurRadius: 3,
                color: Colors.black54,
              ),
              Shadow(
                offset: const Offset(-1, -1),
                blurRadius: 3,
                color: Colors.black26,
              ),
            ],
          ),
          maxLines: 1,
          overflow: TextOverflow.clip,
        ),
      ),
    );
  }
  
  /// 计算 Y 坐标
  double _calculateY(DanmakuTrack track, DanmakuConfig config, double screenHeight) {
    final trackHeight = 40.0;
    
    switch (track.danmaku.mode) {
      case DanmakuMode.rtl:
      case DanmakuMode.ltr:
        return config.topMargin * screenHeight + 
               (track.trackIndex % 10) * trackHeight;
      
      case DanmakuMode.top:
        return config.topMargin * screenHeight + 
               (track.trackIndex % 10) * trackHeight;
      
      case DanmakuMode.bottom:
        return screenHeight * (1 - config.bottomMargin) - 
               ((track.trackIndex % 10) + 1) * trackHeight;
      
      case DanmakuMode.special:
        return screenHeight / 2 + (track.trackIndex - 5) * trackHeight;
    }
  }
}
