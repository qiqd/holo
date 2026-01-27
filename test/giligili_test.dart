import 'dart:convert';
import 'dart:developer';

import 'package:flutter_test/flutter_test.dart';
import 'package:holo/service/impl/animation/girugiru.dart';

void main() {
  var girugiru = Girugiru();
  group("service.girugiru", () {
    test("fetchSearchSync", () async {
      var res = await girugiru.fetchSearch("JOJO", 1, 10, (e) {
        log(e);
      });
      print(json.encode(res));
    });
    test("fetchDetailSync", () async {
      var res = await girugiru.fetchDetail("/GV765/", (e) {
        log(e);
      });
      print(json.encode(res));
    });
    test("fetchViewSync", () async {
      var res = await girugiru.fetchPlaybackUrl("/playGV765-1-3/", (e) {
        log(e);
      });
      print(json.encode(res));
    });
  });
}
