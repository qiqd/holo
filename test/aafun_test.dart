import 'dart:convert';
import 'dart:developer';

import 'package:flutter_test/flutter_test.dart';
import 'package:holo/service/api.dart';
import 'package:holo/service/impl/animation/aafun.dart';
import 'package:holo/util/dio_timing_extension.dart';
import 'package:holo/util/http_util.dart';

void main() {
  var aafun = AAfun();
  group("service.bangumi", () {
    test("fetchSearchSync", () async {
      var res = await aafun.fetchSearch("未来日记", 1, 10, (e) {
        log(e);
      });
      print(json.encode(res));
    });
    test("fetchDetail", () async {
      var res = await aafun.fetchDetail("/feng-n/7RCCCS.html", (e) {
        print(e);
      });
      print(json.encode(res));
    });
    test("fetchView", () async {
      var res = await aafun.fetchPlaybackUrl("/f/7RCCCS-2-9.html", (e) {
        print(e);
      });
      print(json.encode(res));
    });
    test("dio getWithTiming", () async {
      final response = await HttpUtil.createDio().getWithTiming(
        'https://www.baidu.com',
      );
      final duration = response.extra['request_duration'] as int?;
      print('请求耗时: $duration ms');
    });
    test(" delay test", () async {
      await Api.delayTest();
      Api.getSources().forEach((element) {
        print("${element.getName()} delay: ${element.delay}");
      });
    });
  });
}
