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
            _buildTitle('rule_guide.title'.tr()),
            _buildParagraph('rule_guide.intro'.tr()),
            _buildDivider(),

            // 基础信息
            _buildSectionTitle('rule_guide.section_basic_info'.tr()),
            _buildTable([
              [
                'rule_guide.th_field'.tr(),
                'rule_guide.th_type'.tr(),
                'rule_guide.th_required'.tr(),
                'rule_guide.th_description'.tr(),
              ],
              ['name', 'string', 'rule_guide.yes'.tr(), 'rule_guide.fd_name'.tr()],
              ['baseUrl', 'string', 'rule_guide.yes'.tr(), 'rule_guide.fd_base_url'.tr()],
              ['logoUrl', 'string', 'rule_guide.no'.tr(), 'rule_guide.fd_logo_url'.tr()],
              ['useWebView', 'boolean', 'rule_guide.no'.tr(), 'rule_guide.fd_use_webview'.tr()],
              ['timeout', 'number', 'rule_guide.no'.tr(), 'rule_guide.fd_timeout'.tr()],
              ['isPureJs', 'boolean', 'rule_guide.no'.tr(), 'rule_guide.fd_is_pure_js'.tr()],
            ]),
            _buildDivider(),

            // 搜索页规则
            _buildSectionTitle('rule_guide.section_search_rules'.tr()),
            _buildSubTitle('rule_guide.sub_url_config'.tr()),
            _buildTable([
              [
                'rule_guide.th_field'.tr(),
                'rule_guide.th_description'.tr(),
                'rule_guide.th_example'.tr(),
              ],
              ['searchUrl', 'rule_guide.fd_search_url'.tr(), '/search?keyword={keyword}'],
              ['searchRequestMethod', 'rule_guide.fd_search_req_method'.tr(), 'get'],
              ['searchRequestHeaders', 'rule_guide.fd_req_headers'.tr(), '{"User-Agent": "..."}'],
              ['fullSearchUrl', 'rule_guide.fd_full_url'.tr(), 'false'],
            ]),
            SizedBox(height: 12),
            _buildSubTitle('rule_guide.sub_selector_config'.tr()),
            _buildTable([
              [
                'rule_guide.th_field'.tr(),
                'rule_guide.th_description'.tr(),
                'rule_guide.th_example'.tr(),
              ],
              ['searchSelector', 'rule_guide.fd_search_selector'.tr(), 'div.search-results'],
              ['itemImgSelector', 'rule_guide.fd_item_img_selector'.tr(), 'img'],
              ['itemImgFromSrc', 'rule_guide.fd_item_img_from_src'.tr(), 'true/false'],
              ['itemTitleSelector', 'rule_guide.fd_item_title_selector'.tr(), 'h3.title'],
              ['itemIdSelector', 'rule_guide.fd_item_id_selector'.tr(), 'a.detail-link'],
              ['itemGenreSelector', 'rule_guide.fd_item_genre_selector'.tr(), 'span.genre'],
            ]),
            SizedBox(height: 12),
            _buildSubTitle('rule_guide.sub_key_logic'.tr()),
            _buildParagraph('rule_guide.logic_search'.tr()),
            SizedBox(height: 12),
            _buildSubTitle('rule_guide.sub_search_selector_ways'.tr()),
            _buildParagraph('rule_guide.way1_container'.tr()),
            _buildCodeBlock('rule_guide.code_search_example_1'.tr()),
            _buildParagraph('rule_guide.way2_direct'.tr()),
            _buildCodeBlock('rule_guide.code_search_example_2'.tr()),
            _buildSubTitle('rule_guide.sub_common_errors'.tr()),
            _buildParagraph('rule_guide.error_same_selector'.tr()),
            _buildCodeBlock(
              '{\n'
              '  "searchSelector": "div.vod-grid > a.vod-card",\n'
              '  "itemIdSelector": "a.vod-card"\n'
              '}',
            ),
            _buildParagraph('rule_guide.ok_container'.tr()),
            _buildCodeBlock(
              '{\n'
              '  "searchSelector": "div.vod-grid",\n'
              '  "itemIdSelector": "a.vod-card"\n'
              '}',
            ),
            _buildDivider(),

            // 详情页规则
            _buildSectionTitle('rule_guide.section_detail_rules'.tr()),
            _buildSubTitle('rule_guide.sub_url_config'.tr()),
            _buildTable([
              [
                'rule_guide.th_field'.tr(),
                'rule_guide.th_description'.tr(),
                'rule_guide.th_example'.tr(),
              ],
              ['detailUrl', 'rule_guide.fd_detail_url'.tr(), '{mediaId}'],
              ['detailRequestMethod', 'rule_guide.fd_req_method'.tr(), 'get'],
              ['detailRequestHeaders', 'rule_guide.fd_req_headers'.tr(), '{"User-Agent": "..."}'],
              ['fullDetailUrl', 'rule_guide.fd_full_url'.tr(), 'false'],
            ]),
            SizedBox(height: 12),
            _buildSubTitle('rule_guide.sub_selector_config'.tr()),
            _buildTable([
              [
                'rule_guide.th_field'.tr(),
                'rule_guide.th_description'.tr(),
                'rule_guide.th_example'.tr(),
              ],
              ['lineSelector', 'rule_guide.fd_line_selector'.tr(), 'div.line-list'],
              ['episodeSelector', 'rule_guide.fd_episode_selector'.tr(), 'li > a'],
              ['episodeReverse', 'rule_guide.fd_episode_reverse'.tr(), 'false/true'],
            ]),
            SizedBox(height: 12),
            _buildSubTitle('rule_guide.sub_key_logic'.tr()),
            _buildParagraph('rule_guide.logic_detail'.tr()),
            _buildDivider(),

            // 播放页规则
            _buildSectionTitle('rule_guide.section_player_rules'.tr()),
            _buildSubTitle('rule_guide.sub_url_config'.tr()),
            _buildTable([
              [
                'rule_guide.th_field'.tr(),
                'rule_guide.th_description'.tr(),
                'rule_guide.th_example'.tr(),
              ],
              ['playerUrl', 'rule_guide.fd_player_url'.tr(), '{episodeId}'],
              ['playerRequestMethod', 'rule_guide.fd_req_method'.tr(), 'get'],
              ['playerRequestHeaders', 'rule_guide.fd_req_headers'.tr(), '{"User-Agent": "..."}'],
              ['fullPlayerUrl', 'rule_guide.fd_full_url'.tr(), 'false'],
            ]),
            SizedBox(height: 12),
            _buildSubTitle('rule_guide.sub_selector_config'.tr()),
            _buildTable([
              [
                'rule_guide.th_field'.tr(),
                'rule_guide.th_description'.tr(),
                'rule_guide.th_example'.tr(),
              ],
              ['playerVideoSelector', 'rule_guide.fd_player_video_selector'.tr(), 'video#player'],
              ['videoElementAttribute', 'rule_guide.fd_video_element_attr'.tr(), 'src'],
              ['embedVideoSelector', 'rule_guide.fd_embed_video_selector'.tr(), 'iframe'],
              ['waitForTargetElement', 'rule_guide.fd_wait_for_target'.tr(), 'true'],
              ['videoUrlSubsChar', 'rule_guide.fd_video_url_subs_char'.tr(), 'videoUrl='],
            ]),
            SizedBox(height: 12),
            _buildSubTitle('rule_guide.sub_key_logic'.tr()),
            _buildParagraph('rule_guide.logic_player'.tr()),
            _buildDivider(),

            // JS脚本规则
            _buildSectionTitle('rule_guide.section_js_scripts'.tr()),
            _buildParagraph('rule_guide.js_intro'.tr()),
            SizedBox(height: 12),
            _buildSubTitle('rule_guide.sub_config_fields'.tr()),
            _buildTable([
              [
                'rule_guide.th_field'.tr(),
                'rule_guide.th_description'.tr(),
                'rule_guide.th_return_format'.tr(),
              ],
              ['searchScript', 'rule_guide.fd_search_script'.tr(), '[{"id":"", "title":"", ...}]'],
              ['detailScript', 'rule_guide.fd_detail_script'.tr(), '{"lines": [{"episodes": [...]}]}'],
              ['playerScript', 'rule_guide.fd_player_script'.tr(), '{"videoUrl": "https://..."}'],
            ]),
            SizedBox(height: 12),
            _buildSubTitle('rule_guide.sub_priority'.tr()),
            _buildParagraph('rule_guide.priority_text'.tr()),
            SizedBox(height: 12),
            _buildSubTitle('rule_guide.sub_pure_js'.tr()),
            _buildParagraph('rule_guide.pure_js_desc'.tr()),
            _buildParagraph('rule_guide.pure_js_features_title'.tr()),
            _buildParagraph('rule_guide.pure_js_features'.tr()),
            _buildParagraph('rule_guide.pure_js_example_title'.tr()),
            _buildCodeBlock('rule_guide.code_pure_js'.tr()),
            SizedBox(height: 12),
            _buildSubTitle('rule_guide.sub_encoding'.tr()),
            _buildParagraph('rule_guide.encoding_desc'.tr()),
            _buildParagraph('rule_guide.original_js_title'.tr()),
            _buildCodeBlock(
              '(function() {\n'
              '  if (typeof player_aaaa !== \'undefined\' && player_aaaa.url) {\n'
              '    return JSON.stringify({ videoUrl: player_aaaa.url });\n'
              '  }\n'
              '  return JSON.stringify({ videoUrl: \'\' });\n'
              '})();',
            ),
            _buildParagraph('rule_guide.usage_scenarios_title'.tr()),
            _buildParagraph('rule_guide.usage_scenarios'.tr()),
            _buildDivider(),

            // 占位符说明
            _buildSectionTitle('rule_guide.section_placeholders'.tr()),
            _buildTable([
              [
                'rule_guide.th_placeholder'.tr(),
                'rule_guide.th_description'.tr(),
                'rule_guide.th_used_in'.tr(),
              ],
              ['{keyword}', 'rule_guide.fd_ph_keyword'.tr(), 'searchUrl'],
              ['{mediaId}', 'rule_guide.fd_ph_media_id'.tr(), 'detailUrl、playerUrl'],
              ['{episodeId}', 'rule_guide.fd_ph_episode_id'.tr(), 'playerUrl'],
            ]),
            SizedBox(height: 12),
            _buildParagraph('rule_guide.placeholder_note'.tr()),
            _buildDivider(),

            // 调试技巧
            _buildSectionTitle('rule_guide.section_debug_tips'.tr()),
            _buildParagraph('rule_guide.debug_tips'.tr()),
            _buildDivider(),

            // 常见问题
            _buildSectionTitle('rule_guide.section_faq'.tr()),
            _buildSubTitle('rule_guide.faq_q_empty_search'.tr()),
            _buildParagraph('rule_guide.faq_a_empty_search'.tr()),
            SizedBox(height: 8),
            _buildSubTitle('rule_guide.faq_q_no_episodes'.tr()),
            _buildParagraph('rule_guide.faq_a_no_episodes'.tr()),
            SizedBox(height: 8),
            _buildSubTitle('rule_guide.faq_q_no_video'.tr()),
            _buildParagraph('rule_guide.faq_a_no_video'.tr()),
            SizedBox(height: 8),
            _buildSubTitle('rule_guide.faq_q_js_empty'.tr()),
            _buildParagraph('rule_guide.faq_a_js_empty'.tr()),
            SizedBox(height: 8),
            _buildSubTitle('rule_guide.faq_q_base64'.tr()),
            _buildParagraph('rule_guide.faq_a_base64'.tr()),
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
