import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import '../../models/vod_config.dart';
import '../../models/live.dart';
import '../../provider/config_provider.dart';
import '../../utils/device_utils.dart';
import '../../routes/app_routes.dart';

/// 直播页面
class LiveScreen extends StatefulWidget {
  const LiveScreen({super.key});

  @override
  State<LiveScreen> createState() => _LiveScreenState();
}

class _LiveScreenState extends State<LiveScreen> {
  LiveConfig? _liveConfig;
  List<Group> _groups = [];
  bool _isLoading = false;
  String? _errorMessage;
  
  Group? _selectedGroup;
  Channel? _selectedChannel;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadLiveConfig();
  }

  Future<void> _loadLiveConfig() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final configProvider = context.read<ConfigProvider>();
      final config = await configProvider.loadLive();
      
      setState(() {
        _liveConfig = config;
        _groups = config?.groups ?? [];
        if (_groups.isNotEmpty && _selectedGroup == null) {
          _selectedGroup = _groups.first;
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = '加载直播源失败：$e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _playChannel(Channel channel) {
    setState(() {
      _selectedChannel = channel;
    });
    
    Get.toNamed(AppRoutes.livePlayer, arguments: {
      'channel': channel,
      'group': _selectedGroup,
    });
  }

  void _showEPG(Channel channel) {
    // TODO: 显示 EPG
    Get.snackbar('提示', 'EPG 功能开发中');
  }

  @override
  Widget build(BuildContext context) {
    final isTV = DeviceUtils.isTV(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('直播'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLiveConfig,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : _groups.isEmpty
                  ? const Center(child: Text('暂无直播源'))
                  : isTV
                      ? _buildTVLayout()
                      : _buildMobileLayout(),
    );
  }

  Widget _buildTVLayout() {
    return Row(
      children: [
        // 左侧分组列表
        Container(
          width: 150,
          color: Colors.grey[900],
          child: ListView.builder(
            itemCount: _groups.length,
            itemBuilder: (context, index) {
              final group = _groups[index];
              final isSelected = _selectedGroup == group;
              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedGroup = group;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected ? Theme.of(context).primaryColor : null,
                    border: Border(
                      left: BorderSide(
                        color: isSelected ? Colors.white : Colors.transparent,
                        width: 4,
                      ),
                    ),
                  ),
                  child: Text(
                    group.name ?? '分组 $index',
                    style: const TextStyle(fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              );
            },
          ),
        ),
        
        // 右侧频道列表
        Expanded(
          child: _selectedGroup == null
              ? const Center(child: Text('请选择分组'))
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.5,
                  ),
                  itemCount: _selectedGroup?.channel.length ?? 0 ?? 0,
                  itemBuilder: (context, index) {
                    final channel = _selectedGroup!.channel[index];
                    final isSelected = _selectedChannel == channel;
                    return InkWell(
                      onTap: () => _playChannel(channel),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Theme.of(context).primaryColor
                              : Colors.grey[800],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? Colors.white : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.live_tv,
                              size: 32,
                              color: isSelected ? Colors.white : Colors.grey[400],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              channel.name ?? '频道 $index',
                              style: TextStyle(
                                fontSize: 12,
                                color: isSelected ? Colors.white : Colors.grey[300],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        // 分组选择
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _groups.length,
            itemBuilder: (context, index) {
              final group = _groups[index];
              final isSelected = _selectedGroup == group;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(group.name ?? '分组 $index'),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedGroup = group;
                    });
                  },
                ),
              );
            },
          ),
        ),
        
        // 频道列表
        Expanded(
          child: _selectedGroup == null
              ? const Center(child: Text('请选择分组'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _selectedGroup?.channel.length ?? 0 ?? 0,
                  itemBuilder: (context, index) {
                    final channel = _selectedGroup!.channel[index];
                    final isSelected = _selectedChannel == channel;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      color: isSelected
                          ? Theme.of(context).primaryColor.withOpacity(0.2)
                          : null,
                      child: ListTile(
                        leading: Icon(
                          Icons.live_tv,
                          color: isSelected
                              ? Theme.of(context).primaryColor
                              : Colors.grey,
                        ),
                        title: Text(channel.name ?? '频道 $index'),
                        subtitle: channel.epg != null
                            ? Text('节目：${channel.epg}')
                            : null,
                        trailing: IconButton(
                          icon: const Icon(Icons.info_outline),
                          onPressed: () => _showEPG(channel),
                        ),
                        onTap: () => _playChannel(channel),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
