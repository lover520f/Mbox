# TVBox/FongMi 架构对比检查清单

## 核心模块对比

### 1. 网络层 (Network Layer)

#### FongMi/TV 实现
- OkHttp3 作为 HTTP 客户端
- DNS over HTTPS (DoH) 支持
- 代理支持 (HTTP/SOCKS)
- Hosts 文件覆盖
- 自定义 Header 注入
- 广告拦截规则

#### MBox 当前状态
- [x] Dio 作为 HTTP 客户端 ✅
- [x] Hosts 覆盖 ✅
- [ ] DoH 实现不完整 ⚠️
- [ ] 代理设置未实际生效 ⚠️
- [x] 自定义 Header ✅
- [ ] 广告拦截未实现 ❌

### 2. 配置解析 (Config Parser)

#### FongMi/TV 实现
- JSON 配置 (Type 1/4)
- XML 配置 (Type 0)
- Base64 编码 ext 字段
- 多站点支持
- 解析器 (Parse) 配置
- 直播源 (Live) 配置

#### MBox 当前状态
- [x] JSON 配置 ✅
- [x] XML 配置 ✅
- [ ] Base64 ext 解码 ⚠️
- [x] 多站点支持 ✅
- [x] 解析器配置 ✅
- [x] 直播源配置 ✅

### 3. 爬虫引擎 (Spider Engine)

#### FongMi/TV 实现
- Type 0: XML (HTTP 请求)
- Type 1: JSON (HTTP 请求)
- Type 3: JAR/JS/Python
- Type 4: JSON+Base64

#### MBox 当前状态
- [ ] Type 0: XML ⚠️
- [ ] Type 1: JSON ⚠️
- [ ] Type 3: JAR ❌
- [ ] Type 3: JS (QuickJS) ❌
- [ ] Type 3: Python ❌
- [ ] Type 4: JSON+Base64 ❌

### 4. 播放器 (Player)

#### FongMi/TV 实现
- ExoPlayer (Media3)
- FFmpeg 软解
- 自动硬解/软解切换
- 弹幕支持
- 字幕支持
- 倍速播放
- 选集播放

#### MBox 当前状态
- [x] 基础播放器 ✅
- [ ] FFmpeg 集成 ⚠️
- [ ] 弹幕功能 ❌
- [x] 字幕支持 ✅
- [x] 倍速播放 ✅
- [ ] 选集播放 ⚠️

### 5. 数据模型 (Models)

#### FongMi/TV 实现
- Vod (影片卡片)
- Site (站点配置)
- Parse (解析器)
- Live (直播)
- Class (分类)
- Filter (筛选器)
- Result (返回结果)

#### MBox 当前状态
- [x] Vod ✅
- [x] Site ✅
- [x] Parse ✅
- [x] Live ✅
- [ ] Class (分类) ❌
- [ ] Filter (筛选器) ❌
- [ ] Result ❌

### 6. UI 功能

#### FongMi/TV 实现
- 首页 (分类导航)
- 详情 (选集列表)
- 播放 (播放控制)
- 搜索
- 历史记录
- 收藏
- 设置

#### MBox 当前状态
- [x] 首页 ✅
- [x] 详情 ✅
- [x] 播放 ✅
- [ ] 搜索 ⚠️
- [ ] 历史记录 ❌
- [ ] 收藏 ❌
- [x] 设置 ✅

---

## 需要立即修复的问题

### P0 - 严重问题

1. **爬虫引擎未实现**
   - Type 0/1 需要实现 HTTP 请求调用远端 API
   - 需要实现 homeContent, categoryContent, detailContent, searchContent, playerContent 方法

2. **配置解析不完整**
   - ext 字段 Base64 解码
   - jar 字段 JAR 加载

3. **网络问题**
   - DNS 解析问题（中文域名）
   - 连接超时设置

### P1 - 高优先级

4. **数据模型缺失**
   - Vod 模型补全所有字段
   - Class 分类模型
   - Filter 筛选器模型

5. **播放器功能**
   - 选集播放
   - 历史记录

### P2 - 中优先级

6. **广告拦截**
7. **DoH 完整实现**
8. **代理功能**

---

## 执行计划

### 第一阶段：核心功能（本次）
1. ✅ 修复网络请求
2. ✅ 修复配置解析
3. ⏳ 实现爬虫引擎 (Type 0/1)
4. ⏳ 补全数据模型

### 第二阶段：增强功能
5. 实现搜索功能
6. 实现历史记录
7. 完善播放器

### 第三阶段：高级功能
8. JAR/JS/Python 爬虫
9. 弹幕功能
10. DLNA 投放
