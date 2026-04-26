# 爬蟲 API 規格說明

本文件說明如何實作一個 Spider 爬蟲，包含所有方法的參數、回傳格式及 JSON 結構定義。

---

## 目錄

- [概覽](#概覽)
- [爬蟲類型與載入方式](#爬蟲類型與載入方式)
- [Spider 抽象類別](#spider-抽象類別)
    - [init — 初始化](#init--初始化)
    - [homeContent — 首頁分類](#homecontent--首頁分類)
    - [homeVideoContent — 首頁推薦影片](#homevideocontent--首頁推薦影片)
    - [categoryContent — 分類列表](#categorycontent--分類列表)
    - [detailContent — 影片詳情](#detailcontent--影片詳情)
    - [searchContent — 搜尋](#searchcontent--搜尋)
    - [playerContent — 播放解析](#playercontent--播放解析)
    - [liveContent — 直播頻道列表](#livecontent--直播頻道列表)
    - [proxy — 本地代理](#proxy--本地代理)
    - [action — 自定義動作](#action--自定義動作)
    - [manualVideoCheck / isVideoFormat — 影片格式判斷](#manualvideocheck--isvideoformat--影片格式判斷)
    - [destroy — 銷毀](#destroy--銷毀)
- [回傳資料結構](#回傳資料結構)
    - [Result — 通用回傳物件](#result--通用回傳物件)
    - [Vod — 影片卡片物件](#vod--影片卡片物件)
    - [Class — 分類物件](#class--分類物件)
    - [Filter — 篩選器物件](#filter--篩選器物件)
    - [Danmaku — 彈幕物件](#danmaku--彈幕物件)
    - [Sub — 字幕物件](#sub--字幕物件)
    - [Drm — DRM 設定物件](#drm--drm-設定物件)
    - [播放集數格式（vod_play_from / vod_play_url）](#播放集數格式 vod_play_from--vod_play_url)
- [完整 JSON 範例](#完整-json-範例)
    - [homeContent 回傳範例](#homecontent-回傳範例)
    - [homeVideoContent / categoryContent 回傳範例](#homevideocontent--categorycontent-回傳範例)
    - [detailContent 回傳範例](#detailcontent-回傳範例)
    - [playerContent 回傳範例](#playercontent-回傳範例)
    - [searchContent 回傳範例](#searchcontent-回傳範例)
    - [liveContent 回傳範例](#livecontent-回傳範例)
- [爬蟲本地代理 URL](#爬蟲本地代理-url)

---

## 概覽

Spider 是應用程式爬蟲的抽象基底類別，位於 `com.github.catvod.crawler.Spider`。每個影片來源（`Site`）對應一個 Spider 實例。

**生命週期：**

```
init(context, ext)
    │
    ├─► homeContent(filter)          首頁分類
    ├─► homeVideoContent()           首頁推薦
    ├─► categoryContent(...)         分類瀏覽
    ├─► detailContent(ids)           影片詳情
    ├─► searchContent(key, quick)    搜尋
    ├─► playerContent(flag, id, ...) 播放解析
    ├─► liveContent(url)             直播解析
    └─► destroy()                    清理資源
```

**欄位：**

| 欄位        | 類型       | 說明                             |
|-----------|----------|--------------------------------|
| `siteKey` | `String` | 由載入器注入，標識此 Spider 服務的來源`key`。 |

---

## 爬蟲類型與載入方式

在`sites`配置中，`type` 欄位決定呼叫方式，`api` 欄位決定載入哪種引擎：

| `type` | `api` 格式        | 引擎                  | 說明                                                         |
|--------|-----------------|---------------------|------------------------------------------------------------|
| `0`    | HTTP URL        | 內建 XML 解析           | 直接 GET 請求，回傳 XML 格式。                                       |
| `1`    | HTTP URL        | 內建 JSON+Filter      | 直接 GET 請求，回傳 JSON 格式，篩選參數以 `f=` 傳遞。                        |
| `3`    | `csp_ClassName` | JAR（DexClassLoader） | 從 `jar` 指定的 .jar 檔載入 `com.github.catvod.spider.ClassName`。 |
| `3`    | `xxx.js`        | JavaScript（QuickJS） | 載入 `.js` 檔作為 Spider。                                       |
| `3`    | `xxx.py`        | Python（Chaquopy）    | 載入 `.py` 檔作為 Spider。                                       |
| `4`    | HTTP URL        | 內建 JSON+Base64 ext  | 同 `1`，擴充參數以 Base64 編碼傳遞（`ext=`）。                           |

> 本文件主要說明 `type=3`（Spider 直接呼叫）的情境。

---

## Spider 抽象類別

所有方法預設回傳空字串 `""`，子類別僅需覆寫所需功能。

---

### init — 初始化

```java
public void init(Context context, String extend) throws Exception
```

**觸發時機：** Spider 實例建立後呼叫一次，用於初始化連線、載入設定等。

| 參數        | 類型        | 說明                                                    |
|-----------|-----------|-------------------------------------------------------|
| `context` | `Context` | Android Context，可取得應用資源、路徑等。                          |
| `extend`  | `String`  | 對應 `Site.ext` 欄位的額外擴充資料，內容由爬蟲自行定義（可為 URL、JSON 字串或路徑）。 |

**回傳：** 無（`void`）

---

## 回傳資料結構

所有方法（`proxy` 除外）的回傳值均為 JSON 字串，解析後對應以下物件。

### Result — 通用回傳物件

不同方法使用的欄位不同，以下按方法分組說明。

**homeContent：**

| JSON 欄位   | 類型             | 說明                                                                     |
|-----------|----------------|------------------------------------------------------------------------|
| `class`   | `array<Class>` | 分類列表。詳見 [Class](#class--分類物件)。                                         |
| `filters` | `object`       | 篩選器定義，key 為 `type_id`，value 為 `Filter` 陣列。詳見 [Filter](#filter--篩選器物件)。 |

**homeVideoContent / categoryContent / detailContent / searchContent：**

| JSON 欄位     | 類型           | 說明                                         |
|-------------|--------------|--------------------------------------------|
| `list`      | `array<Vod>` | 影片卡片列表。詳見 [Vod](#vod--影片卡片物件)。             |
| `pagecount` | `integer`    | 總頁數（`categoryContent`、`searchContent` 使用）。 |

**playerContent：**

| JSON 欄位    | 類型               | 說明                                                                                 |
|------------|------------------|------------------------------------------------------------------------------------|
| `url`      | `string`         | 實際播放媒體 URL。                                                                        |
| `parse`    | `integer`        | `0` = 直接播放，`1` = 需進一步解析（預設 `0`）。`jx=1` 效果相同。                                       |
| `jx`       | `integer`        | 同 `parse=1`，需進一步解析（兩者任一為 `1` 即觸發解析流程）。                                             |
| `playUrl`  | `string`         | 解析器前綴或指定。`json:…` 傳入 JSON 解析器，`parse:解析器名稱` 指定具名解析器，其他值作為解析 URL 前綴。                |
| `key`      | `string`         | 來源 `key`，用於從配置查找對應 `Site.click`。當爬蟲未回傳 `click` 時，框架以此 key 從 VodConfig 取得 click。    |
| `click`    | `string`         | 點擊攔截處理 URL，傳遞給解析器 WebView 執行點擊動作。                                                  |
| `code`     | `integer`        | 非零時抑制 `msg` 顯示（通常用於錯誤狀態碼）。                                                         |
| `header`   | `object`         | 播放請求的額外 HTTP 標頭，鍵值對格式。                                                             |
| `flag`     | `string`         | 播放來源旗標名稱，覆蓋原始 `flag` 參數。                                                           |
| `jxFrom`   | `string`         | 強制指定解析器旗標（覆蓋 `flag` 的解析器比對結果）。                                                     |
| `format`   | `string`         | 媒體 MIME type（如 `"application/x-mpegURL"`、`"application/dash+xml"`），指定後播放器跳過格式自動偵測。 |
| `danmaku`  | `array<Danmaku>` | 彈幕資料列表，詳見 [Danmaku](#danmaku--彈幕物件)。                                               |
| `subs`     | `array<Sub>`     | 字幕列表，詳見 [Sub](#sub--字幕物件)。                                                         |
| `drm`      | `Drm`            | DRM 版權保護設定，詳見 [Drm](#drm--drm-設定物件)。                                               |
| `artwork`  | `string`         | 播放頁面封面圖 URL。                                                                       |
| `desc`     | `string`         | 播放頁面描述文字。                                                                          |
| `position` | `long`           | 播放恢復位置（毫秒）。                                                                        |
| `lrc`      | `string`         | 歌詞 URL（音樂類來源使用）。                                                                   |

---

## 完整範例

詳細範例請參考原始文件。

---

## 爬蟲本地代理 URL

爬蟲可在回傳的媒體 URL 中使用 `proxy://` 協議，將請求導向本地代理伺服器。

| 語言         | 回傳 URL 前綴        | 取得代理 URL 的方法                  |
|------------|------------------|-------------------------------|
| Java（JAR）  | `proxy://`       | `Proxy.getUrl(boolean local)` |
| Python     | `proxy://?do=py` | `getProxyUrl(boolean local)`  |
| JavaScript | `proxy://?do=js` | `getProxy(boolean local)`     |

完整端點說明見 [LOCAL.md — /proxy](LOCAL.md#proxy--爬蟲代理)。
