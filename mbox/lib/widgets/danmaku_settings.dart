import 'package:flutter/material.dart';
import '../models/danmaku.dart';

/// 弹幕设置对话框
class DanmakuSettingsDialog extends StatefulWidget {
  final DanmakuConfig config;
  
  const DanmakuSettingsDialog({super.key, required this.config});
  
  @override
  State<DanmakuSettingsDialog> createState() => _DanmakuSettingsDialogState();
}

class _DanmakuSettingsDialogState extends State<DanmakuSettingsDialog> {
  late DanmakuConfig _config;
  
  @override
  void initState() {
    super.initState();
    _config = DanmakuConfig(
      enabled: widget.config.enabled,
      alpha: widget.config.alpha,
      fontSize: widget.config.fontSize,
      speed: widget.config.speed,
      topMargin: widget.config.topMargin,
      bottomMargin: widget.config.bottomMargin,
      showTop: widget.config.showTop,
      showBottom: widget.config.showBottom,
      showSpecial: widget.config.showSpecial,
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('弹幕设置'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text('启用弹幕'),
              value: _config.enabled,
              onChanged: (value) {
                setState(() => _config.enabled = value);
              },
            ),
            const Divider(),
            ListTile(
              title: Text('透明度: ${((_config.alpha / 255) * 100).toInt()}%'),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Slider(
                value: _config.alpha.toDouble(),
                min: 0,
                max: 255,
                divisions: 255,
                onChanged: (value) {
                  setState(() => _config.alpha = value.toInt());
                },
              ),
            ),
            ListTile(
              title: Text('字体大小: ${_config.fontSize.toStringAsFixed(1)}'),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Slider(
                value: _config.fontSize,
                min: 12,
                max: 40,
                divisions: 28,
                onChanged: (value) {
                  setState(() => _config.fontSize = value);
                },
              ),
            ),
            ListTile(
              title: Text('滚动速度: ${_config.speed.toStringAsFixed(1)}x'),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Slider(
                value: _config.speed,
                min: 0.5,
                max: 3.0,
                divisions: 25,
                onChanged: (value) {
                  setState(() => _config.speed = value);
                },
              ),
            ),
            const Divider(),
            SwitchListTile(
              title: const Text('显示顶部弹幕'),
              value: _config.showTop,
              onChanged: (value) {
                setState(() => _config.showTop = value);
              },
            ),
            SwitchListTile(
              title: const Text('显示底部弹幕'),
              value: _config.showBottom,
              onChanged: (value) {
                setState(() => _config.showBottom = value);
              },
            ),
            SwitchListTile(
              title: const Text('显示特殊弹幕'),
              value: _config.showSpecial,
              onChanged: (value) {
                setState(() => _config.showSpecial = value);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _config),
          child: const Text('确定'),
        ),
      ],
    );
  }
}
