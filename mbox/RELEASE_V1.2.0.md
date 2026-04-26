# 魔宝盒 MBox v1.2.0 发布说明

📅 发布日期：2026-04-26

## ✨ 新增功能

### 爬虫引擎 🕷️
- ✅ 实现完整的 JS 爬虫引擎
- ✅ 使用 WebView 作为 JavaScript 运行时
- ✅ 支持爬虫方法：home、category、detail、play、search
- ✅ 提供测试用 JS 爬虫脚本

### 配置系统 ⚙️
- ✅ 支持从 URL 加载配置
- ✅ 多站点管理和切换
- ✅ 配置加载对话框
- ✅ 站点选择对话框

### UI 改进 🎨
- ✅ 首页展示分类列表
- ✅ 站点切换按钮
- ✅ 空状态引导界面
- ✅ 加载状态提示

## 🔧 技术变更

### Android 原生层
- 使用 WebView 作为 JS 引擎（替代 QuickJS）
- 完善的 Method Channel 实现
- 支持从 assets 加载 JS 脚本

### Flutter 层
- 爬虫引擎统一接口 (SpiderEngine)
- 配置 Provider 完善
- 首页数据加载逻辑

### 构建配置
- 只构建 ARM 架构（32 位和 64 位）
- 移除 x86_64 和 universal APK
- 减小 APK 体积

## 📦 APK 文件

本次构建生成 4 个 APK 文件：

### TV 版 (Leanback)
- `app-leanback-arm64-v8a-release.apk` (25MB) - 64 位 ARM
- `app-leanback-armeabi-v7a-release.apk` (22MB) - 32 位 ARM

### 手机版 (Mobile)
- `app-mobile-arm64-v8a-release.apk` (25MB) - 64 位 ARM
- `app-mobile-armeabi-v7a-release.apk` (22MB) - 32 位 ARM

## 📋 使用指南

### 加载配置

1. 打开应用
2. 点击"加载配置"按钮
3. 输入配置接口地址（JSON 格式）
4. 确认加载

### 切换站点

1. 点击首页右上角的站点名称
2. 从列表中选择要切换的站点
3. 自动重新加载该站点的内容

### 浏览内容

- 左右滑动查看分类
- 上下滑动查看影片列表
- 点击影片卡片查看详情

## 🐛 已知问题

- 详情页尚未实现
- 播放器功能待完善
- 直播功能待实现
- 搜索功能待实现

## 📱 系统要求

- Android 7.0 (API 24) 及以上版本
- 支持 ARMv7 或 ARM64 架构设备
- TV 版仅限 Android TV 设备

## 🔗 下载链接

GitHub Release: https://github.com/lover520f/Mbox/releases/tag/v1.2.0

---

**注意**: 此版本为测试版本，部分功能尚未完善。
