# MBox - Flutter 全平台影音播放器

基于 Flutter 开发的全平台媒体播放器，参考 FongMi/TV 项目架构，支持 Android TV（Leanback）和 Android 手机（Mobile）双版本。

## 功能特性

### 核心功能
- [x] ExoPlayer（Media3）+ FFmpeg 软解/硬解自动切换
- [x] 支持 Widevine、PlayReady、ClearKey DRM
- [x] 弹幕功能（DanmakuFlameMaster）
- [x] 多格式字幕（SRT/SSA/ASS）
- [x] 倍速播放、画中画、后台音频
- [x] 片头/片尾自动跳过

### 点播功能
- [ ] 多站点分类浏览和筛选
- [ ] 多站点并行搜索
- [ ] 播放失败自动换源
- [ ] 观看记录（60 天）
- [ ] 收藏和无痕模式
- [ ] 遥控器操作（TV 版）
- [ ] 手势控制（手机版）

### 直播功能
- [ ] M3U/TXT/JSON 格式支持
- [ ] EPG 节目表（XMLTV）
- [ ] 追看/时移功能
- [ ] 频道收藏和隐藏分组

### 爬虫引擎
- [ ] Java JAR（DexClassLoader）
- [ ] JavaScript（QuickJS）
- [ ] Python（Chaquopy）

### 网络功能
- [ ] DNS over HTTPS（DoH）
- [ ] HTTP/HTTPS/SOCKS 代理
- [ ] Hosts DNS 解析覆盖
- [ ] CORS 注入
- [ ] 广告拦截
- [ ] WebView 嗅探

### DLNA 投放
- [ ] DMC（投放端）- 手机版
- [ ] DMR（被投放端）- 电视版

### 远程控制
- [ ] 本地 HTTP 服务器（9978-9998 端口）
- [ ] 播放控制 API
- [ ] 字幕/弹幕推送
- [ ] 多设备同步

## 项目结构

```
mbox/
├── android/                  # Android 原生层
│   ├── app/                  # 主应用
│   │   ├── src/main/         # 共用业务逻辑
│   │   ├── src/leanback/     # TV 版本 UI
│   │   └── src/mobile/       # 手机版 UI
│   ├── catvod/               # 爬虫抽象层
│   ├── quickjs/              # JavaScript 引擎
│   └── chaquo/               # Python 引擎
├── lib/                      # Flutter 共享代码
│   ├── main.dart             # 应用入口
│   ├── app.dart              # 应用配置
│   ├── config/               # 配置管理
│   ├── crawler/              # 爬虫层
│   ├── player/               # 播放器核心
│   ├── network/              # 网络功能
│   ├── database/             # 数据库
│   ├── models/               # 数据模型
│   ├── provider/             # 状态管理
│   ├── utils/                # 工具类
│   ├── leanback/             # TV 版 UI
│   └── mobile/               # 手机版 UI
├── packages/                 # 子模块
│   ├── catvod_spider/        # 爬虫抽象包
│   ├── quickjs_engine/       # JS 引擎封装
│   └── python_engine/        # Python 引擎封装
└── docs/                     # 文档
```

## 开发环境要求

- Flutter 3.x+
- Dart 3.x+
- Android SDK 24+
- Android Studio / VS Code

## 构建说明

### TV 版（Leanback）
```bash
flutter build apk --flavor leanback -t lib/main_leanback.dart
```

### 手机版（Mobile）
```bash
flutter build apk --flavor mobile -t lib/main_mobile.dart
```

## 配置说明

详细配置请参考：
- [CONFIG.md](docs/CONFIG.md) - 配置字段说明
- [SPIDER.md](docs/SPIDER.md) - 爬虫 API 规格
- [LOCAL.md](docs/LOCAL.md) - 本地 HTTP API
- [LIVE.md](docs/LIVE.md) - 直播源格式

## 许可证

MIT License
