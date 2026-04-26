import 'package:flutter/material.dart';

/// 插件页面（预留）
class PluginScreen extends StatelessWidget {
  const PluginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('插件'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.extension,
              size: 80,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 24),
            const Text(
              '插件功能开发中',
              style: TextStyle(
                fontSize: 20,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '即将支持更多扩展功能',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
