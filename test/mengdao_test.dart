import 'dart:convert';
import 'dart:developer';

import 'package:flutter_test/flutter_test.dart';
import 'package:holo/service/impl/animation/mengdao.dart';

void main() {
  var mengdao = Mengdao();
  group("service.bangumi", () {
    test("fetchSearchSync", () async {
      var res = await mengdao.fetchSearch("JOJO的奇妙冒险", 1, 10, (e) {
        log(e);
      });
      print(json.encode(res));
    });
    test("fetchDetailSync", () async {
      var res = await mengdao.fetchDetail("/man/914596.html", (e) {
        log(e);
      });
      print(json.encode(res));
    });
    test("fetchViewSync", () async {
      var res = await mengdao.fetchView("/man_v/14596-0-5.html", (e) {
        log(e.toString());
      });
      print(json.encode(res));
    });
  });
}
