import 'package:json_annotation/json_annotation.dart';

part 'drm.g.dart';

/// DRM 配置对象
@JsonSerializable(explicitToJson: true)
class Drm {
  final String? type;
  final String? key;
  final Map<String, String>? header;
  final bool? forceKey;

  Drm({
    this.type,
    this.key,
    this.header,
    this.forceKey,
  });

  factory Drm.fromJson(Map<String, dynamic> json) => _$DrmFromJson(json);
  Map<String, dynamic> toJson() => _$DrmToJson(this);
}
