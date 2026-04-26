import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../provider/config_provider.dart';
import '../../provider/app_provider.dart';
import '../../widgets/vod_grid.dart';
import '../../widgets/source_list.dart';
import '../../widgets/loading_dialog.dart';
import '../../widgets/config_dialog.dart';
import '../../crawler/spider_engine.dart';
import '../../utils/log_utils.dart';
import '../../models/vod.dart';

/// TV 版首页（Leanback 风格）
class LeanbackHomeScreen extends StatefulWidget {
  const LeanbackHomeScreen({super.key});

  @override
  State<LeanbackHomeScreen> createState() => _LeanbackHomeScreenState();
}

class _LeanbackHomeScreenState extends State<LeanbackHomeScreen> {
  static const int _tabCount = 4;
  int _currentTabIndex = 0;
  bool _isSpiderInitialized = false;
  List<Map<String, dynamic>> _homeClasses = [];
  bool _isLoadingHome = false;
  String? _currentSiteKey;
  List<Vod> _vodList = [];

  @override
  void initState() {
    super.initState();
    _initSpiderEngine();
  }

  Future<void> _initSpiderEngine() async {
    try {
      Log.d('Initializing spider engine...');
      await SpiderEngine.init('', '');
      setState(() {
        _isSpiderInitialized = true;
      });
      Log.d('Spider engine initialized');
      _loadHomeContent();
    } catch (e) {
      Log.e('Failed to initialize spider engine: $e');
    }
  }

  Future<void> _loadHomeContent() async {
    final configProvider = context.read<ConfigProvider>();
    if (configProvider.config == null) return;
    
    // 使用第一个站点
    final siteId = configProvider.config!.sites.first.key;

    setState(() {
      _isLoadingHome = true;
    });
    
    try {
      // 加载首页分类
      final result = await SpiderEngine.home('');
      if (result['class'] != null && result['class'] is List) {
        setState(() {
          _homeClasses = List<Map<String, dynamic>>.from(result['class']);
        });
        Log.d('Loaded ${_homeClasses.length} home categories');
      }
      
      // 加载第一个分类的内容
      if (_homeClasses.isNotEmpty) {
        final firstClass = _homeClasses.first;
        final contentResult = await configProvider.getCategoryContent(
          siteId,
          firstClass['type_id'],
          '1',
        );
        
        if (contentResult['list'] != null && contentResult['list'] is List) {
          setState(() {
            _vodList = (contentResult['list'] as List)
                .map((item) => Vod.fromJson(item as Map<String, dynamic>))
                .toList();
          });
          Log.d('Loaded ${_vodList.length} videos');
        }
      }
    } catch (e) {
      Log.e('Load home content error: $e');
    } finally {
      setState(() {
        _isLoadingHome = false;
      });
    }
  }

  Future<void> _showConfigLoadDialog() async {
    final result = await showDialog(
      context: context,
      builder: (context) => const ConfigLoadDialog(),
    );
    
    if (result == true) {
      _loadHomeContent();
    }
  }

  Future<void> _showSourceListDialog() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => const SourceListDialog(),
    );
    
    if (result != null && result != _currentSiteKey) {
      setState(() {
        _currentSiteKey = result;
      });
      Log.d('Switched to site: $_currentSiteKey');
      _loadHomeContent();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          _buildNavigationBar(),
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
    final icons = [Icons.home, Icons.live_tv, Icons.search, Icons.settings];
    final isSelected = _currentTabIndex == index;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(icons[index], color: Colors.white),
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

  Widget _buildHomeTab() {
    final configProvider = context.watch<ConfigProvider>();
    
    if (!_isSpiderInitialized) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              '初始化爬虫引擎...',
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
          ],
        ),
      );
    }

    if (_isLoadingHome && _homeClasses.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              '加载中...',
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
          ],
        ),
      );
    }

    if (_homeClasses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.movie_outlined,
              size: 80,
              color: Colors.white54,
            ),
            const SizedBox(height: 24),
            Text(
              configProvider.config == null ? '请先加载配置' : '暂无内容',
              style: const TextStyle(fontSize: 24, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (configProvider.config == null)
                  ElevatedButton(
                    onPressed: _showConfigLoadDialog,
                    child: const Text('加载配置'),
                  ),
                if (configProvider.config != null)
                  ElevatedButton(
                    onPressed: _loadHomeContent,
                    child: const Text('刷新'),
                  ),
              ],
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '推荐',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _showSourceListDialog,
                icon: const Icon(Icons.swap_horiz),
                label: Text(
                  configProvider.config?.sites.firstWhere(
                    (s) => s.key == _currentSiteKey,
                    orElse: () => configProvider.config!.sites.first,
                  ).name ?? '选择站点',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _homeClasses.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Chip(
                      label: const Text('全部', style: TextStyle(color: Colors.white)),
                      backgroundColor: Colors.blue,
                      avatar: const Icon(Icons.all_inclusive, color: Colors.white, size: 18),
                    ),
                  );
                }
                final category = _homeClasses[index - 1];
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Chip(
                    label: Text(category['type_name'] ?? '', style: const TextStyle(color: Colors.white)),
                    backgroundColor: Colors.grey[800],
                    avatar: Icon(Icons.category, color: Colors.white.withOpacity(0.7), size: 18),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _vodList.isEmpty && !_isLoadingHome
                ? const Center(
                    child: Text(
                      '暂无内容',
                      style: TextStyle(fontSize: 18, color: Colors.white54),
                    ),
                  )
                : VodGrid(items: _vodList),
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
