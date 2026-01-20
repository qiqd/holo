// ... existing code ...
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:holo/entity/rule.dart';
import 'package:holo/util/local_store.dart';

class RuleEditScreen extends StatefulWidget {
  final Rule? rule;
  const RuleEditScreen({super.key, this.rule});

  @override
  State<RuleEditScreen> createState() => _RuleEditScreenState();
}

class _RuleEditScreenState extends State<RuleEditScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _name;
  String? _baseUrl;
  String? _logoUrl;
  String? _searchUrl;
  bool _fullSearchUrl = false;
  int? _timeout;
  String? _searchSelector;
  String? _itemImgSelector;
  bool _itemImgFromSrc = false;
  String? _itemTitleSelector;
  String? _itemIdSelector;
  String? _itemGenreSelector;
  String? _detailUrl;
  bool _fullDetailUrl = false;
  String? _lineSelector;
  String? _episodeSelector;
  String? _playerUrl;
  bool _fullPlayerUrl = false;
  String? _playerVideoSelector;
  String? _embedVideoSelector;
  String? _videoUrlSubsChar;
  void _saveRule() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final rule = Rule(
      name: _name ?? '',
      baseUrl: _baseUrl ?? '',
      logoUrl: _logoUrl ?? '',
      searchUrl: _searchUrl ?? '',
      fullSearchUrl: _fullSearchUrl,
      timeout: _timeout ?? 5,
      searchSelector: _searchSelector ?? '',
      itemImgSelector: _itemImgSelector ?? '',
      itemImgFromSrc: _itemImgFromSrc,
      itemTitleSelector: _itemTitleSelector ?? '',
      itemIdSelector: _itemIdSelector ?? '',
      itemGenreSelector: _itemGenreSelector ?? '',
      detailUrl: _detailUrl ?? '',
      fullDetailUrl: _fullDetailUrl,
      lineSelector: _lineSelector ?? '',
      episodeSelector: _episodeSelector ?? '',
      playerUrl: _playerUrl ?? '',
      fullPlayerUrl: _fullPlayerUrl,
      playerVideoSelector: _playerVideoSelector ?? '',
      embedVideoSelector: _embedVideoSelector ?? '',
      videoUrlSubsChar: _videoUrlSubsChar ?? '',
    );
    LocalStore.saveRule(rule);
    context.pop();
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('规则配置详细说明'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '【规则名称】\n• 作用：设置此规则的名称，用于在界面中显示和区分不同规则\n• 示例：Bilibili、微博、知乎、豆瓣等\n• 要求：不能为空，建议使用网站的常用名称',
                  style: TextStyle(fontSize: 14),
                ),
                SizedBox(height: 10),
                Divider(),
                Text(
                  '\n【网站域名】\n• 作用：指定目标网站的域名，用于匹配和识别网页\n• 格式：仅输入域名部分，不需要协议前缀（如 http:// 或 https://）\n• 示例：www.bilibili.com、tieba.baidu.com、weibo.com\n• 注意：支持主域名和子域名，不要包含路径部分',
                  style: TextStyle(fontSize: 14),
                ),
                SizedBox(height: 10),
                Divider(),
                Text(
                  '\n【Logo路径】\n• 作用：指定网站Logo的路径，用于界面展示\n• 格式：可使用相对路径或完整URL路径（不带协议前缀）\n• 示例：logo.png、images/site-logo.svg、static/logo.jpg\n• 支持：PNG、JPG、SVG等常见图片格式',
                  style: TextStyle(fontSize: 14),
                ),
                SizedBox(height: 10),
                Divider(),
                Text(
                  '\n【搜索图片选择器】\n• 作用：在搜索结果页面定位缩略图元素\n• 格式：CSS选择器语法，用于提取列表页的图片链接\n• 示例：img.thumbnail、.image-box img、[data-src]、.cover-image\n• 常见类型：img标签、带背景图的div、data属性等',
                  style: TextStyle(fontSize: 14),
                ),
                SizedBox(height: 10),
                Divider(),
                Text(
                  '\n【详情标题选择器】\n• 作用：在详情页提取标题内容\n• 格式：CSS选择器，通常为标题标签或标题类名\n• 示例：h1.title、.detail-title、article h1、header h2\n• 建议：优先选择唯一性高、结构稳定的元素',
                  style: TextStyle(fontSize: 14),
                ),
                SizedBox(height: 10),
                Divider(),
                Text(
                  '\n【详情描述选择器】\n• 作用：在详情页提取描述或摘要信息\n• 格式：CSS选择器，通常是段落或描述容器\n• 示例：.description、p.summary、.intro-text、.content-brief\n• 注意：选择包含关键描述信息的元素',
                  style: TextStyle(fontSize: 14),
                ),
                SizedBox(height: 10),
                Divider(),
                Text(
                  '\n【详情内容选择器】\n• 作用：在详情页提取核心内容\n• 格式：CSS选择器，通常是文章主体或内容容器\n• 示例：.content、article、.detail-content、main div\n• 重要：这是抓取主要内容的关键选择器，请确保准确性',
                  style: TextStyle(fontSize: 14),
                ),
                SizedBox(height: 10),
                Divider(),
                Text(
                  '\n【启用规则】\n• 作用：控制此规则是否生效\n• 开启：规则将被使用，参与网页解析\n• 关闭：规则将被禁用，不参与解析过程\n• 用途：方便测试和管理多个规则',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('确定'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.save_rounded),
            onPressed: _saveRule,
          ),
          IconButton(
            icon: const Icon(Icons.help_rounded),
            onPressed: () {
              _showHelpDialog();
            },
          ),
        ],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('规则编辑'),
      ),
      body: SafeArea(
        child: SizedBox(
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // 基本信息
                  Card(
                    margin: EdgeInsets.all(10),
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '基本信息',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 12),
                          TextFormField(
                            enabled: widget.rule == null,
                            initialValue: widget.rule?.name,
                            decoration: InputDecoration(
                              labelText: '规则名称',
                              hintText: '例如：樱花动漫',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(20.0),
                                ),
                              ),
                            ),
                            onChanged: (value) {
                              setState(() {
                                _name = value;
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return '请输入规则名称';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 12),
                          TextFormField(
                            enabled: widget.rule == null,
                            initialValue: widget.rule?.baseUrl,
                            decoration: InputDecoration(
                              labelText: '网站域名()',
                              hintText: '例如：www.example.com',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(20.0),
                                ),
                              ),
                            ),
                            onChanged: (value) {
                              setState(() {
                                _baseUrl = value;
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return '请输入网站域名';
                              }
                              if (value.contains('://')) {
                                return '请勿包含协议前缀 (http:// 或 https://)';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 12),
                          TextFormField(
                            enabled: widget.rule == null,
                            initialValue: widget.rule?.logoUrl,
                            decoration: InputDecoration(
                              labelText: '网站图标URL',
                              hintText:
                                  '例如：/logo.png 或 https://example.com/logo.png',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(20.0),
                                ),
                              ),
                            ),
                            onChanged: (value) {
                              setState(() {
                                _logoUrl = value;
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return '请输入网站图标URL';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 12),
                          TextFormField(
                            enabled: widget.rule == null,
                            initialValue: widget.rule?.timeout.toString(),
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: '请求超时时间(秒)',
                              hintText: '默认5秒，超过此时间请求将被取消',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(20.0),
                                ),
                              ),
                            ),
                            onChanged: (value) {
                              setState(() {
                                _timeout = int.tryParse(value) ?? 5;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  // 搜索页面规则
                  Card(
                    margin: EdgeInsets.all(10),
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '搜索页面规则',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 12),
                          TextFormField(
                            enabled: widget.rule == null,
                            initialValue: widget.rule?.searchUrl,
                            decoration: InputDecoration(
                              labelText: '搜索页面路径',
                              hintText:
                                  '例如：/search 或 /search?keyword={keyword}',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(20.0),
                                ),
                              ),
                            ),
                            onChanged: (value) {
                              setState(() {
                                _searchUrl = value;
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return '请输入搜索页面路径';
                              }
                              if (value.contains('://')) {
                                return '请勿包含协议前缀 (http:// 或 https://)';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 12),
                          SwitchListTile(
                            title: Text('搜索路径是否完整'),
                            subtitle: Text(
                              '开启：搜索路径不与 baseUrl 拼接\n'
                              '关闭：搜索路径与 baseUrl 拼接',
                            ),
                            value: _fullSearchUrl,
                            onChanged: widget.rule == null
                                ? (value) {
                                    setState(() {
                                      _fullSearchUrl = value;
                                    });
                                  }
                                : null,
                          ),
                          SizedBox(height: 12),
                          TextFormField(
                            enabled: widget.rule == null,
                            decoration: InputDecoration(
                              labelText: '搜索结果列表选择器',
                              hintText: '例如：div.search-results 或 ul.list-items',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(20.0),
                                ),
                              ),
                            ),
                            onChanged: (value) {
                              setState(() {
                                _searchSelector = value;
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return '请输入搜索结果列表选择器';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 12),
                          TextFormField(
                            enabled: widget.rule == null,
                            decoration: InputDecoration(
                              labelText: '搜索结果图片选择器',
                              hintText: '例如：img.poster 或 .thumbnail img',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(20.0),
                                ),
                              ),
                            ),
                            onChanged: (value) {
                              setState(() {
                                _itemImgSelector = value;
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return '请输入搜索结果图片选择器';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 12),
                          SwitchListTile(
                            title: Text('图片链接来自src属性'),
                            subtitle: Text(
                              '开启：使用src属性获取图片\n'
                              '关闭：使用data-original等属性',
                            ),
                            value: _itemImgFromSrc,
                            onChanged: widget.rule == null
                                ? (value) {
                                    setState(() {
                                      _itemImgFromSrc = value;
                                    });
                                  }
                                : null,
                          ),
                          SizedBox(height: 12),
                          TextFormField(
                            enabled: widget.rule == null,
                            decoration: InputDecoration(
                              labelText: '搜索结果标题选择器',
                              hintText: '例如：h3.title 或 .result-title',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(20.0),
                                ),
                              ),
                            ),
                            onChanged: (value) {
                              setState(() {
                                _itemTitleSelector = value;
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return '请输入搜索结果标题选择器';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 12),
                          TextFormField(
                            enabled: widget.rule == null,
                            decoration: InputDecoration(
                              labelText: '搜索结果ID选择器',
                              hintText: '例如：a[href*="/detail/"] 或 .detail-link',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(20.0),
                                ),
                              ),
                            ),
                            onChanged: (value) {
                              setState(() {
                                _itemIdSelector = value;
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return '请输入搜索结果ID选择器';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 12),
                          TextFormField(
                            enabled: widget.rule == null,
                            decoration: InputDecoration(
                              labelText: '搜索结果分类选择器',
                              hintText: '例如：span.genre 或 .category',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(20.0),
                                ),
                              ),
                            ),
                            onChanged: (value) {
                              setState(() {
                                _itemGenreSelector = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  // 详情页规则
                  Card(
                    margin: EdgeInsets.all(10),
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '详情页面规则',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 12),
                          TextFormField(
                            enabled: widget.rule == null,
                            decoration: InputDecoration(
                              labelText: '详情页面路径',
                              hintText: '例如：/detail/{mediaId}',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(20.0),
                                ),
                              ),
                            ),
                            onChanged: (value) {
                              setState(() {
                                _detailUrl = value;
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return '请输入详情页面路径';
                              }
                              if (value.contains('://')) {
                                return '请勿包含协议前缀 (http:// 或 https://)';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 12),
                          SwitchListTile(
                            title: Text('详情路径是否完整'),
                            subtitle: Text(
                              '开启：详情路径不与 baseUrl 拼接\n'
                              '关闭：详情路径与 baseUrl 拼接',
                            ),
                            value: _fullDetailUrl,
                            onChanged: widget.rule == null
                                ? (value) {
                                    setState(() {
                                      _fullDetailUrl = value;
                                    });
                                  }
                                : null,
                          ),
                          SizedBox(height: 12),
                          TextFormField(
                            enabled: widget.rule == null,
                            decoration: InputDecoration(
                              labelText: '播放路线选择器',
                              hintText: '例如：div.route-list 或 .play-routes',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(20.0),
                                ),
                              ),
                            ),
                            onChanged: (value) {
                              setState(() {
                                _lineSelector = value;
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return '请输入播放路线选择器';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 12),
                          TextFormField(
                            enabled: widget.rule == null,
                            decoration: InputDecoration(
                              labelText: '剧集列表选择器',
                              hintText: '例如：ul.episodes 或 .episode-list',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(20.0),
                                ),
                              ),
                            ),
                            onChanged: (value) {
                              setState(() {
                                _episodeSelector = value;
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return '请输入剧集列表选择器';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  // 播放页面规则
                  Card(
                    margin: EdgeInsets.all(10),
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '播放页面规则',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 12),
                          TextFormField(
                            enabled: widget.rule == null,
                            decoration: InputDecoration(
                              labelText: '播放页面路径',
                              hintText: '例如：/play/{episodeId}',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(20.0),
                                ),
                              ),
                            ),
                            onChanged: (value) {
                              setState(() {
                                _playerUrl = value;
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return '请输入播放页面路径';
                              }
                              if (value.contains('://')) {
                                return '请勿包含协议前缀 (http:// 或 https://)';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 12),
                          SwitchListTile(
                            title: Text('播放路径是否完整'),
                            subtitle: Text(
                              '开启：播放路径不与 baseUrl 拼接\n'
                              '关闭：播放路径与 baseUrl 拼接',
                            ),
                            value: _fullPlayerUrl,
                            onChanged: widget.rule == null
                                ? (value) {
                                    setState(() {
                                      _fullPlayerUrl = value;
                                    });
                                  }
                                : null,
                          ),
                          SizedBox(height: 12),
                          TextFormField(
                            enabled: widget.rule == null,
                            decoration: InputDecoration(
                              labelText: '视频播放器选择器',
                              hintText:
                                  '例如：video#player 或 iframe[src*="embed"]',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(20.0),
                                ),
                              ),
                            ),
                            onChanged: (value) {
                              setState(() {
                                _playerVideoSelector = value;
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return '请输入视频播放器选择器';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 12),
                          TextFormField(
                            enabled: widget.rule == null,
                            decoration: InputDecoration(
                              labelText: '嵌入式视频选择器',
                              hintText: '多个选择器用英文逗号分隔，例如：iframe, #embed-player',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(20.0),
                                ),
                              ),
                            ),
                            onChanged: (value) {
                              setState(() {
                                _embedVideoSelector = value;
                              });
                            },
                          ),
                          SizedBox(height: 12),
                          TextFormField(
                            enabled: widget.rule == null,
                            decoration: InputDecoration(
                              labelText: '视频URL提取规则',
                              hintText: '例如：提取 params=videoUrl=xxxx 中的 xxxx 部分',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(20.0),
                                ),
                              ),
                            ),
                            onChanged: (value) {
                              setState(() {
                                _videoUrlSubsChar = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
