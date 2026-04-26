# 快速开始指南

## 1. 环境准备

### 1.1 安装 Flutter

1. 下载 Flutter SDK：https://docs.flutter.dev/get-started/install
2. 配置环境变量
3. 运行 `flutter doctor` 检查环境

### 1.2 开发工具

- **Android Studio**（推荐）
  - 安装 Flutter 插件
  - 安装 Dart 插件
  
- **VS Code**
  - 安装 Flutter 插件
  - 安装 Dart 插件

## 2. 项目设置

### 2.1 克隆项目

```bash
git clone <repository-url>
cd mbox
```

### 2.2 安装依赖

```bash
flutter pub get
```

### 2.3 生成代码

项目使用 `json_serializable` 生成 JSON 序列化代码：

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## 3. 配置说明

### 3.1 配置文件格式

MBox 完全兼容 FongMi/TV 的配置格式。配置文件为 JSON 格式，包含：

- **spider**: 全局爬虫 JAR 路径
- **sites**: 点播来源列表
- **parses**: 解析规则列表
- **lives**: 直播来源列表
- **doh**: DNS over HTTPS 设置
- **proxy**: 代理设置
- **ads**: 广告过滤列表

### 3.2 示例配置

```json
{
  "spider": "https://example.com/spider.jar",
  "sites": [
    {
      "key": "push_agent",
      "name": "推送",
      "type": 3,
      "api": "csp_Push"
    }
  ],
  "lives": [
    {
      "name": "直播",
      "url": "https://example.com/live.m3u",
      "epg": "https://example.com/epg.xml"
    }
  ],
  "parses": [
    {
      "name": "解析 1",
      "type": 1,
      "url": "https://example.com/parse?url="
    }
  ]
}
```

### 3.3 加载配置

启动应用后，有多种方式加载配置：

#### 方式 1：直接输入配置 URL

```
http://your-domain/config.json
```

#### 方式 2：推送配置

通过本地 HTTP API 推送配置：

```bash
curl "http://127.0.0.1:9978/action?do=setting&text={config_json}&name=我的配置"
```

#### 方式 3：扫码加载

生成配置 URL 的二维码，使用扫码功能加载。

## 4. 运行应用

### 4.1 调试模式

```bash
# 手机版
flutter run --flavor mobile -t lib/main_mobile.dart

# TV 版
flutter run --flavor leanback -t lib/main_leanback.dart
```

### 4.2 打包发布

```bash
# 打包手机版 APK
flutter build apk --flavor mobile -t lib/main_mobile.dart

# 打包 TV 版 APK
flutter build apk --flavor leanback -t lib/main_leanback.dart
```

## 5. 功能使用

### 5.1 点播功能

1. 加载配置后，进入首页
2. 浏览推荐内容或选择分类
3. 点击影片卡片查看详情
4. 选择播放线路和集数
5. 开始播放（支持倍速、弹幕、字幕等）

### 5.2 直播功能

1. 切换到"直播"标签
2. 选择频道分组
3. 选择频道开始播放
4. 支持 EPG 节目单显示

### 5.3 搜索功能

1. 进入搜索页面
2. 输入关键字
3. 多站点并行搜索
4. 选择结果播放

### 5.4 推送播放

通过本地 HTTP API 推送视频 URL：

```bash
curl "http://127.0.0.1:9978/action?do=push&url=https://example.com/video.m3u8"
```

### 5.5 播放控制

```bash
# 播放
curl "http://127.0.0.1:9978/action?do=control&type=play"

# 暂停
curl "http://127.0.0.1:9978/action?do=control&type=pause"

# 下一集
curl "http://127.0.0.1:9978/action?do=control&type=next"

# 推送字幕
curl "http://127.0.0.1:9978/action?do=refresh&type=subtitle&path=http://example.com/sub.srt"
```

## 6. 自定义开发

### 6.1 添加新的爬虫

参考 `docs/SPIDER.md` 实现 Spider 抽象类：

```dart
class MySpider extends Spider {
  @override
  Future<String> homeContent(bool filter) async {
    // 实现首页分类
  }
  
  @override
  Future<String> playerContent(String flag, String id, List<String> vipFlags) async {
    // 实现播放解析
  }
}
```

### 6.2 添加新的 UI 主题

修改 `lib/config/theme_config.dart`：

```dart
class ThemeConfig {
  static ThemeData customTheme = ThemeData(
    primaryColor: Colors.blue,
    // ...
  );
}
```

### 6.3 添加新的功能

按照项目架构，在对应目录添加代码：
- 新页面：`lib/screens/`
- 新组件：`lib/widgets/`
- 新工具：`lib/utils/`
- 新模型：`lib/models/`

## 7. 故障排除

### 7.1 常见问题

**Q: 配置加载失败？**
A: 检查配置 JSON 格式是否正确，网络连接是否正常。

**Q: 视频无法播放？**
A: 检查视频 URL 是否有效，是否需要解析器，是否需要特定的 User-Agent。

**Q: 弹幕/字幕不显示？**
A: 检查弹幕/字幕 URL 是否可访问，格式是否正确。

**Q: HTTP API 无法访问？**
A: 检查端口是否正确（9978-9998），防火墙是否阻止。

### 7.2 查看日志

应用日志会输出到控制台，使用以下命令查看：

```bash
# Android
adb logcat | grep MBox

# Flutter 调试
flutter run --verbose
```

## 8. 参考资料

- [架构文档](ARCHITECTURE.md) - 项目架构说明
- [CONFIG.md](CONFIG.md) - 配置字段说明
- [SPIDER.md](SPIDER.md) - 爬虫 API 规格
- [LOCAL.md](LOCAL.md) - 本地 HTTP API
- [LIVE.md](LIVE.md) - 直播源格式

## 9. 获取帮助

遇到问题？

1. 查看 [README.md](../README.md) 了解项目功能
2. 查看 `docs/` 目录下的详细文档
3. 检查已解决的 Issue
4. 提交新的 Issue 寻求帮助
