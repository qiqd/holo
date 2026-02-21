import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:holo/entity/rule.dart';
import 'package:holo/service/common.dart';
import 'package:holo/util/flutter_inappwebview.dart';
import 'package:logger/logger.dart';

void main() {
  runApp(const SeviceCommonTest());
}

class SeviceCommonTest extends StatefulWidget {
  const SeviceCommonTest({super.key});

  @override
  State<SeviceCommonTest> createState() => _SeviceCommonTestState();
}

class _SeviceCommonTestState extends State<SeviceCommonTest> {
  late final Common _sourceService = Common.build(
    Rule(
      name: "樱花动漫2",
      baseUrl: 'https://www.czzymovie.com',
      logoUrl:
          'https://tv.yinghuadongman.info/upload/mxprocms/20260114-1/f765273ee1a2bd224227ca581fdf22f8.jpg',
      searchUrl:
          'https://tv.yinghuadongman.info/search_-------------.html?wd={keyword}',
      fullSearchUrl: false,
      searchSelector: 'div.module-card-item.module-item',
      itemImgSelector: 'div.module-item-pic img',
      itemImgFromSrc: false,
      itemTitleSelector: 'div.module-card-item-title a',
      itemIdSelector: 'div.module-card-item-title a',
      itemGenreSelector: 'div.module-info-item-content',
      detailUrl: 'https://tv.yinghuadongman.info{mediaId}',
      fullDetailUrl: false,
      lineSelector: 'div#panel1',
      episodeSelector: 'a',
      playerUrl: 'https://tv.yinghuadongman.info{episodeId}',
      fullPlayerUrl: false,
      embedVideoSelector: 'td#playleft>iframe',
      timeout: 30,
      playerVideoSelector: 'video#lelevideo',
      waitForMediaElement: true,
    ),
  );
  String _keyword = '';
  String _mediaId = '';
  String _episodeId = '';
  final Logger _logger = Logger();
  final FlutterInappwebview _webviewUtil = FlutterInappwebview();
  void _fetchHTML() async {
    final res = await _webviewUtil.fetchHtml(
      'https://player.gugu3.com/?url=vwnet-c64cf37de43ce4a854f35f19d6ab7a26&next=//www.gugu3.com/index.php/vod/play/id/4878/sid/2/nid/3.html',
      timeout: Duration(seconds: 30),
      headers: {'referer': 'https://www.gugu3.com/'},

      onError: (e) {
        log('fetchHtml error:$e');
      },
    );
    _logger.i('fetchHtml res:$res');
  }

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
    final res = await _sourceService.fetchPlaybackUrl(_episodeId, (e) {
      log('fetchView error:$e');
    });
    log('fetchView res:$res');
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(title: const Text('SeviceCommonTest')),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              FilledButton(
                onPressed: () => _fetchHTML(),
                child: Text('fetch html'),
              ),
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
