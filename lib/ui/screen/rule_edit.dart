import 'package:flutter/material.dart';
import 'package:flutter_device_type/flutter_device_type.dart';

import 'package:go_router/go_router.dart';
import 'package:holo/entity/rule.dart';
import 'package:holo/service/api.dart';
import 'package:holo/service/source_service.dart';
import 'package:holo/ui/screen/rule_test.dart';

import 'package:holo/util/local_store.dart';
import 'package:easy_localization/easy_localization.dart';

class RuleEditScreen extends StatefulWidget {
  final Rule? rule;
  final bool isEditMode;
  const RuleEditScreen({super.key, this.rule, this.isEditMode = false});

  @override
  State<RuleEditScreen> createState() => _RuleEditScreenState();
}

class _RuleEditScreenState extends State<RuleEditScreen> {
  final _formKey = GlobalKey<FormState>();
  SourceService? _service;
  late final _isEditMode = widget.isEditMode;
  late final Rule _rule = widget.rule ?? Rule();
  bool _isTablet = false;
  void _saveRule() {
    if (!_formKey.currentState!.validate() || !_isEditMode) {
      return;
    }
    if (widget.rule != null) {
      LocalStore.updateRule(_rule);
    } else {
      LocalStore.saveRules([_rule]);
    }
    context.pop();
  }

  Future<void> _showHelpDialog() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('rule_edit.help_title'.tr()),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'rule_edit.help_rule_name'.tr(),
                  style: TextStyle(fontSize: 14),
                ),
                SizedBox(height: 10),
                Divider(),
                Text(
                  '\n${'rule_edit.help_base_url'.tr()}',
                  style: TextStyle(fontSize: 14),
                ),
                SizedBox(height: 10),
                Divider(),
                Text(
                  '\n${'rule_edit.help_logo_url'.tr()}',
                  style: TextStyle(fontSize: 14),
                ),
                SizedBox(height: 10),
                Divider(),
                Text(
                  '\n${'rule_edit.help_search_img_selector'.tr()}',
                  style: TextStyle(fontSize: 14),
                ),
                SizedBox(height: 10),
                Divider(),
                Text(
                  '\n${'rule_edit.help_detail_title_selector'.tr()}',
                  style: TextStyle(fontSize: 14),
                ),
                SizedBox(height: 10),
                Divider(),
                Text(
                  '\n${'rule_edit.help_detail_desc_selector'.tr()}',
                  style: TextStyle(fontSize: 14),
                ),
                SizedBox(height: 10),
                Divider(),
                Text(
                  '\n${'rule_edit.help_detail_content_selector'.tr()}',
                  style: TextStyle(fontSize: 14),
                ),
                SizedBox(height: 10),
                Divider(),
                Text(
                  '\n${'rule_edit.help_enable_rule'.tr()}',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('rule_edit.help_ok_button'.tr()),
            ),
          ],
        );
      },
    );
  }

  List<Widget> _buildAppbarActions() {
    return [
      if (widget.rule != null && !_isTablet)
        IconButton(
          icon: Text('Test'),
          onPressed: () {
            if (_service == null) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('未检测到数据源实例,请在规则管理页面刷新试试')));
              return;
            }
            context.push('/rule_test', extra: _service!);
          },
        ),
      IconButton(
        tooltip: 'Save Rule To Local',
        icon: const Icon(Icons.save_outlined),
        onPressed: _saveRule,
      ),
      IconButton(
        tooltip: 'Help',
        icon: const Icon(Icons.help_outline_outlined),
        onPressed: () {
          _showHelpDialog();
        },
      ),
    ];
  }

  //基本信息部分
  Widget _buildBasicCard() {
    return Card(
      margin: EdgeInsets.all(10),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          spacing: 12,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'rule_edit.basic_info'.tr(),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            TextFormField(
              enabled: widget.isEditMode,
              initialValue: widget.rule?.name,
              decoration: InputDecoration(
                labelText: 'rule_edit.rule_name_label'.tr(),
                hintText: 'rule_edit.rule_name_hint'.tr(),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(20.0)),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _rule.name = value;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'rule_edit.rule_name_validator'.tr();
                }

                return null;
              },
            ),

            TextFormField(
              enabled: widget.isEditMode,
              initialValue: widget.rule?.baseUrl,
              decoration: InputDecoration(
                labelText: 'rule_edit.base_url_label'.tr(),
                hintText: 'rule_edit.base_url_hint'.tr(),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(20.0)),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _rule.baseUrl = value;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'rule_edit.base_url_validator'.tr();
                }
                if (!value.contains('://')) {
                  return 'rule_edit.base_url_protocol_validator'.tr();
                }
                return null;
              },
            ),

            TextFormField(
              enabled: widget.isEditMode,
              initialValue: widget.rule?.logoUrl,
              decoration: InputDecoration(
                labelText: 'rule_edit.logo_url_label'.tr(),
                hintText: 'rule_edit.logo_url_hint'.tr(),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(20.0)),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _rule.logoUrl = value;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'rule_edit.logo_url_validator'.tr();
                }
                if (!value.contains('://')) {
                  return 'rule_edit.base_url_protocol_validator'.tr();
                }
                return null;
              },
            ),

            TextFormField(
              enabled: widget.isEditMode,
              initialValue: widget.rule?.timeout.toString(),
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'rule_edit.timeout_label'.tr(),
                hintText: 'rule_edit.timeout_hint'.tr(),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(20.0)),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _rule.timeout = int.tryParse(value) ?? 5;
                });
              },
            ),
            SwitchListTile(
              title: Text('rule_edit.base_use_webview_label'.tr()),
              value: _rule.useWebView,
              onChanged: (value) {
                setState(() {
                  _rule.useWebView = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchRuleCard() {
    return //搜索页面规则部分
    Card(
      margin: EdgeInsets.all(10),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12,
          children: [
            Text(
              'rule_edit.search_page_rules'.tr(),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            //搜索页面路径
            TextFormField(
              enabled: widget.isEditMode,
              initialValue: widget.rule?.searchUrl,
              decoration: InputDecoration(
                labelText: 'rule_edit.search_url_label'.tr(),
                hintText: 'rule_edit.search_url_hint'.tr(),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(20.0)),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _rule.searchUrl = value;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'rule_edit.search_url_validator'.tr();
                }
                return null;
              },
            ),
            //搜索请求方法
            DropdownButtonFormField<RequestMethod>(
              //  enabled: widget.isEditMode,
              initialValue: _rule.searchRequestMethod,
              decoration: InputDecoration(
                labelText: 'rule_edit.request_method_label'.tr(),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(20.0)),
                ),
              ),
              items: RequestMethod.values.map((e) {
                return DropdownMenuItem<RequestMethod>(
                  value: e,
                  child: Text(e.toString().split('.').last),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _rule.searchRequestMethod = value ?? RequestMethod.get;
                });
              },
            ),
            //请求体
            AnimatedSize(
              duration: Duration(milliseconds: 300),
              child: _rule.searchRequestMethod == RequestMethod.get
                  ? SizedBox.shrink()
                  : TextFormField(
                      enabled: widget.isEditMode,
                      initialValue: widget.rule?.searchRequestBody.entries
                          .map((e) => '${e.key}=${e.value}')
                          .join(','),
                      decoration: InputDecoration(
                        labelText: '请求体'.tr(),
                        hintText: 'key与value用=隔开,多个用英文逗号隔开'.tr(),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(20.0)),
                        ),
                      ),
                      onChanged: (value) {
                        var bodyList = value
                            .split(',')
                            .where((element) => element.contains('='))
                            .toList();
                        if (bodyList.isEmpty) {
                          return;
                        }
                        var body = {
                          for (var element in bodyList)
                            element.split('=')[0]: element.split('=')[1],
                        };
                        setState(() {
                          _rule.searchRequestBody = body;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '';
                        }
                        return null;
                      },
                    ),
            ),
            //搜索元素选择器
            TextFormField(
              enabled: widget.isEditMode,
              initialValue: widget.rule?.searchSelector,
              decoration: InputDecoration(
                labelText: 'rule_edit.search_selector_label'.tr(),
                hintText: 'rule_edit.search_selector_hint'.tr(),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(20.0)),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _rule.searchSelector = value;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'rule_edit.search_selector_validator'.tr();
                }
                return null;
              },
            ),
            //  搜索元素图片选择器
            TextFormField(
              enabled: widget.isEditMode,
              initialValue: widget.rule?.itemImgSelector,
              decoration: InputDecoration(
                labelText: 'rule_edit.item_img_selector_label'.tr(),
                hintText: 'rule_edit.item_img_selector_hint'.tr(),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(20.0)),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _rule.itemImgSelector = value;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'rule_edit.item_img_selector_validator'.tr();
                }
                return null;
              },
            ),
            //  搜索元素图片是否从src获取
            SwitchListTile(
              title: Text('rule_edit.item_img_from_src_label'.tr()),
              subtitle: Text('rule_edit.item_img_from_src_subtitle'.tr()),
              value: widget.rule?.itemImgFromSrc ?? _rule.itemImgFromSrc,
              onChanged: widget.isEditMode
                  ? (value) {
                      setState(() {
                        _rule.itemImgFromSrc = value;
                      });
                    }
                  : null,
            ),
            //  搜索元素标题选择器
            TextFormField(
              enabled: widget.isEditMode,
              initialValue: widget.rule?.itemTitleSelector,
              decoration: InputDecoration(
                labelText: 'rule_edit.item_title_selector_label'.tr(),
                hintText: 'rule_edit.item_title_selector_hint'.tr(),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(20.0)),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _rule.itemTitleSelector = value;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'rule_edit.item_title_selector_validator'.tr();
                }
                return null;
              },
            ),
            //  搜索元素id选择器
            TextFormField(
              enabled: widget.isEditMode,
              initialValue: widget.rule?.itemIdSelector,
              decoration: InputDecoration(
                labelText: 'rule_edit.item_id_selector_label'.tr(),
                hintText: 'rule_edit.item_id_selector_hint'.tr(),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(20.0)),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _rule.itemIdSelector = value;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'rule_edit.item_id_selector_validator'.tr();
                }
                return null;
              },
            ),
            //  搜索元素类型选择器
            TextFormField(
              enabled: widget.isEditMode,
              initialValue: widget.rule?.itemGenreSelector,
              decoration: InputDecoration(
                labelText: 'rule_edit.item_genre_selector_label'.tr(),
                hintText: 'rule_edit.item_genre_selector_hint'.tr(),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(20.0)),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _rule.itemGenreSelector = value;
                });
              },
            ),
            //  搜索请求头Referer
            TextFormField(
              enabled: widget.isEditMode,
              maxLines: 2,
              initialValue:
                  widget.rule?.searchRequestHeaders['Referer'] ?? ''.toString(),
              decoration: InputDecoration(
                labelText: "Referer",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(20.0)),
                ),
              ),
              onChanged: (value) {
                _rule.searchRequestHeaders = {'Referer': value};
              },
            ),
            //  搜索请求头User-Agent
            TextFormField(
              enabled: widget.isEditMode,
              maxLines: 2,
              initialValue:
                  widget.rule?.searchRequestHeaders['User-Agent'] ??
                  ''.toString(),
              decoration: InputDecoration(
                labelText: "User-Agent",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(20.0)),
                ),
              ),
              onChanged: (value) {
                _rule.searchRequestHeaders = {'User-Agent': value};
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 详情页规则
  Widget _buildDetalRuleCard() {
    return Card(
      margin: EdgeInsets.all(10),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12,
          children: [
            Text(
              'rule_edit.detail_page_rules'.tr(),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextFormField(
              enabled: widget.isEditMode,
              initialValue: widget.rule?.detailUrl,
              decoration: InputDecoration(
                labelText: 'rule_edit.detail_url_label'.tr(),
                hintText: 'rule_edit.detail_url_hint'.tr(),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(20.0)),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _rule.detailUrl = value;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'rule_edit.detail_url_validator'.tr();
                }
                return null;
              },
            ),
            //详情页请求方法
            DropdownButtonFormField<RequestMethod>(
              //  enabled: widget.isEditMode,
              initialValue: _rule.detailRequestMethod,
              decoration: InputDecoration(
                labelText: 'rule_edit.request_method_label'.tr(),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(20.0)),
                ),
              ),
              items: RequestMethod.values.map((e) {
                return DropdownMenuItem<RequestMethod>(
                  value: e,
                  child: Text(e.toString().split('.').last),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _rule.detailRequestMethod = value ?? RequestMethod.get;
                });
              },
            ),
            //请求体
            AnimatedSize(
              duration: Duration(milliseconds: 300),
              child: _rule.detailRequestMethod == RequestMethod.get
                  ? SizedBox()
                  : TextFormField(
                      enabled: widget.isEditMode,
                      initialValue: widget.rule?.detailRequestBody.entries
                          .map((e) => '${e.key}=${e.value}')
                          .join(','),
                      decoration: InputDecoration(
                        labelText: '请求体'.tr(),
                        hintText: 'key与value用=隔开,多个用英文逗号隔开'.tr(),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(20.0)),
                        ),
                      ),
                      onChanged: (value) {
                        if (value
                            .split(',')
                            .where((element) => element.contains('='))
                            .toList()
                            .isEmpty) {
                          return;
                        }
                        var body = {
                          for (var element in value.split(','))
                            element.split('=')[0]: element.split('=')[1],
                        };
                        setState(() {
                          _rule.detailRequestBody = body;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '';
                        }
                        return null;
                      },
                    ),
            ),
            //详情页播放路线选择器
            TextFormField(
              enabled: widget.isEditMode,
              initialValue: widget.rule?.lineSelector,
              decoration: InputDecoration(
                labelText: 'rule_edit.line_selector_label'.tr(),
                hintText: 'rule_edit.line_selector_hint'.tr(),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(20.0)),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _rule.lineSelector = value;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'rule_edit.line_selector_validator'.tr();
                }
                return null;
              },
            ),
            //详情页剧集选择器
            TextFormField(
              enabled: widget.isEditMode,
              initialValue: widget.rule?.episodeSelector,
              decoration: InputDecoration(
                labelText: 'rule_edit.episode_selector_label'.tr(),
                hintText: 'rule_edit.episode_selector_hint'.tr(),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(20.0)),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _rule.episodeSelector = value;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'rule_edit.episode_selector_validator'.tr();
                }
                return null;
              },
            ),
            //  详情页请求头Referer
            TextFormField(
              enabled: widget.isEditMode,
              maxLines: 2,
              initialValue:
                  widget.rule?.detailRequestHeaders['Referer'] ?? ''.toString(),
              decoration: InputDecoration(
                labelText: "Referer",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(20.0)),
                ),
              ),
              onChanged: (value) {
                _rule.detailRequestHeaders = {'Referer': value};
              },
            ),
            //  搜索请求头User-Agent
            TextFormField(
              enabled: widget.isEditMode,
              maxLines: 2,
              initialValue:
                  widget.rule?.detailRequestHeaders['User-Agent'] ??
                  ''.toString(),
              decoration: InputDecoration(
                labelText: "User-Agent",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(20.0)),
                ),
              ),
              onChanged: (value) {
                _rule.detailRequestHeaders = {'User-Agent': value};
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 播放页规则
  Widget _buildPlayerRuleCard() {
    return Card(
      margin: EdgeInsets.all(10),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12,
          children: [
            Text(
              'rule_edit.player_page_rules'.tr(),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            TextFormField(
              enabled: widget.isEditMode,
              initialValue: widget.rule?.playerUrl,
              decoration: InputDecoration(
                labelText: 'rule_edit.player_url_label'.tr(),
                hintText: 'rule_edit.player_url_hint'.tr(),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(20.0)),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _rule.playerUrl = value;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'rule_edit.player_url_validator'.tr();
                }
                return null;
              },
            ),
            //详情页请求方法
            DropdownButtonFormField<RequestMethod>(
              //  enabled: widget.isEditMode,
              initialValue: _rule.playerRequestMethod,
              decoration: InputDecoration(
                labelText: 'rule_edit.request_method_label'.tr(),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(20.0)),
                ),
              ),
              items: RequestMethod.values.map((e) {
                return DropdownMenuItem<RequestMethod>(
                  value: e,
                  child: Text(e.toString().split('.').last),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _rule.playerRequestMethod = value ?? RequestMethod.get;
                });
              },
            ),
            //请求体
            AnimatedSize(
              duration: Duration(milliseconds: 300),
              child: _rule.playerRequestMethod == RequestMethod.get
                  ? SizedBox()
                  : TextFormField(
                      enabled: widget.isEditMode,
                      initialValue: widget.rule?.playerRequestBody.entries
                          .map((e) => '${e.key}=${e.value}')
                          .join(','),
                      decoration: InputDecoration(
                        labelText: '请求体'.tr(),
                        hintText: 'key与value用=隔开,多个用英文逗号隔开'.tr(),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(20.0)),
                        ),
                      ),
                      onChanged: (value) {
                        if (value
                            .split(',')
                            .where((element) => element.contains('='))
                            .toList()
                            .isEmpty) {
                          return;
                        }
                        var body = {
                          for (var element in value.split(','))
                            element.split('=')[0]: element.split('=')[1],
                        };
                        setState(() {
                          _rule.playerRequestBody = body;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '';
                        }
                        return null;
                      },
                    ),
            ),
            //播放页面视频选择器
            TextFormField(
              enabled: widget.isEditMode,
              initialValue: widget.rule?.playerVideoSelector,
              decoration: InputDecoration(
                labelText: 'rule_edit.player_video_selector_label'.tr(),
                hintText: 'rule_edit.player_video_selector_hint'.tr(),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(20.0)),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _rule.playerVideoSelector = value;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'rule_edit.player_video_selector_validator'.tr();
                }
                return null;
              },
            ),
            //详情页视频元素属性选择器
            TextFormField(
              enabled: widget.isEditMode,
              initialValue: widget.rule?.videoElementAttribute,
              decoration: InputDecoration(
                labelText: 'rule_edit.video_element_attribute_label'.tr(),
                hintText: 'rule_edit.video_element_attribute_hint'.tr(),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(20.0)),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _rule.videoElementAttribute = value;
                });
              },
            ),
            //详情页等待视频元素加载开关
            SwitchListTile(
              value:
                  widget.rule?.waitForMediaElement ?? _rule.waitForMediaElement,
              onChanged: widget.isEditMode
                  ? (value) {
                      setState(() {
                        _rule.waitForMediaElement = value;
                      });
                    }
                  : null,
              title: Text('rule_edit.wait_for_media_element_label'.tr()),
              subtitle: Text('rule_edit.wait_for_media_element_subtitle'.tr()),
            ),
            TextFormField(
              enabled: widget.isEditMode,
              initialValue: widget.rule?.embedVideoSelector,
              decoration: InputDecoration(
                labelText: 'rule_edit.embed_video_selector_label'.tr(),
                hintText: 'rule_edit.embed_video_selector_hint'.tr(),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(20.0)),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _rule.embedVideoSelector = value;
                });
              },
            ),

            // TextFormField(
            //   enabled: widget.isEditMode,
            //   initialValue: widget.rule?.videoUrlSubsChar,
            //   decoration: InputDecoration(
            //     labelText: 'rule_edit.video_url_subs_char_label'
            //         .tr(),
            //     hintText: 'rule_edit.video_url_subs_char_hint'
            //         .tr(),
            //     border: OutlineInputBorder(
            //       borderRadius: BorderRadius.all(
            //         Radius.circular(20.0),
            //       ),
            //     ),
            //   ),
            //   onChanged: (value) {
            //     setState(() {
            //       _rule.videoUrlSubsChar = value;
            //     });
            //   },
            // ),
            //  播放请求头Referer
            TextFormField(
              enabled: widget.isEditMode,
              maxLines: 2,
              initialValue:
                  widget.rule?.playerRequestHeaders['Referer'] ?? ''.toString(),
              decoration: InputDecoration(
                labelText: "Referer",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(20.0)),
                ),
              ),
              onChanged: (value) {
                _rule.playerRequestHeaders = {'Referer': value};
              },
            ),
            //  播放请求头User-Agent
            TextFormField(
              enabled: widget.isEditMode,
              maxLines: 2,
              initialValue:
                  widget.rule?.playerRequestHeaders['User-Agent'] ??
                  ''.toString(),
              decoration: InputDecoration(
                labelText: "User-Agent",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(20.0)),
                ),
              ),
              onChanged: (value) {
                _rule.playerRequestHeaders = {'User-Agent': value};
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    var sources = Api.getSources();
    var services = sources.where(
      (element) => element.getName() == widget.rule?.name,
    );
    if (services.isNotEmpty) {
      _service = services.first;
    }
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    setState(() {
      _isTablet =
          Device.get().isTablet &&
          MediaQuery.of(context).orientation == Orientation.landscape;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actionsPadding: .symmetric(horizontal: 12),
        titleSpacing: 0,
        actions: _buildAppbarActions(),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text('rule_edit.title'.tr()),
      ),
      body: SafeArea(
        child: Row(
          children: [
            Flexible(
              fit: FlexFit.tight,
              child: SizedBox(
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildBasicCard(),
                        _buildSearchRuleCard(),
                        _buildDetalRuleCard(),
                        _buildPlayerRuleCard(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (_isTablet)
              Flexible(
                fit: FlexFit.tight,
                child: widget.rule == null || _service == null
                    ? Center(child: Text('保存规则后即可测试'))
                    : RuleTestScreen(source: _service!, showNavBtn: false),
              ),
          ],
        ),
      ),
    );
  }
}
