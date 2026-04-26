import 'package:json_annotation/json_annotation.dart';

part 'danmaku.g.dart';

/// 弹幕对象
@JsonSerializable(explicitToJson: true)
class Danmaku {
  final String url;
  final String? name;

  Danmaku({
    required this.url,
    this.name,
  });

  factory Danmaku.fromJson(Map<String, dynamic> json) => _$DanmakuFromJson(json);
  Map<String, dynamic> toJson() => _$DanmakuToJson(this);
}
