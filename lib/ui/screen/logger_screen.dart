import 'package:flutter/material.dart';
import 'package:holo/extension/safe_set_state_extension.dart';
import 'package:holo/util/logger_util.dart';

class LoggerScreen extends StatefulWidget {
  const LoggerScreen({super.key});

  @override
  State<LoggerScreen> createState() => _LoggerScreenState();
}

class _LoggerScreenState extends State<LoggerScreen> {
  String _logString = "";

  @override
  void didChangeDependencies() {
    LoggerUtil.getLog().then((value) {
      safeSetState(() {
        _logString = value;
      });
    });
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actionsPadding: EdgeInsets.only(right: 12),
        title: Text("Logger"),
        actions: [
          IconButton(
            tooltip: "Clear log",
            icon: Icon(Icons.delete_outline_rounded),
            onPressed: () {
              LoggerUtil.clearLog();
              setState(() {
                _logString = "";
              });
            },
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12),
        child: _logString.isEmpty
            ? Center(child: Text("No log found"))
            : SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  child: SelectableText(
                    _logString,
                    //softWrap: false,
                    scrollPhysics: NeverScrollableScrollPhysics(),
                  ),
                ),
              ),
      ),
    );
  }
}
