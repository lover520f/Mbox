import 'package:json_annotation/json_annotation.dart';

part 'vod.g.dart';

/// 视频数据对象
@JsonSerializable(explicitToJson: true)
class Vod {
  final String vodId;
  final String vodName;
  final String? vodPic;
  final String? vodRemarks;
  final String? typeName;
  final String? vodYear;
  final String? vodArea;
  final String? vodDirector;
  final String? vodActor;
  final String? vodContent;
  final String? vodPlayFrom;
  final String? vodPlayUrl;
  final String? vodTag;
  final String? action;
  final Cate? cate;
  final int? land;
  final int? circle;
  final double? ratio;
  final Style? style;
  
  // 详情页扩展字段
  final String? type;
  final String? area;
  final String? year;
  final String? remark;
  final String? remarks;
  final String? des;
  final List<PlayList>? playlists;
  final List<Series>? series;

  Vod({
    required this.vodId,
    required this.vodName,
    this.vodPic,
    this.vodRemarks,
    this.typeName,
    this.vodYear,
    this.vodArea,
    this.vodDirector,
    this.vodActor,
    this.vodContent,
    this.vodPlayFrom,
    this.vodPlayUrl,
    this.vodTag,
    this.action,
    this.cate,
    this.land,
    this.circle,
    this.ratio,
    this.style,
    this.type,
    this.area,
    this.year,
    this.remark,
    this.remarks,
    this.des,
    this.playlists,
    this.series,
  });

  factory Vod.fromJson(Map<String, dynamic> json) => _$VodFromJson(json);
  Map<String, dynamic> toJson() => _$VodToJson(this);
}

/// 分类对象
@JsonSerializable(explicitToJson: true)
class Class {
  final String typeId;
  final String typeName;
  final String? typeFlag;
  final int? land;
  final int? circle;
  final double? ratio;

  Class({
    required this.typeId,
    required this.typeName,
    this.typeFlag,
    this.land,
    this.circle,
    this.ratio,
  });

  factory Class.fromJson(Map<String, dynamic> json) => _$ClassFromJson(json);
  Map<String, dynamic> toJson() => _$ClassToJson(this);
}

/// 筛选器对象
@JsonSerializable(explicitToJson: true)
class Filter {
  final String key;
  final String name;
  final String? init;
  final List<FilterValue> value;

  Filter({
    required this.key,
    required this.name,
    this.init,
    required this.value,
  });

  factory Filter.fromJson(Map<String, dynamic> json) => _$FilterFromJson(json);
  Map<String, dynamic> toJson() => _$FilterToJson(this);
}

@JsonSerializable(explicitToJson: true)
class FilterValue {
  final String n;
  final String v;

  FilterValue({
    required this.n,
    required this.v,
  });

  factory FilterValue.fromJson(Map<String, dynamic> json) =>
      _$FilterValueFromJson(json);
  Map<String, dynamic> toJson() => _$FilterValueToJson(this);
}

/// 分类样式对象
@JsonSerializable(explicitToJson: true)
class Cate {
  final int? land;
  final int? circle;
  final double? ratio;

  Cate({this.land, this.circle, this.ratio});

  factory Cate.fromJson(Map<String, dynamic> json) => _$CateFromJson(json);
  Map<String, dynamic> toJson() => _$CateToJson(this);
}

/// 弹幕对象
@JsonSerializable(explicitToJson: true)
class Danmaku {
  final String url;
  final String? name;

  Danmaku({
    required this.url,
    this.name,
  });

  factory Danmaku.fromJson(Map<String, dynamic> json) =>
      _$DanmakuFromJson(json);
  Map<String, dynamic> toJson() => _$DanmakuToJson(this);
}

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

  factory Sub.fromJson(Map<String, dynamic> json) => _$SubFromJson(json);
  Map<String, dynamic> toJson() => _$SubToJson(this);
}

/// 播放列表项
@JsonSerializable(explicitToJson: true)
class PlayList {
  final String name;
  final String url;

  PlayList({
    required this.name,
    required this.url,
  });

  factory PlayList.fromJson(Map<String, dynamic> json) => _$PlayListFromJson(json);
  Map<String, dynamic> toJson() => _$PlayListToJson(this);
}

/// 季数信息
@JsonSerializable(explicitToJson: true)
class Series {
  final String? name;
  final String? id;

  Series({
    this.name,
    this.id,
  });

  factory Series.fromJson(Map<String, dynamic> json) => _$SeriesFromJson(json);
  Map<String, dynamic> toJson() => _$SeriesToJson(this);
}

/// 样式对象
@JsonSerializable(explicitToJson: true)
class Style {
  final int? land;
  final int? circle;
  final double? ratio;

  Style({this.land, this.circle, this.ratio});

  factory Style.fromJson(Map<String, dynamic> json) => _$StyleFromJson(json);
  Map<String, dynamic> toJson() => _$StyleToJson(this);
}
