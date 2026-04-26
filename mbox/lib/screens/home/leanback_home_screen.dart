import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../provider/config_provider.dart';
import '../../provider/app_provider.dart';
import '../../widgets/vod_grid.dart';
import '../../widgets/source_list.dart';
import '../../widgets/loading_dialog.dart';

/// TV 版首页（Leanback 风格）
class LeanbackHomeScreen extends StatefulWidget {
  const LeanbackHomeScreen({super.key});

  @override
  State<LeanbackHomeScreen> createState() => _LeanbackHomeScreenState();
}

class _LeanbackHomeScreenState extends State<LeanbackHomeScreen> {
  static const int _tabCount = 4;
  int _currentTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // 左侧导航栏
          _buildNavigationBar(),
          
          // 右侧内容区
          Expanded(
            child: _buildContentArea(),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationBar() {
    return Container(
      width: 150,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
      ),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'MBox',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _tabCount,
              itemBuilder: (context, index) {
                return _buildNavItem(index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index) {
    final titles = ['首页', '直播', '搜索', '设置'];
    final isSelected = _currentTabIndex == index;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        title: Text(
          titles[index],
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        onTap: () {
          setState(() {
            _currentTabIndex = index;
          });
        },
      ),
    );
  }

  Widget _buildContentArea() {
    final configProvider = context.watch<ConfigProvider>();
    
    if (configProvider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    if (configProvider.config == null) {
      return _buildEmptyState();
    }
    
    return IndexedStack(
      index: _currentTabIndex,
      children: [
        _buildHomeTab(),
        _buildLiveTab(),
        _buildSearchTab(),
        _buildSettingsTab(),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.cloud_upload_outlined,
            size: 80,
            color: Colors.white54,
          ),
          const SizedBox(height: 24),
          const Text(
            '请先加载配置',
            style: TextStyle(
              fontSize: 24,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              // TODO: 打开配置加载对话框
            },
            child: const Text('加载配置'),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '推荐',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          const Expanded(
            child: VodGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveTab() {
    return const Center(
      child: Text(
        '直播',
        style: TextStyle(fontSize: 24, color: Colors.white),
      ),
    );
  }

  Widget _buildSearchTab() {
    return const Center(
      child: Text(
        '搜索',
        style: TextStyle(fontSize: 24, color: Colors.white),
      ),
    );
  }

  Widget _buildSettingsTab() {
    return const Center(
      child: Text(
        '设置',
        style: TextStyle(fontSize: 24, color: Colors.white),
      ),
    );
  }
}
