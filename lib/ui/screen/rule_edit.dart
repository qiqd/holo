import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:holo/entity/rule.dart';
import 'package:holo/service/api.dart';
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
  String? _name;
  String? _baseUrl;
  String? _logoUrl;
  String? _searchUrl;
  final bool _fullSearchUrl = false;
  int? _timeout;
  String? _searchSelector;
  String? _itemImgSelector;
  bool _itemImgFromSrc = false;
  String? _itemTitleSelector;
  String? _itemIdSelector;
  String? _itemGenreSelector;
  String? _detailUrl;
  final bool _fullDetailUrl = false;
  String? _lineSelector;
  String? _episodeSelector;
  String? _playerUrl;
  final bool _fullPlayerUrl = false;
  String? _playerVideoSelector;
  String? _embedVideoSelector;
  String? _videoUrlSubsChar;
  String? _videoElementAttribute;
  bool _waitForMediaElement = false;
  void _saveRule() {
    if (!_formKey.currentState!.validate() || !widget.isEditMode) {
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
      videoElementAttribute: _videoElementAttribute,
      waitForMediaElement: _waitForMediaElement,
      updateAt: DateTime.now(),
    );
    LocalStore.saveRules([rule]);
    Api.initSources();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
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
        title: Text('rule_edit.title'.tr()),
      ),
      body: SafeArea(
        child: SizedBox(
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Card(
                    margin: EdgeInsets.all(10),
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Column(
                        spacing: 12,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'rule_edit.basic_info'.tr(),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          TextFormField(
                            enabled: widget.isEditMode,
                            initialValue: widget.rule?.name,
                            decoration: InputDecoration(
                              labelText: 'rule_edit.rule_name_label'.tr(),
                              hintText: 'rule_edit.rule_name_hint'.tr(),
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
                                return 'rule_edit.base_url_validator'.tr();
                              }
                              if (value.contains('://')) {
                                return 'rule_edit.base_url_protocol_validator'
                                    .tr();
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
                                return 'rule_edit.logo_url_validator'.tr();
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
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          TextFormField(
                            enabled: widget.isEditMode,
                            initialValue: widget.rule?.searchUrl,
                            decoration: InputDecoration(
                              labelText: 'rule_edit.search_url_label'.tr(),
                              hintText: 'rule_edit.search_url_hint'.tr(),
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
                                return 'rule_edit.search_url_validator'.tr();
                              }
                              if (value.contains('://')) {
                                return 'rule_edit.base_url_protocol_validator'
                                    .tr();
                              }
                              return null;
                            },
                          ),

                          TextFormField(
                            enabled: widget.isEditMode,
                            initialValue: widget.rule?.searchSelector,
                            decoration: InputDecoration(
                              labelText: 'rule_edit.search_selector_label'.tr(),
                              hintText: 'rule_edit.search_selector_hint'.tr(),
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
                                return 'rule_edit.search_selector_validator'
                                    .tr();
                              }
                              return null;
                            },
                          ),

                          TextFormField(
                            enabled: widget.isEditMode,
                            initialValue: widget.rule?.itemImgSelector,
                            decoration: InputDecoration(
                              labelText: 'rule_edit.item_img_selector_label'
                                  .tr(),
                              hintText: 'rule_edit.item_img_selector_hint'.tr(),
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
                                return 'rule_edit.item_img_selector_validator'
                                    .tr();
                              }
                              return null;
                            },
                          ),

                          SwitchListTile(
                            title: Text(
                              'rule_edit.item_img_from_src_label'.tr(),
                            ),
                            subtitle: Text(
                              'rule_edit.item_img_from_src_subtitle'.tr(),
                            ),
                            value:
                                widget.rule?.itemImgFromSrc ?? _itemImgFromSrc,
                            onChanged: widget.isEditMode
                                ? (value) {
                                    setState(() {
                                      _itemImgFromSrc = value;
                                    });
                                  }
                                : null,
                          ),

                          TextFormField(
                            enabled: widget.isEditMode,
                            initialValue: widget.rule?.itemTitleSelector,
                            decoration: InputDecoration(
                              labelText: 'rule_edit.item_title_selector_label'
                                  .tr(),
                              hintText: 'rule_edit.item_title_selector_hint'
                                  .tr(),
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
                                return 'rule_edit.item_title_selector_validator'
                                    .tr();
                              }
                              return null;
                            },
                          ),

                          TextFormField(
                            enabled: widget.isEditMode,
                            initialValue: widget.rule?.itemIdSelector,
                            decoration: InputDecoration(
                              labelText: 'rule_edit.item_id_selector_label'
                                  .tr(),
                              hintText: 'rule_edit.item_id_selector_hint'.tr(),
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
                                return 'rule_edit.item_id_selector_validator'
                                    .tr();
                              }
                              return null;
                            },
                          ),

                          TextFormField(
                            enabled: widget.isEditMode,
                            initialValue: widget.rule?.itemGenreSelector,
                            decoration: InputDecoration(
                              labelText: 'rule_edit.item_genre_selector_label'
                                  .tr(),
                              hintText: 'rule_edit.item_genre_selector_hint'
                                  .tr(),
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

                  Card(
                    margin: EdgeInsets.all(10),
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 12,
                        children: [
                          Text(
                            'rule_edit.detail_page_rules'.tr(),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          TextFormField(
                            enabled: widget.isEditMode,
                            initialValue: widget.rule?.detailUrl,
                            decoration: InputDecoration(
                              labelText: 'rule_edit.detail_url_label'.tr(),
                              hintText: 'rule_edit.detail_url_hint'.tr(),
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
                                return 'rule_edit.detail_url_validator'.tr();
                              }
                              if (value.contains('://')) {
                                return 'rule_edit.base_url_protocol_validator'
                                    .tr();
                              }
                              return null;
                            },
                          ),

                          TextFormField(
                            enabled: widget.isEditMode,
                            initialValue: widget.rule?.lineSelector,
                            decoration: InputDecoration(
                              labelText: 'rule_edit.line_selector_label'.tr(),
                              hintText: 'rule_edit.line_selector_hint'.tr(),
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
                                return 'rule_edit.line_selector_validator'.tr();
                              }
                              return null;
                            },
                          ),

                          TextFormField(
                            enabled: widget.isEditMode,
                            initialValue: widget.rule?.episodeSelector,
                            decoration: InputDecoration(
                              labelText: 'rule_edit.episode_selector_label'
                                  .tr(),
                              hintText: 'rule_edit.episode_selector_hint'.tr(),
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
                                return 'rule_edit.episode_selector_validator'
                                    .tr();
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  Card(
                    margin: EdgeInsets.all(10),
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 12,
                        children: [
                          Text(
                            'rule_edit.player_page_rules'.tr(),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          TextFormField(
                            enabled: widget.isEditMode,
                            initialValue: widget.rule?.playerUrl,
                            decoration: InputDecoration(
                              labelText: 'rule_edit.player_url_label'.tr(),
                              hintText: 'rule_edit.player_url_hint'.tr(),
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
                                return 'rule_edit.player_url_validator'.tr();
                              }
                              if (value.contains('://')) {
                                return 'rule_edit.base_url_protocol_validator'
                                    .tr();
                              }
                              return null;
                            },
                          ),

                          TextFormField(
                            enabled: widget.isEditMode,
                            initialValue: widget.rule?.playerVideoSelector,
                            decoration: InputDecoration(
                              labelText: 'rule_edit.player_video_selector_label'
                                  .tr(),
                              hintText: 'rule_edit.player_video_selector_hint'
                                  .tr(),
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
                                return 'rule_edit.player_video_selector_validator'
                                    .tr();
                              }
                              return null;
                            },
                          ),
                          TextFormField(
                            enabled: widget.isEditMode,
                            initialValue: widget.rule?.videoElementAttribute,
                            decoration: InputDecoration(
                              labelText:
                                  'rule_edit.video_element_attribute_label'
                                      .tr(),
                              hintText: 'rule_edit.video_element_attribute_hint'
                                  .tr(),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(20.0),
                                ),
                              ),
                            ),
                            onChanged: (value) {
                              setState(() {
                                _videoElementAttribute = value;
                              });
                            },
                          ),
                          SwitchListTile(
                            value:
                                widget.rule?.waitForMediaElement ??
                                _waitForMediaElement,
                            onChanged: widget.isEditMode
                                ? (value) {
                                    setState(() {
                                      _waitForMediaElement = value;
                                    });
                                  }
                                : null,
                            title: Text(
                              'rule_edit.wait_for_media_element_label'.tr(),
                            ),
                            subtitle: Text(
                              'rule_edit.wait_for_media_element_subtitle'.tr(),
                            ),
                          ),
                          TextFormField(
                            enabled: widget.isEditMode,
                            initialValue: widget.rule?.embedVideoSelector,
                            decoration: InputDecoration(
                              labelText: 'rule_edit.embed_video_selector_label'
                                  .tr(),
                              hintText: 'rule_edit.embed_video_selector_hint'
                                  .tr(),
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

                          TextFormField(
                            enabled: widget.isEditMode,
                            initialValue: widget.rule?.videoUrlSubsChar,
                            decoration: InputDecoration(
                              labelText: 'rule_edit.video_url_subs_char_label'
                                  .tr(),
                              hintText: 'rule_edit.video_url_subs_char_hint'
                                  .tr(),
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
