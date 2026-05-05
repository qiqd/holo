import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:holo/util/logger_util.dart';

class LoggerScreen extends StatelessWidget {
  const LoggerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    var log = LoggerUtil.getLog();
    return Scaffold(
      appBar: AppBar(
        title: Text("Logger"),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: log.isEmpty
          ? Center(child: Text("No log found"))
          : SingleChildScrollView(child: SelectableText(log)),
    );
  }
}
