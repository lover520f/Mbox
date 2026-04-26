import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/vod.dart';
import '../../models/vod_config.dart';
import '../../provider/config_provider.dart';
import '../../widgets/vod_card.dart';
import '../../widgets/filter_panel.dart';

/// 分类页面
class CategoryScreen extends StatefulWidget {
  final String typeId;
  final String typeName;
  final List<Filter> filters;

  const CategoryScreen({
    super.key,
    required this.typeId,
    required this.typeName,
    this.filters = const [],
  });

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  List<Vod> _items = [];
  bool _isLoading = false;
  int _currentPage = 1;
  int _totalPages = 1;
  Map<String, String> _selectedFilters = {};
  bool _showFilterPanel = false;

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  Future<void> _loadContent() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final configProvider = context.read<ConfigProvider>();
      final config = configProvider.config;
      
      if (config == null) {
        throw Exception('配置未加载');
      }

      // 调用爬虫的分类接口
      final result = await configProvider.getCategoryContent(
        config.sites.first.key,
        widget.typeId,
        '$_currentPage',
        extend: _selectedFilters.isNotEmpty 
            ? _selectedFilters.entries.map((e) => '${e.key}=${e.value}').join('&')
            : null,
      );
      
      final List<dynamic> list = result['list'] ?? [];
      final newItems = list.map((item) => Vod.fromJson(item as Map<String, dynamic>)).toList();
      
      setState(() {
        if (_currentPage == 1) {
          _items = newItems;
        } else {
          _items.addAll(newItems);
        }
        _totalPages = result['pagecount'] as int? ?? 1;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载失败：$e')),
        );
      }
    }
  }

  Future<void> _applyFilters(Map<String, String> filters) async {
    setState(() {
      _selectedFilters = filters;
      _currentPage = 1;
    });
    
    await _loadContent();
  }

  Future<void> _loadMore() async {
    if (_currentPage >= _totalPages || _isLoading) return;
    
    setState(() {
      _currentPage++;
    });
    
    await _loadContent();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.typeName),
        actions: [
          if (widget.filters.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: () {
                setState(() {
                  _showFilterPanel = true;
                });
              },
            ),
        ],
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _currentPage = 1;
                _items = [];
              });
              await _loadContent();
            },
            child: _isLoading && _items.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : GridView.builder(
                    padding: const EdgeInsets.all(8),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.6,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: _items.length + 1,
                    itemBuilder: (context, index) {
                      if (index == _items.length) {
                        if (_currentPage >= _totalPages) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text('没有更多了'),
                            ),
                          );
                        } else {
                          _loadMore();
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }
                      }
                      return VodCard(vod: _items[index]);
                    },
                  ),
          ),
          
          // 筛选面板
          if (_showFilterPanel)
            FilterPanel(
              filters: widget.filters,
              selectedFilters: _selectedFilters,
              onApply: (filters) {
                setState(() {
                  _showFilterPanel = false;
                });
                _applyFilters(filters);
              },
              onClose: () {
                setState(() {
                  _showFilterPanel = false;
                });
              },
            ),
        ],
      ),
    );
  }
}
