import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:holo/service/impl/animation/common.dart';
import 'package:holo/service/source_service.dart';

void main() {
  runApp(const SeviceCommonTest());
}

class SeviceCommonTest extends StatefulWidget {
  const SeviceCommonTest({super.key});

  @override
  State<SeviceCommonTest> createState() => _SeviceCommonTestState();
}

class _SeviceCommonTestState extends State<SeviceCommonTest> {
  final Common _sourceService = Common();
  String _keyword = '';
  String _mediaId = '';
  String _episodeId = '';
  void _search() async {
    final res = await _sourceService.fetchSearch(_keyword, 1, 1, (e) {
      log(e.toString());
    });
    log(jsonEncode(res));
  }

  void _detail() async {
    final res = await _sourceService.fetchDetail(_mediaId, (e) {
      log(e.toString());
    });
    log(jsonEncode(res));
  }

  void _player() async {
    final res = await _sourceService.fetchView(_episodeId, (e) {
      log(e.toString());
    });
    log(res.toString());
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: const Text('SeviceCommonTest')),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                onChanged: (value) {
                  setState(() {
                    _keyword = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: '搜索页',
                  label: const Text("搜索"),
                ),
              ),
              ElevatedButton(
                onPressed: () => _search(),
                child: const Text('Go'),
              ),
              Divider(),
              TextField(
                onChanged: (value) {
                  setState(() {
                    _mediaId = value;
                  });
                },
                decoration: InputDecoration(hintText: '详情页'),
              ),
              ElevatedButton(
                onPressed: () => _detail(),
                child: const Text('Go'),
              ),
              Divider(),
              TextField(
                onChanged: (value) {
                  setState(() {
                    _episodeId = value;
                  });
                },
                decoration: InputDecoration(hintText: '播放页'),
              ),
              ElevatedButton(
                onPressed: () => _player(),
                child: const Text('Go'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
