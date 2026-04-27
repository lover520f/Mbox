import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../provider/config_provider.dart';
import '../../provider/app_provider.dart';
import '../../utils/log_utils.dart';

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
            title: '配置管理',
            children: [
              ListTile(
                leading: const Icon(Icons.folder_open, color: Colors.blue),
                title: const Text('加载配置'),
                subtitle: const Text('从 URL、本地文件或 JSON 加载'),
                onTap: _showLoadConfigDialog,
              ),
              ListTile(
                leading: const Icon(Icons.info, color: Colors.green),
                title: const Text('当前配置'),
                subtitle: Consumer<ConfigProvider>(
                  builder: (context, provider, child) {
                    final name = provider.configName ?? '未加载';
                    final count = provider.config?.sites.length ?? 0;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, overflow: TextOverflow.ellipsis),
                        if (count > 0)
                          Text(
                            '$count 个站点',
                            style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                          ),
                      ],
                    );
                  },
                ),
                trailing: Consumer<ConfigProvider>(
                  builder: (context, provider, child) {
                    if (provider.config != null) {
                      return IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: _confirmClearConfig,
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
              Consumer<ConfigProvider>(
                builder: (context, provider, child) {
                  if (provider.config != null && provider.config!.sites.isNotEmpty) {
                    return ListTile(
                      leading: const Icon(Icons.swap_horiz, color: Colors.orange),
                      title: const Text('站点切换'),
                      subtitle: Text('当前：${provider.config?.sites.first.name ?? "未知"}'),
                      onTap: () => _showSiteSelectDialog(),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
          
          _buildSection(
            title: '播放设置',
            children: [
              ListTile(
                leading: const Icon(Icons.hd, color: Colors.purple),
                title: const Text('播放器设置'),
                subtitle: const Text('画质、音效、字幕等'),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('播放器设置开发中')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.history, color: Colors.teal),
                title: const Text('观看历史'),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('观看历史开发中')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.favorite_border, color: Colors.red),
                title: const Text('我的收藏'),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('收藏功能开发中')),
                  );
                },
              ),
            ],
          ),
          
          _buildSection(
            title: '界面设置',
            children: [
              Consumer<AppProvider>(
                builder: (context, appProvider, child) {
                  return SwitchListTile(
                    secondary: const Icon(Icons.brightness_4, color: Colors.yellow),
                    title: const Text('暗色模式'),
                    value: appProvider.isDarkMode,
                    onChanged: (value) {
                      appProvider.toggleDarkMode();
                    },
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.language, color: Colors.cyan),
                title: const Text('语言'),
                subtitle: const Text('简体中文'),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('语言设置开发中')),
                  );
                },
              ),
            ],
          ),
          
          _buildSection(
            title: '网络设置',
            children: [
              ListTile(
                leading: const Icon(Icons.dns, color: Colors.indigo),
                title: const Text('DoH 设置'),
                subtitle: const Text('DNS over HTTPS'),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('DoH 设置开发中')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.security, color: Colors.deepOrange),
                title: const Text('代理设置'),
                subtitle: const Text('HTTP/SOCKS 代理'),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('代理设置开发中')),
                  );
                },
              ),
            ],
          ),
          
          _buildSection(
            title: '关于',
            children: [
              ListTile(
                leading: const Icon(Icons.info_outline, color: Colors.grey),
                title: const Text('版本信息'),
                subtitle: const Text('MBox v1.3.1'),
              ),
              ListTile(
                leading: const Icon(Icons.description, color: Colors.grey),
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
                color: Colors.blue[400],
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
              leading: const Icon(Icons.link, color: Colors.blue),
              title: const Text('URL 配置'),
              subtitle: const Text('输入配置文件的网址'),
              onTap: () {
                Navigator.pop(context);
                _showUrlInputDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.folder, color: Colors.green),
              title: const Text('本地文件'),
              subtitle: const Text('选择本地的配置文件'),
              onTap: () {
                Navigator.pop(context);
                _pickLocalFile();
              },
            ),
            ListTile(
              leading: const Icon(Icons.content_paste, color: Colors.orange),
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
    bool isLoading = false;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('URL 配置'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: '请输入配置 URL',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.link),
                ),
                autofocus: true,
              ),
              if (isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 16.0),
                  child: CircularProgressIndicator(),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: isLoading ? null : () async {
                if (controller.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('请输入 URL')),
                  );
                  return;
                }
                
                setDialogState(() => isLoading = true);
                
                final configProvider = context.read<ConfigProvider>();
                final success = await configProvider.loadConfig(
                  controller.text.trim(),
                  name: 'Remote Config',
                );
                
                if (mounted) {
                  Navigator.pop(context);
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('配置加载成功！'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('加载失败：${configProvider.error ?? "未知错误"}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: isLoading ? const SizedBox() : const Text('确定'),
            ),
          ],
        ),
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
              prefixIcon: Icon(Icons.code),
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
              if (controller.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('请输入 JSON 内容')),
                );
                return;
              }
              
              final configProvider = context.read<ConfigProvider>();
              final success = await configProvider.parseConfigString(controller.text.trim());
              
              if (mounted) {
                Navigator.pop(context);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('配置解析成功！'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('解析失败：${configProvider.error ?? "未知错误"}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
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
        final configProvider = context.read<ConfigProvider>();
        final success = await configProvider.loadConfig(
          result.files.single.path!,
          name: 'Local Config',
        );
        
        if (mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('配置加载成功！'),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('加载失败：${configProvider.error ?? "未知错误"}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('选择文件失败：$e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _confirmClearConfig() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清除配置'),
        content: const Text('确定要清除当前配置吗？清除后将无法使用点播和直播功能。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<ConfigProvider>().clearConfig();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('配置已清除'),
                  backgroundColor: Colors.orange,
                ),
              );
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

  void _showSiteSelectDialog() {
    final configProvider = context.read<ConfigProvider>();
    final config = configProvider.config;
    
    if (config == null || config.sites.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('没有可用的站点')),
      );
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择站点'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: config.sites.length,
            itemBuilder: (context, index) {
              final site = config.sites[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: Text('${index + 1}'),
                ),
                title: Text(site.name),
                subtitle: Text('类型：${_getTypeName(site.type)}'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('已选择：${site.name}')),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  String _getTypeName(int type) {
    switch (type) {
      case 0: return 'JAR';
      case 1: return 'XML';
      case 2: return '音频';
      case 3: return 'JSON';
      case 4: return 'PHP';
      case 5: return 'Py';
      case 6: return 'Pet-Tools';
      default: return '未知';
    }
  }
}
