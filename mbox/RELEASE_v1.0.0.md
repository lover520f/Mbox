# MBox v1.0.0 发布说明

## 🎉 发布信息

- **版本**: v1.0.0
- **发布日期**: 2026-04-26
- **完成度**: 100%
- **代码量**: ~16,000+ 行

## ✨ 主要功能

### 📺 双 UI 架构
- **TV 版 (Leanback)**: 遥控器友好，横屏优化，网格布局
- **手机版 (Material Design)**: 手势支持，响应式设计，卡片布局

### 🕷️ 爬虫引擎
- **JAR 爬虫**: DexClassLoader 加载 Java 爬虫
- **JS 爬虫**: QuickJS 引擎执行 JavaScript
- **Python 爬虫**: Chaquopy 集成 (可选)
- **完整 API**: homeContent, categoryContent, detailContent, searchContent, playerContent

### 💬 弹幕功能
- **格式支持**: JSON (Bilibili), XML
- **类型支持**: 滚动/顶部/底部
- **实时发送**: 用户弹幕输入
- **颜色支持**: 自定义弹幕颜色

### 📝 字幕支持
- **格式支持**: SRT, ASS/SSA, VTT
- **自动检测**: 根据扩展名和内容
- **字体调节**: 12-32px 可调
- **多字幕切换**: 外挂字幕支持

### 🖥️ DLNA 投屏
- **Cling 2.1.1**: 完整 UPnP/DLNA支持
- **设备搜索**: 自动发现 DMR 设备
- **视频投屏**: 推送视频到电视
- **播放控制**: 播放/暂停/停止/跳转

### 🔐 DRM 支持
- **Widevine**: Google DRM 方案
- **PlayReady**: Microsoft DRM 方案
- **ClearKey**: 简单密钥方案

### 🌐 HTTP 服务器
- **端口范围**: 9978-9998
- **完整 API**: 播放控制/配置管理/搜索/详情
- **代理功能**: 爬虫 proxy 接口
- **ADB 推送**: 远程内容推送

### 📡 直播功能
- **三格式解析**: M3U (EXTM3U), TXT (genre#), JSON
- **EPG 节目单**: XMLTV/JSON格式
- **多线路支持**: 自动切换
- **追看时移**: 回看功能

## 📊 技术栈

### Flutter 层
- Flutter 3.x
- Dart SDK >=3.0.0
- media_kit (ExoPlayer/FFmpeg)
- provider (状态管理)
- get (路由)
- danmaku (弹幕)
- dio/http (网络)
- hive (本地存储)

### Android 原生层
- Java 8
- Cling 2.1.1 (DLNA)
- QuickJS (JavaScript)
- NanoHTTPD (HTTP 服务器)
- Media3 (ExoPlayer)
- DexClassLoader (JAR 加载)

## 📦 安装与构建

### 开发环境运行
```bash
# 安装依赖
flutter pub get

# TV 版
flutter run --flavor leanback -t lib/main_leanback.dart

# 手机版
flutter run --flavor mobile -t lib/main_mobile.dart
```

### 构建 APK
```bash
# 分 ABI 构建 (推荐)
flutter build apk --split-per-abi

# 通用 APK
flutter build apk

# Release 版本
flutter build apk --release
```

### 输出位置
- APK 文件：`build/app/outputs/flutter-apk/`
- TV 版：`app-leanback-release.apk`
- 手机版：`app-mobile-release.apk`

## 📱 系统要求

- **Android 版本**: 7.0+ (API 24)
- **CPU 架构**: armeabi-v7a, arm64-v8a
- **内存**: 建议 2GB+
- **存储**: 建议 500MB+ 可用空间

## 🔧 配置说明

### 配置文件格式
支持 JSON 格式配置，包含：
- `sites`: 点播站点
- `lives`: 直播源
- `parses`: 解析器
- `doh`: DNS over HTTPS
- `proxy`: 代理设置
- `rules`: 广告规则

### 配置加载方式
1. **URL 加载**: 输入配置 URL
2. **本地文件**: 选择 JSON 文件
3. **JSON 粘贴**: 直接粘贴配置内容

## 📖 使用指南

### 第一次使用
1. 启动应用
2. 进入设置页面
3. 加载配置文件 (URL/本地/粘贴)
4. 返回首页浏览内容

### 点播播放
1. 首页选择站点
2. 浏览分类或搜索内容
3. 点击进入详情页
4. 选择剧集开始播放
5. 使用弹幕/字幕功能

### 直播观看
1. 进入直播页面
2. 选择分组和频道
3. 查看 EPG 节目单
4. 支持多线路切换

### DLNA 投屏
1. 确保手机和电视在同一网络
2. 播放器页面点击投屏图标
3. 选择 TV 设备
4. 开始投屏播放

## 🐛 已知问题

- 部分老旧设备可能存在兼容性问题
- Chaquopy Python 集成需要额外配置
- 某些 DRM 内容需要特定授权

## 📝 更新日志

### v1.0.0 (2026-04-26)
- ✅ 初始版本发布
- ✅ 完整双 UI 架构
- ✅ 爬虫引擎三语言支持
- ✅ 弹幕字幕功能
- ✅ DLNA 投屏
- ✅ DRM 支持
- ✅ HTTP 服务器
- ✅ 直播解析

## 📄 许可证

MIT License

## 👥 贡献

欢迎提交 Issue 和 Pull Request!

## 🔗 链接

- **GitHub**: [项目地址]
- **文档**: /docs 目录
- **反馈**: Issues

---

**MBox Team**  
Made with ❤️ using Flutter
