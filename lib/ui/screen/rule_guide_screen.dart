import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class RuleGuideScreen extends StatelessWidget {
  const RuleGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('rule_edit.help_title'.tr())),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTitle('Holo 规则编写指南'),
            _buildParagraph(
              'Holo 使用规则驱动架构，通过 JSON 配置适配不同动漫网站。'
              '每个规则定义了如何搜索、获取详情、解析播放地址的完整流程。',
            ),
            _buildDivider(),

            // 基础信息
            _buildSectionTitle('基础信息'),
            _buildTable([
              ['字段', '类型', '必填', '说明'],
              ['name', 'string', '是', '规则名称，用于界面显示'],
              ['baseUrl', 'string', '是', '网站域名'],
              ['logoUrl', 'string', '否', '网站图标URL'],
              ['useWebView', 'boolean', '否', '是否使用WebView加载'],
              ['timeout', 'number', '否', '请求超时时间（秒），默认15'],
              ['isPureJs', 'boolean', '否', '是否为纯JS规则，默认false'],
            ]),
            _buildDivider(),

            // 搜索页规则
            _buildSectionTitle('搜索页规则'),
            _buildSubTitle('URL配置'),
            _buildTable([
              ['字段', '说明', '示例'],
              ['searchUrl', '搜索路径，使用{keyword}占位符', '/search?keyword={keyword}'],
              ['searchRequestMethod', '请求方法：get/post', 'get'],
              ['searchRequestHeaders', '请求头', '{"User-Agent": "..."}'],
              ['fullSearchUrl', '是否使用完整URL', 'false'],
            ]),
            SizedBox(height: 12),
            _buildSubTitle('选择器配置'),
            _buildTable([
              ['字段', '说明', '示例'],
              ['searchSelector', '搜索结果列表容器的选择器', 'div.search-results'],
              ['itemImgSelector', '在条目内查找图片的选择器', 'img'],
              ['itemImgFromSrc', '图片是否从src属性获取', 'true/false'],
              ['itemTitleSelector', '在条目内查找标题的选择器', 'h3.title'],
              ['itemIdSelector', '在条目内查找详情页链接的选择器', 'a.detail-link'],
              ['itemGenreSelector', '在条目内查找分类的选择器（可选）', 'span.genre'],
            ]),
            SizedBox(height: 12),
            _buildSubTitle('关键逻辑'),
            _buildParagraph(
              '1. searchSelector 匹配到的每个元素是一个搜索结果条目（entry）\n'
              '2. 在每个条目（entry）内，使用 itemIdSelector 查找子元素，提取其 href 属性作为 mediaId\n'
              '3. mediaId 将用于拼接详情页URL',
            ),
            SizedBox(height: 12),
            _buildSubTitle('重要：searchSelector 的两种写法'),
            _buildParagraph('写法1：选择容器（推荐）'),
            _buildCodeBlock(
              '<div class="search-results">  <!-- searchSelector: "div.search-results" -->\n'
              '  <a class="item" href="/anime/1234">  <!-- itemIdSelector: "a.item" -->\n'
              '    <img src="cover.jpg">\n'
              '    <h3>番剧名称</h3>\n'
              '  </a>\n'
              '</div>',
            ),
            _buildParagraph('写法2：直接选择条目'),
            _buildCodeBlock(
              '<div class="search-results">\n'
              '  <div class="item">  <!-- searchSelector: "div.search-results > div.item" -->\n'
              '    <img src="cover.jpg">\n'
              '    <h3>番剧名称</h3>\n'
              '    <a href="/anime/1234">详情</a>  <!-- itemIdSelector: "a" -->\n'
              '  </div>\n'
              '</div>',
            ),
            _buildSubTitle('常见错误'),
            _buildParagraph('❌ 错误：searchSelector 和 itemIdSelector 选择同一个元素'),
            _buildCodeBlock(
              '{\n'
              '  "searchSelector": "div.vod-grid > a.vod-card",\n'
              '  "itemIdSelector": "a.vod-card"\n'
              '}',
            ),
            _buildParagraph('✅ 正确：使用容器方式'),
            _buildCodeBlock(
              '{\n'
              '  "searchSelector": "div.vod-grid",\n'
              '  "itemIdSelector": "a.vod-card"\n'
              '}',
            ),
            _buildDivider(),

            // 详情页规则
            _buildSectionTitle('详情页规则'),
            _buildSubTitle('URL配置'),
            _buildTable([
              ['字段', '说明', '示例'],
              ['detailUrl', '详情页路径，使用{mediaId}占位符', '{mediaId}'],
              ['detailRequestMethod', '请求方法', 'get'],
              ['detailRequestHeaders', '请求头', '{"User-Agent": "..."}'],
              ['fullDetailUrl', '是否使用完整URL', 'false'],
            ]),
            SizedBox(height: 12),
            _buildSubTitle('选择器配置'),
            _buildTable([
              ['字段', '说明', '示例'],
              ['lineSelector', '播放线路列表的选择器', 'div.line-list'],
              ['episodeSelector', '在线路内查找剧集链接的选择器', 'li > a'],
              ['episodeReverse', '是否反转剧集顺序', 'false/true'],
            ]),
            SizedBox(height: 12),
            _buildSubTitle('关键逻辑'),
            _buildParagraph(
              '1. lineSelector 匹配到的每个元素是一个播放线路\n'
              '2. 在每个线路内，使用 episodeSelector 查找<a>标签，提取其 href 属性作为 episodeId\n'
              '3. episodeId 将用于拼接播放页URL',
            ),
            _buildDivider(),

            // 播放页规则
            _buildSectionTitle('播放页规则'),
            _buildSubTitle('URL配置'),
            _buildTable([
              ['字段', '说明', '示例'],
              ['playerUrl', '播放页路径，使用{episodeId}占位符', '{episodeId}'],
              ['playerRequestMethod', '请求方法', 'get'],
              ['playerRequestHeaders', '请求头', '{"User-Agent": "..."}'],
              ['fullPlayerUrl', '是否使用完整URL', 'false'],
            ]),
            SizedBox(height: 12),
            _buildSubTitle('选择器配置'),
            _buildTable([
              ['字段', '说明', '示例'],
              ['playerVideoSelector', '视频元素的选择器', 'video#player'],
              ['videoElementAttribute', '视频元素上存储URL的属性', 'src'],
              ['embedVideoSelector', '嵌入式视频选择器（iframe等）', 'iframe'],
              ['waitForTargetElement', '是否等待目标元素加载完成', 'true'],
              ['videoUrlSubsChar', '视频URL截取规则', 'videoUrl='],
            ]),
            SizedBox(height: 12),
            _buildSubTitle('关键逻辑'),
            _buildParagraph(
              '1. 加载播放页后，首先查找 playerVideoSelector 匹配的视频元素\n'
              '2. 从视频元素的 videoElementAttribute 属性中获取视频URL\n'
              '3. 如果找不到视频元素，尝试查找 embedVideoSelector 匹配的 iframe\n'
              '4. 如果配置了 videoUrlSubsChar，则从URL中截取指定部分',
            ),
            _buildDivider(),

            // JS脚本规则
            _buildSectionTitle('JS脚本规则（高级）'),
            _buildParagraph('当CSS选择器无法获取数据时（如视频地址在JS变量中），可以使用JS脚本注入。'),
            SizedBox(height: 12),
            _buildSubTitle('配置字段'),
            _buildTable([
              ['字段', '说明', '返回值格式'],
              ['searchScript', '搜索页JS脚本', '[{"id":"", "title":"", ...}]'],
              ['detailScript', '详情页JS脚本', '{"lines": [{"episodes": [...]}]}'],
              ['playerScript', '播放页JS脚本', '{"videoUrl": "https://..."}'],
            ]),
            SizedBox(height: 12),
            _buildSubTitle('优先级'),
            _buildParagraph(
              '• 配置了JS脚本的页面：优先使用JS返回的JSON数据\n'
              '• 未配置JS脚本的页面：使用CSS选择器解析',
            ),
            SizedBox(height: 12),
            _buildSubTitle('纯JS规则（isPureJs）'),
            _buildParagraph(
              '当设置 isPureJs: true 时，规则将完全依赖JS脚本获取数据，不再使用CSS选择器解析。',
            ),
            _buildParagraph('纯JS规则的特点：'),
            _buildParagraph(
              '• 自动启用WebView和JS脚本功能\n'
              '• 隐藏所有CSS选择器输入框，只显示JS脚本输入\n'
              '• 搜索、详情、播放页面都通过JS脚本获取数据\n'
              '• 适合REST API或纯数据接口类型的网站',
            ),
            _buildParagraph('纯JS规则示例：'),
            _buildCodeBlock(
              '{\n'
              '  "name": "Sorani动漫",\n'
              '  "baseUrl": "https://example.com",\n'
              '  "isPureJs": true,\n'
              '  "useWebView": true,\n'
              '  "searchScript": "(function() { ... })();",\n'
              '  "detailScript": "(function() { ... })();",\n'
              '  "playerScript": "(function() { ... })();"\n'
              '}',
            ),
            SizedBox(height: 12),
            _buildSubTitle('编码方式'),
            _buildParagraph('JS脚本使用 Base64编码 存储在JSON中，避免转义问题。'),
            _buildParagraph('原始JS脚本：'),
            _buildCodeBlock(
              '(function() {\n'
              '  if (typeof player_aaaa !== \'undefined\' && player_aaaa.url) {\n'
              '    return JSON.stringify({ videoUrl: player_aaaa.url });\n'
              '  }\n'
              '  return JSON.stringify({ videoUrl: \'\' });\n'
              '})();',
            ),
            _buildParagraph('使用场景：'),
            _buildParagraph(
              '• 视频地址在JS变量中\n'
              '• 需要异步加载\n'
              '• 复杂的解析逻辑\n'
              '• 网站提供REST API接口（纯JS规则）',
            ),
            _buildDivider(),

            // 占位符说明
            _buildSectionTitle('占位符说明'),
            _buildTable([
              ['占位符', '说明', '使用位置'],
              ['{keyword}', '搜索关键词', 'searchUrl'],
              ['{mediaId}', '详情页ID（从搜索结果提取的href）', 'detailUrl、playerUrl'],
              ['{episodeId}', '剧集ID（从详情页提取的href）', 'playerUrl'],
            ]),
            SizedBox(height: 12),
            _buildParagraph(
              '注意：mediaId 和 episodeId 提取的是完整的 href 路径，如 /anime/1234 或 /play/1234/1。',
            ),
            _buildDivider(),

            // 调试技巧
            _buildSectionTitle('调试技巧'),
            _buildParagraph(
              '1. 使用WebView：动态渲染的页面必须设置 useWebView: true\n'
              '2. 检查选择器：在浏览器控制台使用 document.querySelectorAll("你的选择器") 测试\n'
              '3. 查看日志：应用日志会输出HTML解析结果和JS执行结果\n'
              '4. 逐步测试：先测试搜索，再测试详情，最后测试播放\n'
              '5. 使用JS脚本：当CSS选择器无法获取时，尝试使用JS脚本注入',
            ),
            _buildDivider(),

            // 常见问题
            _buildSectionTitle('常见问题'),
            _buildSubTitle('Q: 搜索结果显示为空？'),
            _buildParagraph('A: 检查 searchSelector 是否正确，确保能匹配到搜索结果条目。'),
            SizedBox(height: 8),
            _buildSubTitle('Q: 详情页没有剧集？'),
            _buildParagraph(
              'A: 检查 lineSelector 和 episodeSelector，确保能匹配到线路和剧集链接。',
            ),
            SizedBox(height: 8),
            _buildSubTitle('Q: 播放页获取不到视频地址？'),
            _buildParagraph(
              'A: \n'
              '• 检查 playerVideoSelector 和 videoElementAttribute 是否正确\n'
              '• 如果视频在iframe中，配置 embedVideoSelector\n'
              '• 如果视频地址在JS变量中，使用 playerScript 注入获取',
            ),
            SizedBox(height: 8),
            _buildSubTitle('Q: JS脚本返回空？'),
            _buildParagraph(
              'A: \n'
              '• 确保JS变量已经加载（可能需要等待异步加载）\n'
              '• 检查JS变量名是否正确\n'
              '• 在浏览器控制台手动执行JS脚本测试',
            ),
            SizedBox(height: 8),
            _buildSubTitle('Q: 如何获取Base64编码的JS脚本？'),
            _buildParagraph('A: 使用Python编码：'),
            _buildCodeBlock(
              'import base64\n'
              'js_code = \'\'(function() { return JSON.stringify({videoUrl: player_aaaa.url}); })();\'\'\n'
              'encoded = base64.b64encode(js_code.encode(\'utf-8\')).decode(\'utf-8\')\n'
              'print(encoded)',
            ),
            SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildSectionTitle(String text) {
    return Padding(
      padding: EdgeInsets.only(top: 8, bottom: 12),
      child: Text(
        text,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildSubTitle(String text) {
    return Padding(
      padding: EdgeInsets.only(top: 4, bottom: 8),
      child: Text(
        text,
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildParagraph(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Text(text, style: TextStyle(fontSize: 14, height: 1.5)),
    );
  }

  Widget _buildCodeBlock(String code) {
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          width: double.infinity,
          margin: EdgeInsets.only(bottom: 12),
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[800] : Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            code,
            style: TextStyle(
              fontSize: 13,
              fontFamily: 'monospace',
              height: 1.4,
              color: isDark ? Colors.grey[300] : Colors.grey[800],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTable(List<List<String>> rows) {
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          width: double.infinity,
          margin: EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            border: Border.all(
              color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: rows.asMap().entries.map((entry) {
              final index = entry.key;
              final row = entry.value;
              return Container(
                decoration: BoxDecoration(
                  color: index == 0
                      ? (isDark ? Colors.grey[850] : Colors.grey[100])
                      : null,
                  border: Border(
                    bottom: BorderSide(
                      color: index < rows.length - 1
                          ? (isDark ? Colors.grey[700]! : Colors.grey[300]!)
                          : Colors.transparent,
                    ),
                  ),
                ),
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: row.map((cell) {
                    return Expanded(
                      child: Text(
                        cell,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: index == 0
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isDark ? Colors.grey[300] : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Divider(),
    );
  }
}
