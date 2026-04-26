# FongMi/TV 相关文档

本目录包含从 FongMi/TV 项目复制的核心文档，详细说明了配置格式、爬虫 API、本地 HTTP API 和直播源格式。

## 文档列表

### 1. [SPIDER.md](SPIDER.md) - 爬虫 API 规格说明

详细说明如何实作 Spider 爬虫，包含：
- 爬虫类型与载入方式（Type 0/1/3/4）
- Spider 抽象类别的所有方法
- 回传资料结构（Result、Vod、Class、Filter、Danmaku、Sub、Drm 等）
- 完整 JSON 范例
- 爬虫本地代理 URL

### 2. [CONFIG.md](CONFIG.md) - 配置说明

详细说明 Vod（点播）与 Live（直播）配置档案的 JSON 结构：
- Vod 配置（VodConfig）：sites、parses、lives、doh、proxy、rules 等
- Live 配置（LiveConfig）：groups、channel、catchup 等
- 共用栏位物件：doh、proxy、rules、headers、hosts、ads、catchup、style

### 3. [LOCAL.md](LOCAL.md) - 本地 HTTP API

详细说明应用启动后提供的本地 HTTP API（端口 9978-9998）：
- `/action` - 动作指令（play/pause/stop/prev/next/refresh/push/file/search 等）
- `/cache` - 快取操作
- `/media` - 播放状态
- `/file` - 本地档案系统
- `/upload` - 上传档案
- `/parse` - 解析页面
- `/proxy` - 爬虫代理
- `/device` - 装置资讯

### 4. [LIVE.md](LIVE.md) - 直播来源格式说明

详细说明三种直播来源格式：
- **TXT 格式**: 分組 + 頻道，支援多線路和行內標頭
- **M3U 格式**: `#EXTM3U` + `#EXTINF`，支援 XMLTV EPG 和 DRM 宣告
- **JSON 格式**: `Group` 物件陣列

## 兼容性说明

MBox 项目完全兼容 FongMi/TV 的配置格式和 API 规范：

1. **配置兼容**: 直接使用 FongMi/TV 的配置文件（`.json`）
2. **爬虫兼容**: 支持相同的 Spider 接口和返回格式
3. **API 兼容**: 本地 HTTP API 端点保持一致
4. **直播源兼容**: 完全支持 M3U/TXT/JSON 格式

## 原始链接

- [SPIDER.md](https://github.com/FongMi/TV/blob/fongmi/docs/SPIDER.md)
- [CONFIG.md](https://github.com/FongMi/TV/blob/fongmi/docs/CONFIG.md)
- [LOCAL.md](https://github.com/FongMi/TV/blob/fongmi/docs/LOCAL.md)
- [LIVE.md](https://github.com/FongMi/TV/blob/fongmi/docs/LIVE.md)
