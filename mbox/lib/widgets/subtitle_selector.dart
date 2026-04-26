import 'package:flutter/material.dart';
import '../../player/subtitle_controller.dart';

/// 字幕选择组件
class SubtitleSelector extends StatelessWidget {
  final SubtitleController controller;
  final Function(int)? onSubtitleChanged;
  final List<dynamic> subtitleTracks;

  const SubtitleSelector({
    super.key,
    required this.controller,
    this.onSubtitleChanged,
    required this.subtitleTracks,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: subtitleTracks.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return ListTile(
            title: const Text('关闭'),
            onTap: () {
              controller.setSubtitle(null);
              onSubtitleChanged?.call(-1);
              Navigator.pop(context);
            },
          );
        }

        final track = subtitleTracks[index - 1];
        final title = track['title'] ?? track['label'] ?? '字幕 ${index}';
        final lang = track['language'] ?? '';

        return ListTile(
          title: Text(title),
          subtitle: lang.isNotEmpty ? Text(lang) : null,
          onTap: () {
            // TODO: 切换字幕
            Navigator.pop(context);
          },
        );
      },
    );
  }
}

/// 字幕设置面板
class SubtitleSettingsPanel extends StatelessWidget {
  final double fontSize;
  final Color textColor;
  final Color backgroundColor;
  final Function(double)? onFontSizeChanged;

  const SubtitleSettingsPanel({
    super.key,
    this.fontSize = 18,
    this.textColor = Colors.white,
    this.backgroundColor = Colors.black54,
    this.onFontSizeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const ListTile(
          title: Text('字幕设置'),
        ),
        ListTile(
          title: const Text('字体大小'),
          subtitle: Slider(
            value: fontSize,
            min: 12,
            max: 32,
            divisions: 4,
            label: fontSize.round().toString(),
            onChanged: (value) {
              onFontSizeChanged?.call(value);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('关闭'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
