import 'dart:io';

import 'package:flutter/material.dart';
import 'package:holo/api/rule_api.dart';
import 'package:holo/entity/rule.dart';
import 'package:holo/extension/safe_set_state_extension.dart';
import 'package:holo/util/hive_util.dart';

class RuleRepository extends StatefulWidget {
  const RuleRepository({super.key});

  @override
  State<RuleRepository> createState() => _RuleRepositoryState();
}

class _RuleRepositoryState extends State<RuleRepository> {
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();
  List<Rule> _rules = [];
  bool _isLoading = false;
  late List<Rule> _localRules;
  Future<void> _getRules() async {
    safeSetState(() {
      _isLoading = true;
    });
    _localRules = HiveUtil.getRules();
    var r = await RuleApi.getRules(
      onError: (error) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(error)));
        }
      },
    );
    safeSetState(() {
      _rules = r;
      _isLoading = false;
    });
  }

  Future<void> _saveRule(Rule rule) async {
    await HiveUtil.setRule(rule);
  }

  Widget _buildTileTrailing(Rule rule) {
    if (_localRules.any(
          (e) => double.parse(e.version) < double.parse(rule.version),
        ) ||
        !_localRules.any((e) => e.name == rule.name)) {
      return IconButton(
        onPressed: () async {
          await _saveRule(rule);
          safeSetState(() {
            _localRules = HiveUtil.getRules();
          });
        },
        icon: const Icon(Icons.download_rounded),
      );
    } else {
      return const IconButton(onPressed: null, icon: Icon(Icons.check_rounded));
    }
  }

  @override
  void initState() {
    super.initState();
    _getRules();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("规则仓库"),
        actionsPadding: .symmetric(horizontal: 12),
        actions: [
          if (Platform.isWindows || Platform.isMacOS || Platform.isLinux)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () => _getRules(),
            ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          key: _refreshIndicatorKey,
          onRefresh: _getRules,
          child: SizedBox.expand(
            child: Column(
              children: [
                if (_isLoading &&
                    (Platform.isWindows ||
                        Platform.isMacOS ||
                        Platform.isLinux))
                  const Center(child: LinearProgressIndicator()),
                Flexible(
                  child: ListView.builder(
                    padding: .symmetric(horizontal: 12, vertical: 6),
                    itemCount: _rules.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        onTap: () {},
                        leading: SizedBox(
                          width: 60,
                          height: 60,
                          child: Image.network(
                            _rules[index].logoUrl,
                            loadingBuilder: (context, child, loadingProgress) =>
                                loadingProgress == null
                                ? child
                                : const Center(
                                    child: CircularProgressIndicator(
                                      year2023: false,
                                    ),
                                  ),
                            errorBuilder: (context, error, stackTrace) =>
                                const Center(child: Icon(Icons.error_rounded)),
                          ),
                        ),
                        title: Text(_rules[index].name),
                        subtitle: Text(_rules[index].version),
                        trailing: _buildTileTrailing(_rules[index]),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
