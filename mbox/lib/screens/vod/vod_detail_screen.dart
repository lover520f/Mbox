import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import '../../models/vod.dart';
import '../../provider/config_provider.dart';
import '../../provider/player_provider.dart';
import '../../utils/log_utils.dart';
import '../../routes/app_routes.dart';

/// 视频详情页面
class VodDetailScreen extends StatefulWidget {
  final Vod vod;
  final String siteId;

  const VodDetailScreen({
    super.key,
    required this.vod,
    required this.siteId,
  });

  @override
  State<VodDetailScreen> createState() => _VodDetailScreenState();
}

class _VodDetailScreenState extends State<VodDetailScreen> {
  Vod? _detailVod;
  bool _isLoading = false;
  int _selectedTabIndex = 0;
  int _selectedEpisodeIndex = -1;
  String? _selectedFrom;
  
  // 解析后的播放列表
  List<Map<String, String>> _episodes = [];

  @override
  void initState() {
    super.initState();
    _detailVod = widget.vod;
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() => _isLoading = true);

    try {
      final configProvider = context.read<ConfigProvider>();
      final detail = await configProvider.getDetail(widget.siteId, _detailVod!.id);
      
      if (detail != null) {
        setState(() {
          _detailVod = detail;
          _parseEpisodes();
        });
        Log.d('Detail loaded: ${detail.vodName}');
      }
    } catch (e) {
      Log.e('Load detail error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 解析播放集数
  void _parseEpisodes() {
    if (_detailVod == null || _detailVod!.vodPlayUrl == null) return;

    _episodes.clear();
    final playUrl = _detailVod!.vodPlayUrl!;
    
    // 格式：第 1 集$http://xxx#第 2 集$http://yyy
    final episodePattern = RegExp(r'([^#\$]+)\$(.+)');
    final matches = episodePattern.allMatches(playUrl);
    
    for (final match in matches) {
      final title = match.group(1)?.trim() ?? '';
      final url = match.group(2)?.trim() ?? '';
      if (title.isNotEmpty && url.isNotEmpty) {
        _episodes.add({'title': title, 'url': url});
      }
    }
    
    _selectedFrom = _detailVod!.vodPlayFrom;
    Log.d('Parsed ${_episodes.length} episodes');
  }

  void _onEpisodeSelected(int index, String url) {
    setState(() {
      _selectedEpisodeIndex = index;
    });
    
    final playerProvider = context.read<PlayerProvider>();
    playerProvider.setCurrentEpisode(url);
    playerProvider.setVod(_detailVod!);
    
    Get.toNamed(AppRoutes.vodPlayer, arguments: {
      'vod': _detailVod!,
      'episodeIndex': index,
      'url': url,
      'title': _episodes[index]['title'],
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_detailVod?.vodName ?? '详情'),
        actions: [
          IconButton(
            icon: const Icon(Icons.play_arrow),
            onPressed: _selectedEpisodeIndex >= 0 
                ? () => _onEpisodeSelected(_selectedEpisodeIndex, _episodes[_selectedEpisodeIndex]['url']!)
                : null,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_detailVod == null) {
      return const Center(child: Text('加载失败'));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 600) {
          return _buildTVLayout();
        } else {
          return _buildMobileLayout();
        }
      },
    );
  }

  Widget _buildTVLayout() {
    return Row(
      children: [
        // 左侧海报和信息
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _detailVod!.vodPic != null
                      ? Image.network(
                          _detailVod!.vodPic!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: 300,
                          errorBuilder: (_, __, ___) => _buildPlaceholder(),
                        )
                      : _buildPlaceholder(),
                ),
                const SizedBox(height: 16),
                Text(_detailVod!.vodName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _infoRow('年份', _detailVod!.vodYear),
                _infoRow('地区', _detailVod!.vodArea),
                _infoRow('类型', _detailVod!.typeName),
                _infoRow('备注', _detailVod!.vodRemarks),
                if (_detailVod!.vodDirector != null) _textRow('导演', _detailVod!.vodDirector!),
                if (_detailVod!.vodActor != null) _textRow('主演', _detailVod!.vodActor!),
                if (_detailVod!.vodContent != null && _detailVod!.vodContent!.isNotEmpty)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: SingleChildScrollView(
                        child: Text(
                          _detailVod!.vodContent ?? '',
                          style: TextStyle(color: Colors.grey[300]),
                          maxLines: 6,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        // 右侧集数列表
        Expanded(
          flex: 3,
          child: _buildEpisodeSection(),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 海报和简介
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _detailVod!.vodPic != null
                      ? Image.network(
                          _detailVod!.vodPic!,
                          fit: BoxFit.cover,
                          width: 120,
                          height: 180,
                          errorBuilder: (_, __, ___) => _buildMobilePlaceholder(),
                        )
                      : _buildMobilePlaceholder(),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_detailVod!.vodName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      _infoRow('年份', _detailVod!.vodYear),
                      _infoRow('地区', _detailVod!.vodArea),
                      _infoRow('类型', _detailVod!.typeName),
                      _infoRow('备注', _detailVod!.vodRemarks),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // 简介
          if (_detailVod!.vodContent != null && _detailVod!.vodContent!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('简介', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    _detailVod!.vodContent ?? '',
                    style: TextStyle(color: Colors.grey[300]),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          // 集数列表
          _buildEpisodeSection(),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      height: 300,
      color: Colors.grey[800],
      child: const Icon(Icons.movie, size: 64),
    );
  }

  Widget _buildMobilePlaceholder() {
    return Container(
      width: 120,
      height: 180,
      color: Colors.grey[800],
      child: const Icon(Icons.movie, size: 48),
    );
  }

  Widget _infoRow(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Text('$label: $value', style: TextStyle(color: Colors.grey[400], fontSize: 14)),
    );
  }

  Widget _textRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: RichText(
        text: TextSpan(
          style: TextStyle(color: Colors.grey[400], fontSize: 14),
          children: [
            TextSpan(text: '$label:', style: const TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: ' $value'),
          ],
        ),
      ),
    );
  }

  Widget _buildEpisodeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            _selectedFrom != null ? '$_selectedFrom 共${_episodes.length}集' : '播放列表',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        if (_episodes.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('暂无播放资源', style: TextStyle(color: Colors.grey)),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 2,
              ),
              itemCount: _episodes.length,
              itemBuilder: (context, index) {
                final episode = _episodes[index];
                final isSelected = _selectedEpisodeIndex == index;
                return ElevatedButton(
                  onPressed: () => _onEpisodeSelected(index, episode['url']!),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSelected ? Colors.blue : Colors.grey[800],
                    foregroundColor: isSelected ? Colors.white : Colors.white70,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                  child: Text(
                    episode['title'] ?? '第${index + 1}集',
                    style: const TextStyle(fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              },
            ),
          ),
        const SizedBox(height: 16),
      ],
    );
  }
}
