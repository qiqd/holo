import 'package:flutter/material.dart';
import 'package:holo/api/rule_api.dart';
import 'package:holo/entity/rule.dart';
import 'package:holo/extension/safe_set_state.dart';
import 'package:holo/util/local_store.dart';

class RuleRepository extends StatefulWidget {
  const RuleRepository({super.key});

  @override
  State<RuleRepository> createState() => _RuleRepositoryState();
}

class _RuleRepositoryState extends State<RuleRepository> {
  List<Rule> _rules = [];
  List<Rule> _localRules = LocalStore.getRules();
  bool _isLoading = false;
  Future<void> _getRules() async {
    safeSetState(() {
      _isLoading = true;
    });
    var r = await RuleApi.getRules(
      onError: (error) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error)));
      },
    );
    safeSetState(() {
      _rules = r;
      _isLoading = false;
    });
  }

  void _saveRule(Rule rule) {
    LocalStore.saveRules([rule]);
  }

  Widget _buildTileTrailing(Rule rule) {
    if (_localRules.any(
          (e) => double.parse(e.version) < double.parse(rule.version),
        ) ||
        !_localRules.any((e) => e.name == rule.name)) {
      return IconButton(
        onPressed: () {
          safeSetState(() {
            _saveRule(rule);
            _localRules = LocalStore.getRules();
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => _getRules(),
          ),
        ],
      ),
      body: SizedBox.expand(
        child: Column(
          children: [
            if (_isLoading) const Center(child: LinearProgressIndicator()),
            Flexible(
              child: ListView.builder(
                padding: .symmetric(horizontal: 12, vertical: 6),
                itemCount: _rules.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: SizedBox(
                      width: 60,
                      height: 60,
                      child: Image.network(
                        'https://${_rules[index].logoUrl}',
                        loadingBuilder: (context, child, loadingProgress) =>
                            loadingProgress == null
                            ? child
                            : const Center(child: CircularProgressIndicator()),
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
    );
  }
}
