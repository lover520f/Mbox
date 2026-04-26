import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../models/vod.dart';
import '../../models/vod_config.dart';
import '../../provider/config_provider.dart';
import '../../widgets/vod_card.dart';
import '../../crawler/spider_loader.dart';

/// 搜索页面
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  
  List<Vod> _results = [];
  bool _isSearching = false;
  String? _lastError;
  
  // 搜索站点选择
  bool _selectAllSites = true;
  List<String> _selectedSiteKeys = [];
  
  // 搜索历史
  List<String> _searchHistory = [];
  
  // 防抖定时器
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _loadSearchHistory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadSearchHistory() async {
    // TODO: 从本地存储加载搜索历史
    setState(() {
      _searchHistory = ['热门电影', '电视剧', '综艺', '动漫'];
    });
  }

  Future<void> _saveSearchHistory(String keyword) async {
    // TODO: 保存到本地存储
    if (mounted) {
      setState(() {
        if (!_searchHistory.contains(keyword)) {
          _searchHistory.insert(0, keyword);
          if (_searchHistory.length > 20) {
            _searchHistory = _searchHistory.sublist(0, 20);
          }
        }
      });
    }
  }

  List<Site> _getSearchableSites() {
    final configProvider = context.read<ConfigProvider>();
    final config = configProvider.config;
    
    if (config == null) return [];
    
    return config.sites
        .where((site) => site.searchable != 0)
        .toList();
  }

  Future<void> _search(String keyword) async {
    if (keyword.trim().isEmpty) return;
    
    final sites = _getSearchableSites();
    if (sites.isEmpty) {
      setState(() {
        _lastError = '没有可搜索的站点';
      });
      return;
    }
    
    setState(() {
      _isSearching = true;
      _lastError = null;
    });
    
    await _saveSearchHistory(keyword);
    
    try {
      // 多站点并行搜索
      final futures = <Future<List<Vod>>>[];
      
      for (final site in sites) {
        if (_selectAllSites || _selectedSiteKeys.contains(site.key)) {
          futures.add(_searchSite(site, keyword));
        }
      }
      
      final results = await Future.wait(futures);
      
      setState(() {
        _results = results.expand((r) => r).toList();
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _lastError = '搜索失败：$e';
        _isSearching = false;
      });
    }
  }

  Future<List<Vod>> _searchSite(Site site, String keyword) async {
    try {
      final configProvider = context.read<ConfigProvider>();
      final results = await configProvider.search(site.key, keyword, quick: false);
      return results;
    } catch (e) {
      return [];
    }
  }

  void _onSearchTextChanged(String text) {
    _debounceTimer?.cancel();
    
    if (text.trim().isEmpty) {
      setState(() {
        _results = [];
      });
      return;
    }
    
    // 防抖，500ms 后执行搜索
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _search(text);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          focusNode: _focusNode,
          decoration: InputDecoration(
            hintText: '请输入关键字...',
            border: InputBorder.none,
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _results = [];
                      });
                    },
                  )
                : null,
          ),
          onChanged: _onSearchTextChanged,
          onSubmitted: _search,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              _search(_searchController.text);
            },
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isSearching && _results.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('正在搜索...'),
          ],
        ),
      );
    }
    
    if (_lastError != null && _results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(_lastError!),
          ],
        ),
      );
    }
    
    if (_results.isEmpty && _searchController.text.isEmpty) {
      return _buildEmptyState();
    }
    
    if (_results.isEmpty) {
      return const Center(
        child: Text('没有找到相关内容'),
      );
    }
    
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.6,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        return VodCard(vod: _results[index]);
      },
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 搜索历史
          if (_searchHistory.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '搜索历史',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _searchHistory.clear();
                    });
                  },
                  child: const Text('清空'),
                ),
              ],
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _searchHistory.map((keyword) {
                return ActionChip(
                  label: Text(keyword),
                  onPressed: () {
                    _searchController.text = keyword;
                    _search(keyword);
                  },
                );
              }).toList(),
            ),
            const Divider(height: 32),
          ],
          
          // 站点选择
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '搜索站点',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Checkbox(
                    value: _selectAllSites,
                    onChanged: (value) {
                      setState(() {
                        _selectAllSites = value ?? false;
                      });
                    },
                  ),
                ],
              ),
              // TODO: 站点列表
            ],
          ),
        ],
      ),
    );
  }
}
