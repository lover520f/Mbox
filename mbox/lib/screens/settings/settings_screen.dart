import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../provider/config_provider.dart';
import '../../provider/app_provider.dart';
import '../../config/app_config.dart';

/// 设置页面
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: ListView(
        children: [
          _buildSection(
            title: '配置',
            children: [
              ListTile(
                leading: const Icon(Icons.folder_open),
                title: const Text('加载配置'),
                subtitle: const Text('从 URL 或本地文件加载配置'),
                onTap: () => _showLoadConfigDialog(),
              ),
              ListTile(
                leading: const Icon(Icons.info),
                title: const Text('当前配置'),
                subtitle: Consumer<ConfigProvider>(
                  builder: (context, provider, child) {
                    return Text(
                      provider.configName ?? '未加载',
                      overflow: TextOverflow.ellipsis,
                    );
                  },
                ),
              ),
              if (context.watch<ConfigProvider>().config != null)
                ListTile(
                  leading: const Icon(Icons.delete_outline),
                  title: const Text('清除配置'),
                  onTap: () => _confirmClearConfig(),
                ),
            ],
          ),
          
          _buildSection(
            title: '播放',
            children: [
              ListTile(
                leading: const Icon(Icons.hd),
                title: const Text('播放器设置'),
                subtitle: const Text('画质、音效、字幕等'),
                onTap: () {
                  // TODO: 打开播放器设置页面
                },
              ),
              ListTile(
                leading: const Icon(Icons.history),
                title: const Text('观看历史'),
                onTap: () {
                  // TODO: 打开历史记录页面
                },
              ),
              ListTile(
                leading: const Icon(Icons.favorite_border),
                title: const Text('我的收藏'),
                onTap: () {
                  // TODO: 打开收藏页面
                },
              ),
            ],
          ),
          
          _buildSection(
            title: '界面',
            children: [
              Consumer<AppProvider>(
                builder: (context, appProvider, child) {
                  return SwitchListTile(
                    leading: const Icon(Icons.dark_mode),
                    title: const Text('暗色模式'),
                    value: appProvider.isDarkMode,
                    onChanged: (value) {
                      appProvider.toggleDarkMode();
                    },
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.language),
                title: const Text('语言'),
                subtitle: const Text('简体中文'),
                onTap: () {
                  // TODO: 语言选择
                },
              ),
            ],
          ),
          
          _buildSection(
            title: '网络',
            children: [
              ListTile(
                leading: const Icon(Icons.dns),
                title: const Text('DoH 设置'),
                subtitle: const Text('DNS over HTTPS'),
                onTap: () {
                  // TODO: DoH 配置
                },
              ),
              ListTile(
                leading: const Icon(Icons.security),
                title: const Text('代理设置'),
                subtitle: const Text('HTTP/SOCKS 代理'),
                onTap: () {
                  // TODO: 代理配置
                },
              ),
            ],
          ),
          
          _buildSection(
            title: '关于',
            children: [
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('版本信息'),
                subtitle: const Text('MBox 1.0.0'),
              ),
              ListTile(
                leading: const Icon(Icons.description),
                title: const Text('开源协议'),
                subtitle: const Text('MIT License'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  void _showLoadConfigDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('加载配置'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('URL 配置'),
              subtitle: const Text('输入配置文件的网址'),
              onTap: () {
                Navigator.pop(context);
                _showUrlInputDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.folder),
              title: const Text('本地文件'),
              subtitle: const Text('选择本地的配置文件'),
              onTap: () {
                Navigator.pop(context);
                _pickLocalFile();
              },
            ),
            ListTile(
              leading: const Icon(Icons.content_paste),
              title: const Text('粘贴 JSON'),
              subtitle: const Text('直接粘贴配置内容'),
              onTap: () {
                Navigator.pop(context);
                _showJsonInputDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showUrlInputDialog() {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('URL 配置'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: '请输入配置 URL',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await context.read<ConfigProvider>().loadConfig(
                    controller.text,
                    name: 'Remote Config',
                  );
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showJsonInputDialog() {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('粘贴 JSON 配置'),
        content: SizedBox(
          width: double.maxFinite,
          child: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: '请粘贴 JSON 配置内容',
              border: OutlineInputBorder(),
            ),
            maxLines: 10,
            autofocus: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await context
                  .read<ConfigProvider>()
                  .parseConfigString(controller.text);
              
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('配置解析成功')),
                );
              }
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickLocalFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      
      if (result != null && result.files.single.path != null) {
        await context.read<ConfigProvider>().loadConfig(
              result.files.single.path!,
              name: 'Local Config',
            );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('选择文件失败：$e')),
        );
      }
    }
  }

  void _confirmClearConfig() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清除配置'),
        content: const Text('确定要清除当前配置吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<ConfigProvider>().clearConfig();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('清除'),
          ),
        ],
      ),
    );
  }
}
