import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:holo/extension/safe_set_state_extension.dart';
import 'package:holo/util/logger_util.dart';

class LoggerScreen extends StatefulWidget {
  const LoggerScreen({super.key});

  @override
  State<LoggerScreen> createState() => _LoggerScreenState();
}

class _LoggerScreenState extends State<LoggerScreen> {
  String _logString = "";

  Future<void> _showConfirmDialog() {
    return showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(tr("logger.dialog_title")),
          content: Text(tr("logger.dialog_content")),
          actions: [
            OutlinedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(tr("common.dialog.cancel")),
            ),
            FilledButton(
              onPressed: () {
                LoggerUtil.clearLog();
                safeSetState(() {
                  _logString = "";
                });
                Navigator.of(context).pop(true);
              },
              child: Text(tr("common.dialog.confirm")),
            ),
          ],
        );
      },
    );
  }

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
            tooltip: "Copy log to clipboard",
            icon: Icon(Icons.copy_all_rounded),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: _logString));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Log copied to clipboard")),
              );
            },
          ),
          IconButton(
            tooltip: "Clear log",
            icon: Icon(Icons.delete_outline_rounded),
            onPressed: () {
              _showConfirmDialog();
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
