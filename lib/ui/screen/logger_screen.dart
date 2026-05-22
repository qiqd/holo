import 'package:flutter/material.dart';
import 'package:holo/util/logger_util.dart';

class LoggerScreen extends StatelessWidget {
  const LoggerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    var log = LoggerUtil.getLog();
    return Scaffold(
      appBar: AppBar(title: Text("Logger")),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12),
        child: log.isEmpty
            ? Center(child: Text("No log found"))
            : SingleChildScrollView(child: SelectableText(log)),
      ),
    );
  }
}
