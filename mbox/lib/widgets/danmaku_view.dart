import 'package:flutter/material.dart';
import 'package:danmaku/danmaku.dart' as danmaku;
import '../player/danmaku_controller.dart';

/// 弹幕视图组件
class DanmakuView extends StatefulWidget {
  final DanmakuController? controller;
  final bool visible;
  final Size viewportSize;

  const DanmakuView({
    super.key,
    required this.controller,
    this.visible = true,
    required this.viewportSize,
  });

  @override
  State<DanmakuView> createState() => _DanmakuViewState();
}

class _DanmakuViewState extends State<DanmakuView> {
  late danmaku.DanmakuController _danmakuController;

  @override
  void initState() {
    super.initState();
    _initDanmaku();
  }

  void _initDanmaku() {
    _danmakuController = danmaku.DanmakuController();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.visible) {
      return const SizedBox.shrink();
    }

    return ClipRect(
      child: Stack(
        children: [
          Positioned.fill(
            child: danmaku.Danmaku(
              controller: _danmakuController,
              options: danmaku.DanmakuOptions(
                maxLines: 10,
                showLines: 10,
                area: 1.0,
                speed: const Duration(seconds: 8),
                maxStack: 10,
                direction: const danmaku.DanmakuDirection(
                  start: danmaku.AxisDirection.start,
                  end: danmaku.AxisDirection.end,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _danmakuController.dispose();
    super.dispose();
  }
}

/// 字幕显示组件
class SubtitleView extends StatelessWidget {
  final String? subtitle;
  final double fontSize;
  final Color textColor;
  final Color backgroundColor;
  final EdgeInsets padding;

  const SubtitleView({
    super.key,
    this.subtitle,
    this.fontSize = 18,
    this.textColor = Colors.white,
    this.backgroundColor = Colors.black54,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  });

  @override
  Widget build(BuildContext context) {
    if (subtitle == null || subtitle!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: 0,
      right: 0,
      bottom: 80,
      child: Container(
        padding: padding,
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(4),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Text(
            subtitle!,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: fontSize,
              color: textColor,
              fontWeight: FontWeight.w500,
              shadows: [
                Shadow(
                  color: Colors.black,
                  offset: const Offset(1, 1),
                  blurRadius: 2,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 弹幕输入组件
class DanmakuInput extends StatefulWidget {
  final Function(String)? onSend;

  const DanmakuInput({
    super.key,
    this.onSend,
  });

  @override
  State<DanmakuInput> createState() => _DanmakuInputState();
}

class _DanmakuInputState extends State<DanmakuInput> {
  final TextEditingController _controller = TextEditingController();
  bool _isEditing = false;

  @override
  Widget build(BuildContext context) {
    if (!_isEditing) {
      return Positioned(
        bottom: 16,
        left: 16,
        child: ElevatedButton.icon(
          icon: const Icon(Icons.edit, size: 20),
          label: const Text('发弹幕'),
          onPressed: () {
            setState(() {
              _isEditing = true;
            });
          },
        ),
      );
    }

    return Positioned(
      bottom: 16,
      left: 16,
      right: 100,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: '发送弹幕...',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              autocorrect: false,
              enableSuggestions: false,
              maxLines: 1,
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              if (_controller.text.isNotEmpty) {
                widget.onSend?.call(_controller.text);
                _controller.clear();
              }
              setState(() {
                _isEditing = false;
              });
            },
            child: const Text('发送'),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              setState(() {
                _isEditing = false;
              });
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
