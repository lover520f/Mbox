import 'package:json_annotation/json_annotation.dart';

part 'history.g.dart';

/// 观看历史
@JsonSerializable(explicitToJson: true)
class WatchHistory {
  final String id;
  final String vodId;
  final String vodName;
  final String? vodPic;
  final String sourceKey;
  final String? episodeUrl;
  final String? episodeName;
  final int position; // 毫秒
  final int duration; // 毫秒
  final DateTime watchedAt;
  final String? configName;

  WatchHistory({
    required this.id,
    required this.vodId,
    required this.vodName,
    this.vodPic,
    required this.sourceKey,
    this.episodeUrl,
    this.episodeName,
    required this.position,
    required this.duration,
    required this.watchedAt,
    this.configName,
  });

  factory WatchHistory.fromJson(Map<String, dynamic> json) =>
      _$WatchHistoryFromJson(json);
  Map<String, dynamic> toJson() => _$WatchHistoryToJson(this);

  /// 获取格式化后的观看进度
  String get progress {
    if (duration <= 0) return '0%';
    final percent = (position / duration * 100).toInt();
    return '$percent%';
  }

  /// 获取格式化后的观看时间
  String get watchedTime {
    return '${watchedAt.year}-${watchedAt.month.toString().padLeft(2, '0')}-${watchedAt.day.toString().padLeft(2, '0')} '
        '${watchedAt.hour.toString().padLeft(2, '0')}:${watchedAt.minute.toString().padLeft(2, '0')}';
  }
}
