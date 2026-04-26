import 'package:json_annotation/json_annotation.dart';

part 'vod_config.g.dart';

/// Vod 配置根对象
@JsonSerializable(explicitToJson: true)
class VodConfig {
  final String? spider;
  final String? wallpaper;
  final String? logo;
  final String? notice;
  final List<Site> sites;
  final List<Parse> parses;
  final List<Live> lives;
  final List<Doh>? doh;
  final List<Proxy>? proxy;
  final List<Rule>? rules;
  final List<Header>? headers;
  final List<String>? hosts;
  final List<String>? flags;
  final List<String>? ads;

  VodConfig({
    this.spider,
    this.wallpaper,
    this.logo,
    this.notice,
    required this.sites,
    required this.parses,
    required this.lives,
    this.doh,
    this.proxy,
    this.rules,
    this.headers,
    this.hosts,
    this.flags,
    this.ads,
  });

  factory VodConfig.fromJson(Map<String, dynamic> json) => _$VodConfigFromJson(json);
  Map<String, dynamic> toJson() => _$VodConfigToJson(this);
}

/// 站点配置
@JsonSerializable(explicitToJson: true)
class Site {
  final String key;
  final String name;
  final int type;
  final String api;
  final String? ext;
  final String? jar;
  final String? click;
  final String? playUrl;
  final int? hide;
  final int? timeout;
  final int? searchable;
  final int? changeable;
  final int? quickSearch;
  final int? indexs;
  final List<String>? categories;
  final Map<String, String>? header;
  final Style? style;

  Site({
    required this.key,
    required this.name,
    required this.type,
    required this.api,
    this.ext,
    this.jar,
    this.click,
    this.playUrl,
    this.hide,
    this.timeout,
    this.searchable,
    this.changeable,
    this.quickSearch,
    this.indexs,
    this.categories,
    this.header,
    this.style,
  });

  factory Site.fromJson(Map<String, dynamic> json) => _$SiteFromJson(json);
  Map<String, dynamic> toJson() => _$SiteToJson(this);
}

/// 解析器配置
@JsonSerializable(explicitToJson: true)
class Parse {
  final String name;
  final int type;
  final String url;
  final ParseExt? ext;

  Parse({
    required this.name,
    required this.type,
    required this.url,
    this.ext,
  });

  factory Parse.fromJson(Map<String, dynamic> json) => _$ParseFromJson(json);
  Map<String, dynamic> toJson() => _$ParseToJson(this);
}

@JsonSerializable(explicitToJson: true)
class ParseExt {
  final List<String>? flag;
  final Map<String, String>? header;

  ParseExt({this.flag, this.header});

  factory ParseExt.fromJson(Map<String, dynamic> json) => _$ParseExtFromJson(json);
  Map<String, dynamic> toJson() => _$ParseExtToJson(this);
}

/// 直播配置
@JsonSerializable(explicitToJson: true)
class Live {
  final String name;
  final String? url;
  final String? api;
  final String? ext;
  final String? jar;
  final String? click;
  final String? logo;
  final String? epg;
  final String? ua;
  final String? origin;
  final String? referer;
  final String? timeZone;
  final int? timeout;
  final Map<String, String>? header;
  final Catchup? catchup;
  final List<Group>? groups;
  final bool? boot;
  final bool? pass;

  Live({
    required this.name,
    this.url,
    this.api,
    this.ext,
    this.jar,
    this.click,
    this.logo,
    this.epg,
    this.ua,
    this.origin,
    this.referer,
    this.timeZone,
    this.timeout,
    this.header,
    this.catchup,
    this.groups,
    this.boot,
    this.pass,
  });

  factory Live.fromJson(Map<String, dynamic> json) => _$LiveFromJson(json);
  Map<String, dynamic> toJson() => _$LiveToJson(this);
}

/// 频道分组
@JsonSerializable(explicitToJson: true)
class Group {
  final String name;
  final String? pass;
  final List<Channel> channel;

  Group({
    required this.name,
    this.pass,
    required this.channel,
  });

  factory Group.fromJson(Map<String, dynamic> json) => _$GroupFromJson(json);
  Map<String, dynamic> toJson() => _$GroupToJson(this);
}

/// 频道
@JsonSerializable(explicitToJson: true)
class Channel {
  final String name;
  final List<String> urls;
  final String? number;
  final String? logo;
  final String? epg;
  final String? ua;
  final String? click;
  final String? format;
  final String? origin;
  final String? referer;
  final String? tvgId;
  final String? tvgName;
  final Map<String, String>? header;
  final int? parse;
  final Catchup? catchup;
  final Drm? drm;

  Channel({
    required this.name,
    required this.urls,
    this.number,
    this.logo,
    this.epg,
    this.ua,
    this.click,
    this.format,
    this.origin,
    this.referer,
    this.tvgId,
    this.tvgName,
    this.header,
    this.parse,
    this.catchup,
    this.drm,
  });

  factory Channel.fromJson(Map<String, dynamic> json) => _$ChannelFromJson(json);
  Map<String, dynamic> toJson() => _$ChannelToJson(this);
}

/// 追看/时移配置
@JsonSerializable(explicitToJson: true)
class Catchup {
  final String? type;
  final String? regex;
  final String? source;
  final String? replace;

  Catchup({
    this.type,
    this.regex,
    this.source,
    this.replace,
  });

  factory Catchup.fromJson(Map<String, dynamic> json) => _$CatchupFromJson(json);
  Map<String, dynamic> toJson() => _$CatchupToJson(this);
}

/// DRM 配置
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

/// 样式配置
@JsonSerializable(explicitToJson: true)
class Style {
  final String? type;
  final double? ratio;

  Style({this.type, this.ratio});

  factory Style.fromJson(Map<String, dynamic> json) => _$StyleFromJson(json);
  Map<String, dynamic> toJson() => _$StyleToJson(this);
}

/// DNS over HTTPS
@JsonSerializable(explicitToJson: true)
class Doh {
  final String name;
  final String url;
  final List<String> ips;

  Doh({
    required this.name,
    required this.url,
    required this.ips,
  });

  factory Doh.fromJson(Map<String, dynamic> json) => _$DohFromJson(json);
  Map<String, dynamic> toJson() => _$DohToJson(this);
}

/// 代理配置
@JsonSerializable(explicitToJson: true)
class Proxy {
  final String name;
  final List<String> hosts;
  final List<String> urls;

  Proxy({
    required this.name,
    required this.hosts,
    required this.urls,
  });

  factory Proxy.fromJson(Map<String, dynamic> json) => _$ProxyFromJson(json);
  Map<String, dynamic> toJson() => _$ProxyToJson(this);
}

/// 网络规则
@JsonSerializable(explicitToJson: true)
class Rule {
  final String name;
  final List<String> hosts;
  final List<String> regex;
  final List<String> script;
  final List<String> exclude;

  Rule({
    required this.name,
    required this.hosts,
    required this.regex,
    required this.script,
    required this.exclude,
  });

  factory Rule.fromJson(Map<String, dynamic> json) => _$RuleFromJson(json);
  Map<String, dynamic> toJson() => _$RuleToJson(this);
}

/// 响应头注入
@JsonSerializable(explicitToJson: true)
class Header {
  final String host;
  final Map<String, String> header;

  Header({
    required this.host,
    required this.header,
  });

  factory Header.fromJson(Map<String, dynamic> json) => _$HeaderFromJson(json);
  Map<String, dynamic> toJson() => _$HeaderToJson(this);
}
