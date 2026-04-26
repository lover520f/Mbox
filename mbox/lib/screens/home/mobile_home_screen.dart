import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../provider/config_provider.dart';
import '../../widgets/vod_grid.dart';

/// 手机版首页（Material Design 风格）
class MobileHomeScreen extends StatefulWidget {
  const MobileHomeScreen({super.key});

  @override
  State<MobileHomeScreen> createState() => _MobileHomeScreenState();
}

class _MobileHomeScreenState extends State<MobileHomeScreen> {
  int _currentTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MBox'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              setState(() {
                _currentTabIndex = 3;
              });
            },
          ),
        ],
      ),
      body: _buildContentArea(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTabIndex,
        onTap: (index) {
          setState(() {
            _currentTabIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '首页'),
          BottomNavigationBarItem(icon: Icon(Icons.live_tv), label: '直播'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: '搜索'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: '设置'),
        ],
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
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            '请先加载配置',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // TODO: 打开配置加载对话框
            },
            icon: const Icon(Icons.folder_open),
            label: const Text('加载配置'),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    return RefreshIndicator(
      onRefresh: () async {
        // TODO: 刷新数据
      },
      child: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                '推荐',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            sliver: const SliverToBoxAdapter(
              child: VodGrid(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveTab() {
    return const Center(
      child: Text('直播'),
    );
  }

  Widget _buildSearchTab() {
    return const Center(
      child: Text('搜索'),
    );
  }

  Widget _buildSettingsTab() {
    return const Center(
      child: Text('设置'),
    );
  }
}
