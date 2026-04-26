import 'package:hive/hive.dart';
import '../models/history.dart';
import '../utils/log_utils.dart';

/// 历史记录数据库管理
class HistoryDatabase {
  static late String boxName = 'watch_history';
  static late Box<WatchHistory> _box;

  /// 初始化数据库
  static Future<void> init() async {
    // 注册适配器
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(WatchHistoryAdapter());
    }
    
    _box = await Hive.openBox<WatchHistory>(boxName);
    Log.d('History database initialized');
  }

  /// 添加观看记录
  static Future<void> addHistory(WatchHistory history) async {
    // 检查是否已存在相同的记录
    final existing = await _box.get(history.id);
    
    if (existing != null) {
      // 更新现有记录
      await _box.put(history.id, history);
      Log.d('History updated: ${history.vodName}');
    } else {
      // 添加新记录
      await _box.put(history.id, history);
      Log.d('History added: ${history.vodName}');
    }
    
    // 清理 60 天前的记录
    await cleanupOldHistory();
  }

  /// 获取所有观看记录
  static List<WatchHistory> getAllHistory() {
    final history = _box.values.toList();
    // 按观看时间倒序排序
    history.sort((a, b) => b.watchedAt.compareTo(a.watchedAt));
    return history;
  }

  /// 获取指定来源的观看记录
  static List<WatchHistory> getBySource(String sourceKey) {
    return _box.values
        .where((h) => h.sourceKey == sourceKey)
        .toList()
      ..sort((a, b) => b.watchedAt.compareTo(a.watchedAt));
  }

  /// 获取指定影片的观看记录
  static WatchHistory? getByVodId(String vodId) {
    return _box.values.cast<WatchHistory?>().firstWhere(
          (h) => h?.vodId == vodId,
          orElse: () => null,
        );
  }

  /// 删除观看记录
  static Future<void> deleteHistory(String id) async {
    await _box.delete(id);
    Log.d('History deleted: $id');
  }

  /// 清空所有观看记录
  static Future<void> clearAll() async {
    await _box.clear();
    Log.d('All history cleared');
  }

  /// 清理 60 天前的记录
  static Future<void> cleanupOldHistory() async {
    final sixtyDaysAgo = DateTime.now().subtract(const Duration(days: 60));
    final toDelete = <String>[];
    
    _box.keys.forEach((key) {
      final history = _box.get(key);
      if (history != null && history.watchedAt.isBefore(sixtyDaysAgo)) {
        toDelete.add(key);
      }
    });
    
    if (toDelete.isNotEmpty) {
      await _box.deleteAll(toDelete);
      Log.d('Cleaned up ${toDelete.length} old history records');
    }
  }

  /// 获取记录数量
  static int get count => _box.length;
}
