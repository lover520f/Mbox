import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../database/history_db.dart';
import '../../models/history.dart';
import '../../widgets/vod_card.dart';
import '../../provider/config_provider.dart';
import '../../utils/log_utils.dart';

/// 历史记录页面
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<WatchHistory> _historyList = [];
  bool _isLoading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final history = HistoryDatabase.getAllHistory();
      setState(() {
        _historyList = history;
        _isLoading = false;
      });
    } catch (e) {
      Log.e('Load history error: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('观看记录'),
        actions: [
          if (_historyList.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: _confirmClearAll,
              tooltip: '清空所有记录',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _historyList.isEmpty
              ? _buildEmptyView()
              : _buildHistoryList(),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '暂无观看记录',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '观看视频后会自动记录',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _historyList.length,
      itemBuilder: (context, index) {
        final history = _historyList[index];
        return _buildHistoryItem(history);
      },
    );
  }

  Widget _buildHistoryItem(WatchHistory history) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          // TODO: 跳转到详情页并恢复播放
          _playFromHistory(history);
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // 封面图
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: history.vodPic != null && history.vodPic!.isNotEmpty
                    ? Image.network(
                        history.vodPic!,
                        width: 120,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 120,
                          height: 80,
                          color: Colors.grey[300],
                          child: Icon(Icons.movie, color: Colors.grey[500]),
                        ),
                      )
                    : Container(
                        width: 120,
                        height: 80,
                        color: Colors.grey[300],
                        child: Icon(Icons.movie, color: Colors.grey[500]),
                      ),
              ),
              const SizedBox(width: 16),
              // 信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      history.vodName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (history.episodeName != null)
                      Text(
                        history.episodeName!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          history.progress,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[400],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          history.watchedTime,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // 删除按钮
              IconButton(
                icon: const Icon(Icons.delete_outline),
                color: Colors.red[400],
                onPressed: () => _deleteHistory(history),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _playFromHistory(WatchHistory history) async {
    // TODO: 跳转到播放器并恢复播放位置
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '准备播放：${history.vodName} ${history.episodeName ?? ''}',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _deleteHistory(WatchHistory history) async {
    try {
      await HistoryDatabase.deleteHistory(history.id);
      await _loadHistory();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('已删除记录'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      Log.e('Delete history error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('删除失败'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _confirmClearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认清空'),
        content: const Text('确定要清空所有观看记录吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('清空'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await HistoryDatabase.clearAll();
        await _loadHistory();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('已清空所有记录'),
              duration: Duration(seconds: 1),
            ),
          );
        }
      } catch (e) {
        Log.e('Clear all history error: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('清空失败'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
