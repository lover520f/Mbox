import 'package:hive/hive.dart';
import '../models/history.dart';
import '../utils/log_utils.dart';

class HistoryDatabase {
  static const String boxName = 'watch_history';
  static late Box _box;

  static Future<void> init() async {
    _box = await Hive.openBox(boxName);
    Log.d('History database initialized');
  }

  static Future<void> addHistory(WatchHistory history) async {
    await _box.put(history.id, history.toJson());
    Log.d('History added: ${history.vodName}');
  }

  static List<WatchHistory> getAllHistory() {
    final history = _box.values.map((e) {
      if (e is Map) {
        return WatchHistory.fromJson(Map<String, dynamic>.from(e));
      } else if (e is WatchHistory) {
        return e;
      }
      return null;
    }).whereType<WatchHistory>().toList()
      ..sort((a, b) => b.watchedAt.compareTo(a.watchedAt));
    return history;
  }

  static WatchHistory? getByVodId(String vodId) {
    final all = getAllHistory();
    if (all.isEmpty) return null;
    return all.firstWhere((h) => h.vodId == vodId, orElse: () => all.first);
  }

  static Future<void> deleteHistory(String id) async {
    await _box.delete(id);
  }

  static Future<void> clearAll() async {
    await _box.clear();
  }

  static int get count => _box.length;
}
