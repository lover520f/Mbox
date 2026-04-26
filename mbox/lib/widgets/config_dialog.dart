import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/config_provider.dart';
import '../utils/log_utils.dart';

/// 配置加载对话框
class ConfigLoadDialog extends StatefulWidget {
  const ConfigLoadDialog({super.key});

  @override
  State<ConfigLoadDialog> createState() => _ConfigLoadDialogState();
}

class _ConfigLoadDialogState extends State<ConfigLoadDialog> {
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final configProvider = context.read<ConfigProvider>();
      final url = _urlController.text.trim();
      
      Log.d('Loading config from: $url');
      
      final success = await configProvider.loadConfig(url);
      
      if (success && mounted) {
        Navigator.of(context).pop(true);
        _showSuccessSnackBar();
      } else if (mounted) {
        setState(() {
          _error = '配置加载失败，请检查 URL 是否正确';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '错误：$e';
          _isLoading = false;
        });
      }
    }
  }

  void _showSuccessSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('配置加载成功！'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('加载配置'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '请输入配置接口地址',
              style: TextStyle(fontSize: 14, color: Colors.white70),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _urlController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'http://example.com/config.json',
                hintStyle: TextStyle(color: Colors.white54),
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.link, color: Colors.white54),
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
                errorText: _error,
              ),
              keyboardType: TextInputType.url,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '请输入配置地址';
                }
                if (!value.trim().startsWith('http')) {
                  return '地址必须以 http:// 或 https:// 开头';
                }
                return null;
              },
            ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 16.0),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _loadConfig,
          child: const Text('加载'),
        ),
      ],
    );
  }
}

/// 站点选择对话框
class SourceListDialog extends StatefulWidget {
  const SourceListDialog({super.key});

  @override
  State<SourceListDialog> createState() => _SourceListDialogState();
}

class _SourceListDialogState extends State<SourceListDialog> {
  String? _selectedSiteKey;

  @override
  Widget build(BuildContext context) {
    final configProvider = context.watch<ConfigProvider>();
    final config = configProvider.config;

    if (config == null) {
      return AlertDialog(
        title: const Text('站点列表'),
        content: const Text('请先加载配置'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      );
    }

    return AlertDialog(
      title: const Text('站点列表'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: config.sites.length,
          itemBuilder: (context, index) {
            final site = config.sites[index];
            final isSelected = _selectedSiteKey == site.key;
            
            return Card(
              color: isSelected ? Colors.blue.withOpacity(0.3) : Colors.transparent,
              child: ListTile(
                title: Text(
                  site.name,
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  '类型：${_getTypeName(site.type)}',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                onTap: () {
                  setState(() {
                    _selectedSiteKey = site.key;
                  });
                },
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _selectedSiteKey == null
              ? null
              : () => Navigator.of(context).pop(_selectedSiteKey),
          child: const Text('确定'),
        ),
      ],
    );
  }

  String _getTypeName(int type) {
    switch (type) {
      case 0:
        return 'JAR 爬虫';
      case 1:
        return 'XML 爬虫';
      case 2:
        return '音频爬虫';
      case 3:
        return 'JSON 爬虫';
      case 4:
        return 'PHP 爬虫';
      case 5:
        return 'Py 爬虫';
      case 6:
        return 'Pet-Tools';
      default:
        return '未知';
    }
  }
}
