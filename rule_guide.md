# Holo 规则编写指南

## 概述

Holo 使用规则驱动架构，通过 JSON 配置适配不同动漫网站。每个规则定义了如何搜索、获取详情、解析播放地址的完整流程。

## 规则结构

```json
{
  "name": "规则名称",
  "baseUrl": "https://www.example.com",
  "logoUrl": "https://www.example.com/logo.png",
  "useWebView": true,
  "timeout": 15,
  
  "// 搜索页配置": "",
  "searchUrl": "/search?keyword={keyword}",
  "searchSelector": "div.search-item",
  "itemImgSelector": "img",
  "itemImgFromSrc": true,
  "itemTitleSelector": "h3.title",
  "itemIdSelector": "a.detail-link",
  "itemGenreSelector": "span.genre",
  
  "// 详情页配置": "",
  "detailUrl": "{mediaId}",
  "lineSelector": "div.line-list",
  "episodeSelector": "a.episode-link",
  "episodeReverse": false,
  
  "// 播放页配置": "",
  "playerUrl": "{episodeId}",
  "playerVideoSelector": "video#player",
  "videoElementAttribute": "src",
  "embedVideoSelector": "iframe",
  "waitForTargetElement": true,
  
  "// JS脚本配置（可选）": "",
  "searchScript": "",
  "detailScript": "",
  "playerScript": ""
}
```

---

## 基础信息

| 字段 | 类型 | 必填 | 说明 |
| ------ | ------ | ------ | ------ |
| `name` | string | 是 | 规则名称，用于界面显示 |
| `baseUrl` | string | 是 | 网站域名，如 `https://www.example.com` |
| `logoUrl` | string | 否 | 网站图标URL |
| `useWebView` | boolean | 否 | 是否使用WebView加载（动态渲染页面需要） |
| `timeout` | number | 否 | 请求超时时间（秒），默认15 |

---

## 搜索页规则

### URL配置

| 字段 | 说明 | 示例 |
| ------ | ------ | ------ |
| `searchUrl` | 搜索路径，使用 `{keyword}` 作为关键词占位符 | `/search?keyword={keyword}` |
| `searchRequestMethod` | 请求方法：get/post | `get` |
| `searchRequestHeaders` | 请求头 | `{"User-Agent": "..."}` |
| `fullSearchUrl` | 是否使用完整URL（不拼接baseUrl） | `false` |

### 选择器配置

| 字段 | 说明 | 示例 |
| ------ | ------ | ------ |
| `searchSelector` | **搜索结果列表容器**的选择器，匹配所有搜索结果条目的父容器或条目本身 | `div.search-results` 或 `div.search-results > div.item` |
| `itemImgSelector` | 在条目内查找**图片**的选择器 | `img` 或 `div.cover img` |
| `itemImgFromSrc` | 图片是否从 `src` 属性获取 | `true`：从src获取；`false`：从data-original等获取 |
| `itemTitleSelector` | 在条目内查找**标题**的选择器 | `h3.title` 或 `a.title` |
| `itemIdSelector` | 在条目内查找**详情页链接**的选择器 | `a[href*="/detail/"]` |
| `itemGenreSelector` | 在条目内查找**分类/标签**的选择器（可选） | `span.genre` |

### 关键逻辑

1. `searchSelector` 匹配到的每个元素是一个**搜索结果条目**（entry）
2. 在每个条目（entry）内，使用 `itemIdSelector` 查找子元素，提取其 `href` 属性作为 `mediaId`
3. **兼容性处理**：如果 `itemIdSelector` 在子元素中找不到匹配，会自动回退到当前条目元素自身获取 `href`
4. `mediaId` 将用于拼接详情页URL

### 重要：searchSelector 的两种写法

#### 写法1：选择容器（推荐）

`searchSelector` 选择**包含所有条目的容器**，`itemIdSelector` 选择**条目本身**。

```html
<div class="search-results">  <!-- searchSelector: "div.search-results" -->
  <a class="item" href="/anime/1234">  <!-- itemIdSelector: "a.item" -->
    <img src="cover.jpg">
    <h3>番剧名称</h3>
  </a>
  <a class="item" href="/anime/5678">
    <img src="cover2.jpg">
    <h3>番剧名称2</h3>
  </a>
</div>
```

#### 写法2：直接选择条目

`searchSelector` 直接选择**每个条目**，`itemIdSelector` 选择**条目内的链接元素**。

```html
<div class="search-results">
  <div class="item">  <!-- searchSelector: "div.search-results > div.item" -->
    <img src="cover.jpg">
    <h3>番剧名称</h3>
    <a href="/anime/1234">详情</a>  <!-- itemIdSelector: "a" -->
  </div>
</div>
```

### 兼容性说明

由于代码已实现**回退机制**，以下两种写法都可以正常工作：

#### 写法1：选择容器（推荐）

```json
{
  "searchSelector": "div.vod-grid",        // 选中容器
  "itemIdSelector": "a.vod-card"           // 在容器内查找 a.vod-card
}
```

#### 写法2：直接选择条目（兼容）

```json
{
  "searchSelector": "div.vod-grid > a.vod-card",  // 直接选中条目（a标签）
  "itemIdSelector": "a.vod-card"                   // 子元素中找不到时，自动回退到当前元素自身
}
```

> **注意**：代码会先尝试在子元素中查找 `itemIdSelector`，如果找不到，会自动使用当前条目元素自身的 `href` 属性。因此即使 `searchSelector` 和 `itemIdSelector` 选择同一个元素，也能正常工作。

> **提示**：由于回退机制的存在，`itemIdSelector` 的配置更加灵活。但为了代码清晰和可维护性，建议优先使用**写法1**（选择容器）。

### 完整示例

```html
<div class="search-results">
  <div class="item">  <!-- searchSelector: "div.search-results" 匹配到容器，然后 itemIdSelector: "div.item" 匹配条目 -->
    <img src="cover.jpg" data-original="cover.jpg">  <!-- itemImgSelector: "img" -->
    <h3 class="title">番剧名称</h3>  <!-- itemTitleSelector: "h3.title" -->
    <a href="/anime/1234">详情</a>  <!-- itemIdSelector: "a"，提取 /anime/1234 作为 mediaId -->
    <span class="genre">热血</span>  <!-- itemGenreSelector: "span.genre" -->
  </div>
</div>
```

---

## 详情页规则

### URL配置

| 字段 | 说明 | 示例 |
| ------ | ------ | ------ |
| `detailUrl` | 详情页路径，使用 `{mediaId}` 占位符 | `{mediaId}` 或 `/detail/{mediaId}` |
| `detailRequestMethod` | 请求方法 | `get` |
| `detailRequestHeaders` | 请求头 | `{"User-Agent": "..."}` |
| `fullDetailUrl` | 是否使用完整URL | `false` |

### 选择器配置

| 字段 | 说明 | 示例 |
| ------ | ------ | ------ |
| `lineSelector` | **播放线路列表**的选择器，每个匹配元素为一个线路 | `div.line-list` 或 `div.tab-content > div` |
| `episodeSelector` | 在线路内查找**剧集链接**的选择器 | `li > a` 或 `a.episode` |
| `episodeReverse` | 是否反转剧集顺序 | `false`：正序；`true`：倒序 |

### 关键逻辑

1. `lineSelector` 匹配到的每个元素是一个**播放线路**
2. 在每个线路内，使用 `episodeSelector` 查找 `<a>` 标签，提取其 `href` 属性作为 `episodeId`
3. `episodeId` 将用于拼接播放页URL

**示例**：

```html
<div class="line-list">  <!-- lineSelector 匹配这个 -->
  <div class="line">线路1</div>
  <ul>
    <li><a href="/play/1234/1">第1集</a></li>  <!-- episodeSelector，提取 /play/1234/1 作为 episodeId -->
    <li><a href="/play/1234/2">第2集</a></li>
  </ul>
</div>
```

---

## 播放页规则

### URL配置

| 字段 | 说明 | 示例 |
| ------ | ------ | ------ |
| `playerUrl` | 播放页路径，使用 `{episodeId}` 占位符 | `{episodeId}` 或 `/play/{episodeId}` |
| `playerRequestMethod` | 请求方法 | `get` |
| `playerRequestHeaders` | 请求头 | `{"User-Agent": "..."}` |
| `fullPlayerUrl` | 是否使用完整URL | `false` |

### 选择器配置

| 字段 | 说明 | 示例 |
| ------ | ------ | ------ |
| `playerVideoSelector` | **视频元素**的选择器 | `video#player` 或 `video.art-video` |
| `videoElementAttribute` | 视频元素上存储URL的属性 | `src` 或 `data-src` |
| `embedVideoSelector` | 嵌入式视频选择器（iframe等） | `iframe` 或 `#embed-player` |
| `waitForTargetElement` | 是否等待目标元素加载完成 | `true`：等待；`false`：不等待 |
| `videoUrlSubsChar` | 视频URL截取规则（使用lastIndexOf） | 如 `videoUrl=` 提取后面的部分 |

### 关键逻辑

1. 加载播放页后，首先查找 `playerVideoSelector` 匹配的视频元素
2. 从视频元素的 `videoElementAttribute` 属性中获取视频URL
3. 如果找不到视频元素，尝试查找 `embedVideoSelector` 匹配的 iframe
4. 如果配置了 `videoUrlSubsChar`，则从URL中截取指定部分

**示例**：

```html
<video id="player" src="https://cdn.example.com/video.m3u8"></video>
<!-- playerVideoSelector: video#player, videoElementAttribute: src -->
```

---

## JS脚本规则（高级）

当CSS选择器无法获取数据时（如视频地址在JS变量中），可以使用JS脚本注入。

### 配置字段

| 字段 | 说明 | 返回值格式 |
| ------ | ------ | ----------- |
| `searchScript` | 搜索页JS脚本 | `[{"id":"", "title":"", "coverUrl":"", "type":""}]` |
| `detailScript` | 详情页JS脚本 | `{"lines": [{"episodes": ["url1", "url2"]}]}` |
| `playerScript` | 播放页JS脚本 | `{"videoUrl": "https://..."}` |

### 优先级

- **配置了JS脚本的页面**：优先使用JS返回的JSON数据
- **未配置JS脚本的页面**：使用CSS选择器解析

### 编码方式

JS脚本使用 **Base64编码** 存储在JSON中，避免转义问题。

**原始JS脚本**：

```javascript
(function() {
  if (typeof player_aaaa !== 'undefined' && player_aaaa.url) {
    return JSON.stringify({ videoUrl: player_aaaa.url });
  }
  return JSON.stringify({ videoUrl: '' });
})();
```

**Base64编码后**：

```
KGZ1bmN0aW9uKCkgewogIGlmICh0eXBlb2YgcGxheWVyX2FhYWEgIT09ICd1bmRlZmluZWQnICYmIHBsYXllcl9hYWFhLnVybCkgewogICAgcmV0dXJuIEpTT04uc3RyaW5naWZ5KHsgdmlkZW9Vcmw6IHBsYXllcl9hYWFhLnVybCB9KTsKICB9CiAgcmV0dXJuIEpTT04uc3RyaW5naWZ5KHsgdmlkZW9Vcmw6ICcnIH0pOwp9KSgpOw==
```

### 使用场景

1. **视频地址在JS变量中**：如 `player_aaaa.url`
2. **需要异步加载**：页面加载完成后通过AJAX获取视频地址
3. **复杂的解析逻辑**：需要遍历多个元素或执行计算

---

## 占位符说明

| 占位符 | 说明 | 使用位置 |
| -------- | ------ | ---------- |
| `{keyword}` | 搜索关键词 | searchUrl |
| `{mediaId}` | 详情页ID（从搜索结果提取的href） | detailUrl、playerUrl |
| `{episodeId}` | 剧集ID（从详情页提取的href） | playerUrl |

### 替换逻辑

- `{keyword}`：直接替换为搜索关键词（会进行URL编码）
- `{mediaId}`：替换为 `itemIdSelector` 提取到的 `href` 值
- `{episodeId}`：替换为 `episodeSelector` 提取到的 `href` 值

**注意**：`mediaId` 和 `episodeId` 提取的是完整的 href 路径，如 `/anime/1234` 或 `/play/1234/1`。

---

## 完整示例

### 示例1：基础配置（CSS选择器）

```json
{
  "name": "示例动漫",
  "baseUrl": "https://www.example.com",
  "logoUrl": "https://www.example.com/logo.png",
  "useWebView": true,
  "timeout": 15,
  
  "searchUrl": "/search?keyword={keyword}",
  "searchRequestMethod": "get",
  "searchSelector": "div.search-item",
  "itemImgSelector": "img",
  "itemImgFromSrc": true,
  "itemTitleSelector": "h3.title",
  "itemIdSelector": "a.detail-link",
  "itemGenreSelector": "span.genre",
  
  "detailUrl": "{mediaId}",
  "detailRequestMethod": "get",
  "lineSelector": "div.line-list",
  "episodeSelector": "li > a",
  "episodeReverse": false,
  
  "playerUrl": "{episodeId}",
  "playerRequestMethod": "get",
  "playerVideoSelector": "video#player",
  "videoElementAttribute": "src",
  "embedVideoSelector": "",
  "waitForTargetElement": true,
  "videoUrlSubsChar": "",
  
  "searchScript": "",
  "detailScript": "",
  "playerScript": ""
}
```

### 示例2：JS脚本配置（视频地址在JS变量中）

```json
{
  "name": "JS变量示例",
  "baseUrl": "https://www.example.com",
  "logoUrl": "https://www.example.com/logo.png",
  "useWebView": true,
  "timeout": 15,
  
  "searchUrl": "/search?keyword={keyword}",
  "searchRequestMethod": "get",
  "searchSelector": "div.search-item",
  "itemImgSelector": "img",
  "itemImgFromSrc": true,
  "itemTitleSelector": "h3.title",
  "itemIdSelector": "a.detail-link",
  "itemGenreSelector": "span.genre",
  
  "detailUrl": "{mediaId}",
  "detailRequestMethod": "get",
  "lineSelector": "div.line-list",
  "episodeSelector": "li > a",
  "episodeReverse": false,
  
  "playerUrl": "{episodeId}",
  "playerRequestMethod": "get",
  "playerVideoSelector": "",
  "videoElementAttribute": "",
  "embedVideoSelector": "",
  "waitForTargetElement": true,
  "videoUrlSubsChar": "",
  
  "searchScript": "",
  "detailScript": "",
  "playerScript": "KGZ1bmN0aW9uKCkgewogIGlmICh0eXBlb2YgcGxheWVyX2FhYWEgIT09ICd1bmRlZmluZWQnICYmIHBsYXllcl9hYWFhLnVybCkgewogICAgcmV0dXJuIEpTT04uc3RyaW5naWZ5KHsgdmlkZW9Vcmw6IHBsYXllcl9hYWFhLnVybCB9KTsKICB9CiAgcmV0dXJuIEpTT04uc3RyaW5naWZ5KHsgdmlkZW9Vcmw6ICcnIH0pOwp9KSgpOw=="
}
```

---

## 调试技巧

1. **使用WebView**：动态渲染的页面必须设置 `useWebView: true`
2. **检查选择器**：在浏览器控制台使用 `document.querySelectorAll('你的选择器')` 测试
3. **查看日志**：应用日志会输出HTML解析结果和JS执行结果
4. **逐步测试**：先测试搜索，再测试详情，最后测试播放
5. **使用JS脚本**：当CSS选择器无法获取时，尝试使用JS脚本注入

---

## 常见问题

### Q: 搜索结果显示为空？

A: 检查 `searchSelector` 是否正确，确保能匹配到搜索结果条目。

### Q: 详情页没有剧集？

A: 检查 `lineSelector` 和 `episodeSelector`，确保能匹配到线路和剧集链接。

### Q: 播放页获取不到视频地址？

A:

- 检查 `playerVideoSelector` 和 `videoElementAttribute` 是否正确
- 如果视频在iframe中，配置 `embedVideoSelector`
- 如果视频地址在JS变量中，使用 `playerScript` 注入获取

### Q: JS脚本返回空？

A:

- 确保JS变量已经加载（可能需要等待异步加载）
- 检查JS变量名是否正确
- 在浏览器控制台手动执行JS脚本测试

### Q: 如何获取Base64编码的JS脚本？

A: 使用Python编码：

```python
import base64
js_code = '''(function() { return JSON.stringify({videoUrl: player_aaaa.url}); })();'''
encoded = base64.b64encode(js_code.encode('utf-8')).decode('utf-8')
print(encoded)
```
