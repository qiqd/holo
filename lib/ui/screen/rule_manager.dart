import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RuleManager extends StatefulWidget {
  const RuleManager({super.key});

  @override
  State<RuleManager> createState() => _RuleManagerState();
}

class _RuleManagerState extends State<RuleManager> {
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
            icon: const Icon(Icons.add_rounded),
            onPressed: () {
              context.push('/rule_edit');
            },
          ),
        ],
      ),
      body: const Center(child: Text('规则管理界面')),
    );
  }
}
