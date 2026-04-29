import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../provider/config_provider.dart';
import '../../widgets/vod_grid.dart';
import '../../widgets/config_dialog.dart';
import '../../models/vod.dart';
import '../../crawler/spider_engine.dart';
import '../../utils/log_utils.dart';

/// 点播首页
class VodHomeScreen extends StatefulWidget {
  const VodHomeScreen({super.key});

  @override
  State<VodHomeScreen> createState() => _VodHomeScreenState();
}

class _VodHomeScreenState extends State<VodHomeScreen> with TickerProviderStateMixin {
  bool _isLoading = false;
  List<Map<String, dynamic>> _categories = [];
  List<Vod> _vodList = [];
  String? _currentSiteKey;
  int _selectedCategoryIndex = 0;
  
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
    _loadContent();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadContent() async {
    final configProvider = context.read<ConfigProvider>();
    if (configProvider.config == null) return;
    
    final siteId = configProvider.config!.sites.first.key;
    setState(() => _isLoading = true);

    try {
      // 加载分类
      final result = await SpiderEngine.home(false);
      if (result['class'] != null && result['class'] is List) {
        setState(() {
          _categories = List<Map<String, dynamic>>.from(result['class']);
          if (_categories.isNotEmpty && _selectedCategoryIndex >= _categories.length) {
            _selectedCategoryIndex = 0;
          }
        });
      }
      
      // 加载第一个分类内容
      if (_categories.isNotEmpty) {
        final contentResult = await configProvider.getCategoryContent(
          siteId,
          _categories.first['type_id'],
          '1',
        );
        
        if (contentResult['list'] != null && contentResult['list'] is List) {
          setState(() {
            _vodList = (contentResult['list'] as List)
                .map((item) => Vod.fromJson(item as Map<String, dynamic>))
                .toList();
          });
        }
      }
    } catch (e) {
      Log.e('Load content error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('点播'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchDialog(),
          ),
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            onPressed: () => _showSiteSelectDialog(),
          ),
        ],
        bottom: _categories.length > 1
            ? TabBar(
                controller: _tabController,
                isScrollable: true,
                tabs: _categories.map((cat) => Tab(text: cat['type_name'])).toList(),
              )
            : null,
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _loadContent,
        icon: const Icon(Icons.refresh),
        label: const Text('刷新'),
      ),
    );
  }

  Widget _buildBody() {
    final configProvider = context.watch<ConfigProvider>();
    
    if (configProvider.config == null) {
      return _buildEmptyState('请先在设置中加载配置');
    }

    if (_isLoading && _vodList.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_vodList.isEmpty) {
      return _buildEmptyState('暂无内容');
    }

    return RefreshIndicator(
      onRefresh: _loadContent,
      child: GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.6,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: _vodList.length,
        itemBuilder: (context, index) {
          final vod = _vodList[index];
          return _buildVodCard(vod);
        },
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.movie_outlined, size: 80, color: Colors.grey[600]),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(color: Colors.grey[400], fontSize: 16)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _showConfigDialog(),
            child: const Text('去设置'),
          ),
        ],
      ),
    );
  }

  Widget _buildVodCard(Vod vod) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _goToDetail(vod),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  vod.vodPic != null && vod.vodPic!.isNotEmpty
                      ? Image.network(
                          vod.vodPic!,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey[800],
                            child: const Icon(Icons.image, color: Colors.white54),
                          ),
                        )
                      : Container(
                          color: Colors.grey[800],
                          child: const Icon(Icons.image, color: Colors.white54),
                        ),
                  if (vod.vodRemarks != null && vod.vodRemarks!.isNotEmpty)
                    Positioned(
                      right: 4,
                      bottom: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          vod.vodRemarks!,
                          style: const TextStyle(fontSize: 10, color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vod.vodName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  if (vod.typeName != null && vod.typeName!.isNotEmpty)
                    Text(
                      vod.typeName!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 10, color: Colors.grey[400]),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _goToDetail(Vod vod) {
    // TODO: 跳转到详情页
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('点击：${vod.vodName}')),
    );
  }

  void _showSearchDialog() {
    // TODO: 实现搜索功能
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('搜索功能开发中')),
    );
  }

  void _showSiteSelectDialog() {
    // TODO: 实现站点选择
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('请选择站点')),
    );
  }

  void _showConfigDialog() {
    showDialog(
      context: context,
      builder: (context) => const ConfigLoadDialog(),
    ).then((result) {
      if (result == true) {
        _loadContent();
      }
    });
  }
}
