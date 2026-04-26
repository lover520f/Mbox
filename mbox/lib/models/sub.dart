import 'package:json_annotation/json_annotation.dart';

part 'sub.g.dart';

/// 字幕对象
@JsonSerializable(explicitToJson: true)
class Sub {
  final String url;
  final String? name;
  final String? lang;
  final String? format;
  final int? flag;

  Sub({
    required this.url,
    this.name,
    this.lang,
    this.format,
    this.flag,
  });
  
  // 别名 getter
  String? get label => name;

  factory Sub.fromJson(Map<String, dynamic> json) => _$SubFromJson(json);
  Map<String, dynamic> toJson() => _$SubToJson(this);
}
