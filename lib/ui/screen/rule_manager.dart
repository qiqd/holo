import 'dart:convert';
import 'dart:developer';
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('导入失败,格式有误')));
    }
  }

  void _clipboardRulesToJson() {
    if (_rules.isEmpty) {
      return;
    }
    var jsonStr = json.encode(_rules);
    Clipboard.setData(ClipboardData(text: jsonStr));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('所有本地规则已复制到剪贴板')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('规则管理'),
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
                    title: const Text('从JSON导入'),
                    content: TextField(
                      maxLines: 10,
                      minLines: 5,
                      onChanged: (value) {
                        _rulesStr = value;
                      },
                      decoration: const InputDecoration(
                        hintText: '请输入规则JSON字符串',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    actions: [
                      OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text('取消'),
                      ),
                      FilledButton(
                        onPressed: () {
                          _importRulesFromJson();
                          Navigator.of(context).pop();
                        },
                        child: const Text('确认'),
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
                        extra: {'rule': _rules[index], 'isEditMode': false},
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
