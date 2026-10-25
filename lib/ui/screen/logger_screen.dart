import 'dart:async';

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
  bool _isLoading = false;
  List<String> _logLines = [];

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
                  _logLines = [];
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

  Future<void> _getLog() async {
    safeSetState(() {
      _isLoading = true;
    });
    final logString = await LoggerUtil.getLog();
    _logLines = logString.split("\n");
    safeSetState(() {
      _isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _getLog();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actionsPadding: EdgeInsets.only(right: 12),
        title: Text('logger.title'.tr()),
        actions: [
          IconButton(
            tooltip: 'logger.copy_tooltip'.tr(),
            icon: Icon(Icons.copy_all_rounded),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: _logLines.join("\n")));
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('logger.copied'.tr())));
            },
          ),
          IconButton(
            tooltip: 'logger.clear_tooltip'.tr(),
            icon: Icon(Icons.delete_outline_rounded),
            onPressed: () {
              _showConfirmDialog();
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(year2023: false))
          : SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: _logLines.isEmpty
                    ? Center(child: Text('logger.no_log'.tr()))
                    : ListView.builder(
                        itemCount: _logLines.length,
                        itemBuilder: (context, index) {
                          return SelectableText(_logLines[index]);
                        },
                      ),
              ),
            ),
    );
  }
}
