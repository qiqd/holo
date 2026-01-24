import 'dart:convert';
import 'dart:developer';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:holo/entity/rule.dart';
import 'package:holo/service/api.dart';
import 'package:holo/util/local_store.dart';

class RuleManager extends StatefulWidget {
  const RuleManager({super.key});

  @override
  State<RuleManager> createState() => _RuleManagerState();
}

class _RuleManagerState extends State<RuleManager> {
  List<Rule> _rules = LocalStore.getRules();
  String _rulesStr = '';
  final bool _isUpdating = false;
  void _importRulesFromJson() {
    if (_rulesStr.isEmpty) {
      return;
    }
    try {
      var rules = (json.decode(_rulesStr) as List)
          .map((e) => Rule.fromJson(e))
          .toList();
      LocalStore.saveRules(rules);
      setState(() {
        _rules = LocalStore.getRules();
      });
    } catch (e) {
      log('Import rules failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('rule_manager.import_failure'.tr())),
      );
    }
  }

  void _clipboardRulesToJson() {
    if (_rules.isEmpty) {
      return;
    }
    var jsonStr = json.encode(_rules);
    Clipboard.setData(ClipboardData(text: jsonStr));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('rule_manager.copy_to_clipboard'.tr())),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Text('rule_manager.title'.tr()),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () {
            context.pop();
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            onPressed: () {
              _clipboardRulesToJson();
            },
          ),
          if (LocalStore.getRuleRepositoryUrl().isNotEmpty)
            IconButton(
              onPressed: () {
                // TODO规则更新逻辑待完成
              },
              icon: Icon(Icons.update_rounded),
            ),
          IconButton(
            icon: const Icon(Icons.inventory_2_rounded),
            onPressed: () {
              context.push('/rule_repository');
            },
          ),
          IconButton(
            icon: const Icon(Icons.content_copy_rounded),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: Text('rule_manager.import_from_json'.tr()),
                    content: TextField(
                      maxLines: 10,
                      minLines: 5,
                      onChanged: (value) {
                        _rulesStr = value;
                      },
                      decoration: InputDecoration(
                        hintText: 'rule_manager.import_from_json_hint'.tr(),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    actions: [
                      OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text('rule_manager.cancel'.tr()),
                      ),
                      FilledButton(
                        onPressed: () {
                          _importRulesFromJson();
                          Navigator.of(context).pop();
                        },
                        child: Text('rule_manager.confirm'.tr()),
                      ),
                    ],
                  );
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () {
              context.push('/rule_edit', extra: {'isEditMode': true});
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () {
          setState(() {
            _rules = LocalStore.getRules();
          });
          Api.initSources();
          return Future.value(null);
        },
        child: Column(
          children: [
            if (_isUpdating)
              Padding(padding: .only(top: 4), child: LinearProgressIndicator()),
            Expanded(
              child: ListView.builder(
                itemCount: _rules.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_rules[index].name),
                    subtitle: Text('v${_rules[index].version}'),
                    onTap: () {
                      context.push(
                        '/rule_edit',
                        extra: {
                          'rule': _rules[index],
                          'isEditMode': _rules[index].isLocal,
                        },
                      );
                    },
                    leading: SizedBox(
                      width: 40,
                      height: 40,
                      child: Image.network(
                        'https://${_rules[index].logoUrl}',
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Icon(
                              Icons.broken_image_rounded,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          );
                        },
                      ),
                    ),
                    trailing: SizedBox(
                      width: 110,
                      child: Row(
                        spacing: 4,
                        children: [
                          IconButton(
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.delete_rounded),
                            onPressed: () {
                              setState(() {
                                LocalStore.removeRuleByName(_rules[index].name);
                                _rules.removeAt(index);
                              });
                            },
                          ),

                          Switch(
                            padding: .zero,
                            value: _rules[index].isEnabled,
                            onChanged: (value) {
                              setState(() {
                                _rules[index].isEnabled = value;
                                LocalStore.updateRule(_rules[index]);
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
