import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import '../../models/vod.dart';
import '../../models/vod_config.dart';
import '../../provider/config_provider.dart';
import '../../provider/player_provider.dart';
import '../../utils/device_utils.dart';
import '../../utils/log_utils.dart';
import '../../routes/app_routes.dart';

/// 点播详情页面
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
  late Vod _vod;
  int _selectedSeasonIndex = 0;
  int _selectedEpisodeIndex = 0;
  bool _isLoading = false;
  String? _currentEpisodeUrl;

  @override
  void initState() {
    super.initState();
    _vod = widget.vod;
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final configProvider = context.read<ConfigProvider>();
      final detail = await configProvider.getDetail(widget.siteId, _vod.id);
      
      if (detail != null) {
        setState(() {
          _vod = detail;
          _parseEpisodes();
        });
      }
    } catch (e) {
      Log.d('加载详情失败：$e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _parseEpisodes() {
    // 解析剧集信息
    if (_vod.playUrl != null && _vod.playUrl!.isNotEmpty) {
      // 解析播放 URL
    }
  }

  void _playEpisode(int episodeIndex) {
    final playerProvider = context.read<PlayerProvider>();
    playerProvider.setCurrentEpisode(_currentEpisodeUrl ?? '');
    
    Get.toNamed(AppRoutes.vodPlayer, arguments: {
      'vod': _vod,
      'episodeIndex': episodeIndex,
      'url': _currentEpisodeUrl,
    });
  }

  @override
  Widget build(BuildContext context) {
    final isTV = false; // DeviceUtils 已移除
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_vod.vodName ?? '详情'),
        actions: [
          IconButton(
            icon: const Icon(Icons.play_arrow),
            onPressed: () => _playEpisode(_selectedEpisodeIndex),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(isTV),
    );
  }

  Widget _buildContent(bool isTV) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (isTV) {
          return _buildTVLayout();
        } else {
          return _buildMobileLayout(constraints);
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
                // 海报
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _vod.vodPic != null
                      ? Image.network(
                          _vod.vodPic!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: 300,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 300,
                              color: Colors.grey[800],
                              child: const Icon(Icons.movie, size: 64),
                            );
                          },
                        )
                      : Container(
                          height: 300,
                          color: Colors.grey[800],
                          child: const Icon(Icons.movie, size: 64),
                        ),
                ),
                const SizedBox(height: 16),
                // 基本信息
                Text(
                  _vod.vodName ?? '',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                if (_vod.vodYear != null)
                  Text('年份：${_vod.vodYear}', style: TextStyle(color: Colors.grey[400])),
                if (_vod.vodArea != null)
                  Text('地区：${_vod.vodArea}', style: TextStyle(color: Colors.grey[400])),
                if (_vod.typeName != null)
                  Text('类型：${_vod.typeName}', style: TextStyle(color: Colors.grey[400])),
                if (_vod.vodRemarks != null)
                  Text('备注：${_vod.vodRemarks}', style: TextStyle(color: Colors.grey[400])),
                if (_vod.vodDirector != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text('导演：${_vod.vodDirector}', style: TextStyle(color: Colors.grey[400])),
                  ),
                if (_vod.vodActor != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text('主演：${_vod.vodActor}', style: TextStyle(color: Colors.grey[400])),
                  ),
                if (_vod.remark != null && _vod.remark!.isNotEmpty)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: SingleChildScrollView(
                        child: Text(
                          _vod.remark!,
                          style: TextStyle(color: Colors.grey[300]),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        // 右侧剧集列表
        Expanded(
          flex: 3,
          child: _buildEpisodeList(),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(BoxConstraints constraints) {
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
                // 海报
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _vod.vodPic != null
                      ? Image.network(
                          _vod.vodPic!,
                          fit: BoxFit.cover,
                          width: 150,
                          height: 220,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 150,
                              height: 220,
                              color: Colors.grey[800],
                              child: const Icon(Icons.movie, size: 48),
                            );
                          },
                        )
                      : Container(
                          width: 150,
                          height: 220,
                          color: Colors.grey[800],
                          child: const Icon(Icons.movie, size: 48),
                        ),
                ),
                const SizedBox(width: 16),
                // 信息
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _vod.vodName ?? '',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      if (_vod.vodYear != null)
                        Text('年份：${_vod.vodYear}', style: TextStyle(color: Colors.grey[400])),
                      if (_vod.vodArea != null)
                        Text('地区：${_vod.vodArea}', style: TextStyle(color: Colors.grey[400])),
                      if (_vod.typeName != null)
                        Text('类型：${_vod.typeName}', style: TextStyle(color: Colors.grey[400])),
                      if (_vod.vodRemarks != null)
                        Text('备注：${_vod.vodRemarks}', style: TextStyle(color: Colors.grey[400])),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('立即播放'),
                        onPressed: () => _playEpisode(_selectedEpisodeIndex),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // 导演和演员
          if (_vod.vodDirector != null || _vod.vodActor != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_vod.vodDirector != null)
                    Text('导演：${_vod.vodDirector}', style: TextStyle(color: Colors.grey[400])),
                  if (_vod.vodActor != null)
                    Text('主演：${_vod.vodActor}', style: TextStyle(color: Colors.grey[400])),
                ],
              ),
            ),
          // 简介
          if (_vod.remark != null && _vod.remark!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('简介', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(_vod.remark!, style: TextStyle(color: Colors.grey[300])),
                ],
              ),
            ),
          // 剧集列表
          _buildEpisodeList(),
        ],
      ),
    );
  }

  Widget _buildEpisodeList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 季数选择（如果有）
        if (_vod.series != null && _vod.series!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _vod.series!.length,
                itemBuilder: (context, index) {
                  final isSelected = index == _selectedSeasonIndex;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(_vod.series![index].name ?? '第${index + 1}季'),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedSeasonIndex = index;
                        });
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        // 集数网格
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            '选集',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.5,
            ),
            itemCount: _vod.playlists?.length ?? 0,
            itemBuilder: (context, index) {
              final playlist = _vod.playlists?[index];
              final isSelected = index == _selectedEpisodeIndex;
              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedEpisodeIndex = index;
                    _currentEpisodeUrl = playlist?.url;
                  });
                  _playEpisode(index);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? Theme.of(context).primaryColor : Colors.grey[800],
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    playlist?.name ?? '第${index + 1}集',
                    style: const TextStyle(fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
