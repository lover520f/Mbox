# MBox 项目架构文档

## 1. 项目概述

MBox 是一款基于 Flutter 开发的全平台影音播放器，参考 FongMi/TV 项目架构设计，支持 Android TV（Leanback）和 Android 手机（Mobile）双版本。

### 1.1 核心特性

- **双 UI 架构**: TV 版使用 Leanback 风格，手机版使用 Material Design
- **多源支持**: 支持多种在线源和本地源
- **爬虫引擎**: 支持 Java JAR、JavaScript（QuickJS）、Python（Chaquopy）三种爬虫
- **播放器核心**: 基于 ExoPlayer（Media3）+ FFmpeg，支持硬解/软解自动切换
- **DRM 支持**: Widevine、PlayReady、ClearKey
- **弹幕功能**: DanmakuFlameMaster，与播放时间轴精确同步
- **字幕支持**: SRT/SSA/ASS 外挂字幕
- **DLNA 投放**: 支持 DMC（投放端）和 DMR（被投放端）
- **远程控制**: 本地 HTTP 服务器（9978-9998 端口）

## 2. 项目结构

```
mbox/
├── android/                      # Android 原生层
│   ├── app/                      # 主应用模块
│   │   ├── src/main/             # 共用业务逻辑
│   │   ├── src/leanback/         # TV 版 UI
│   │   └── src/mobile/           # 手机版 UI
│   ├── catvod/                   # 爬虫抽象层（Spider 接口）
│   ├── quickjs/                  # QuickJS JavaScript 引擎
│   └── chaquo/                   # Chaquopy Python 引擎
├── lib/                          # Flutter 共享代码
│   ├── main.dart                 # 应用入口
│   ├── app.dart                  # 应用配置
│   ├── config/                   # 配置管理
│   │   ├── app_config.dart       # 应用配置类
│   │   └── theme_config.dart     # 主题配置
│   ├── crawler/                  # 爬虫层
│   │   ├── spider.dart           # Spider 抽象基类
│   │   └── spider_loader.dart    # Spider 加载器
│   ├── player/                   # 播放器核心
│   │   └── mbox_player_controller.dart
│   ├── network/                  # 网络功能
│   │   └── okhttp_client.dart    # HTTP 客户端
│   ├── database/                 # 数据库
│   ├── models/                   # 数据模型
│   │   ├── vod_config.dart       # Vod 配置模型
│   │   └── vod.dart              # Vod 数据模型
│   ├── provider/                 # 状态管理
│   │   ├── app_provider.dart
│   │   ├── config_provider.dart
│   │   └── player_provider.dart
│   ├── utils/                    # 工具类
│   │   ├── log_utils.dart
│   │   ├── device_utils.dart
│   │   └── locale_utils.dart
│   ├── routes/                   # 路由配置
│   │   └── app_routes.dart
│   ├── screens/                  # 页面
│   │   ├── home/
│   │   ├── vod/
│   │   ├── live/
│   │   └── settings/
│   └── widgets/                  # 通用组件
├── packages/                     # 子模块
│   ├── catvod_spider/            # 爬虫抽象包
│   ├── quickjs_engine/           # JS 引擎封装
│   └── python_engine/            # Python 引擎封装
└── docs/                         # 文档
```

## 3. 核心模块设计

### 3.1 爬虫层（Crawler Layer）

爬虫层位于 `lib/crawler/` 目录，实现了 FongMi/TV 的 Spider 抽象接口。

#### Spider 抽象基类

```dart
abstract class Spider {
  String siteKey = '';
  
  // 生命周期方法
  Future<void> init(dynamic context, String extend);
  Future<String> homeContent(bool filter);
  Future<String> homeVideoContent();
  Future<String> categoryContent(String tid, String pg, bool filter, HashMap<String, String> extend);
  Future<String> detailContent(List<String> ids);
  Future<String> searchContent(String key, bool quick, [String pg]);
  Future<String> playerContent(String flag, String id, List<String> vipFlags);
  Future<String> liveContent(String url);
  Future<Object[]> proxy(Map<String, String> params);
  Future<String> action(String action);
  Future<bool> manualVideoCheck();
  Future<bool> isVideoFormat(String url);
  Future<void> destroy();
}
```

#### SpiderLoader

负责加载不同类型的爬虫：
- **Type 0**: XML 格式（HTTP 请求）
- **Type 1**: JSON 格式（HTTP 请求）
- **Type 3**: Spider 直接呼叫（JAR/JS/Python）
- **Type 4**: JSON+Base64 ext

### 3.2 播放器核心（Player Core）

播放器基于 `media_kit` 库（封装 ExoPlayer/FFmpeg）实现：

```dart
class MBoxPlayerController {
  // 核心功能
  Future<void> play({String url, headers, subtitles, danmakus, drm});
  Future<void> pause();
  Future<void> resume();
  Future<void> stop();
  Future<void> seek(Duration position);
  Future<void> setSpeed(double speed);
  
  // 高级功能
  Future<void> next();     // 下一集
  Future<void> prev();     // 上一集
  Future<void> replay();   // 重新播放
  Future<void> toggleRepeat(); // 循环播放
}
```

### 3.3 网络层（Network Layer）

网络层实现了以下功能：

1. **OkHttpUtils**: 封装 HTTP 请求
2. **DoH 支持**: DNS over HTTPS
3. **代理支持**: HTTP/HTTPS/SOCKS4/SOCKS5
4. **Hosts 覆盖**: DNS 解析覆盖
5. **CORS 注入**: 响应头注入
6. **广告拦截**: 域名黑名单

### 3.4 配置管理（Configuration）

配置格式完全兼容 FongMi/TV 的 JSON 格式：

```json
{
  "spider": "https://xxx.jar",
  "sites": [...],
  "parses": [...],
  "lives": [...],
  "doh": [...],
  "proxy": [...],
  "rules": [...],
  "hosts": [...],
  "ads": [...]
}
```

详细字段说明见：
- `docs/CONFIG.md` - 配置字段说明
- `docs/SPIDER.md` - 爬虫 API 规格
- `docs/LIVE.md` - 直播源格式

## 4. UI 架构

### 4.1 双 UI 架构

根据设备类型自动切换 UI：

```dart
class HomeScreen {
  Widget build() {
    if (isTV) {
      return LeanbackHomeScreen();  // TV 版
    } else {
      return MobileHomeScreen();    // 手机版
    }
  }
}
```

### 4.2 TV 版（Leanback）

- 左侧导航栏 + 右侧内容区
- 支持遥控器方向键操作
- 大字体、大间距设计

### 4.3 手机版（Material Design）

- BottomNavigationBar 导航
- 支持手势操作
- 响应式布局

## 5. 状态管理

使用 Provider 进行状态管理：

- **AppProvider**: 应用级状态（加载、主题等）
- **ConfigProvider**: 配置状态
- **PlayerProvider**: 播放器状态

## 6. 数据持久化

- **Hive**: 本地数据库（观看记录、收藏等）
- **SharedPreferences**: 简单配置存储

## 7. 本地 HTTP API

应用启动后会在 9978-9998 端口启动 HTTP 服务器，提供以下 API：

### 7.1 播放控制

```
/action?do=control&type=play|pause|stop|prev|next|repeat|replay
```

### 7.2 内容推送

```
/action?do=push&url={media_url}
/action?do=refresh&type=subtitle|danmaku&path={url}
```

### 7.3 配置管理

```
/action?do=setting&text={config_json}&name={name}
```

### 7.4 设备信息

```
/device - 获取设备信息
```

完整 API 列表见 `docs/LOCAL.md`。

## 8. 待完善功能

以下是需要在后续版本中实现的功能：

### 8.1 高优先级

- [ ] JAR 爬虫加载（DexClassLoader）
- [ ] JavaScript 爬虫（QuickJS）
- [ ] Python 爬虫（Chaquopy）
- [ ] 直播功能完整实现（M3U/TXT/JSON 解析）
- [ ] 弹幕功能（DanmakuFlameMaster）
- [ ] 字幕解析（SRT/SSA/ASS）

### 8.2 中优先级

- [ ] 观看记录和收藏功能
- [ ] 广告拦截和 WebView 嗹探
- [ ] DLNA 投放（Cling 2.1.1）
- [ ] 画中画（PiP）模式
- [ ] 倍速播放
- [ ] 片头/片尾自动跳过

### 8.3 优化项

- [ ] 性能优化
- [ ] 内存管理
- [ ] 错误处理增强
- [ ] 单元测试
- [ ] UI/UX 优化

## 9. 开发指南

### 9.1 环境要求

- Flutter 3.x+
- Dart 3.x+
- Android SDK 24+
- Android Studio / VS Code

### 9.2 代码风格

遵循 `analysis_options.yaml` 中的 Lint 规则：
- 使用 `const` 构造函数
- 使用 `final` 字段
- 避免 `print`，使用 `Log` 工具类
- 使用单一引号

### 9.3 提交规范

分支命名规范：`YYMMDD-(feat|fix|chore|refactor)-xxxxx`

示例：
- `260204-feat-add-player-ui`
- `260204-fix-search-crash`

## 10. 参考资料

- [FongMi/TV 源码](https://github.com/FongMi/TV/tree/fongmi)
- [CONFIG.md](docs/CONFIG.md) - 配置说明
- [SPIDER.md](docs/SPIDER.md) - 爬虫 API
- [LOCAL.md](docs/LOCAL.md) - 本地 API
- [LIVE.md](docs/LIVE.md) - 直播源格式
