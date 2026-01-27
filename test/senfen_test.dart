import 'dart:convert';
import 'dart:developer';

import 'package:flutter_test/flutter_test.dart';
import 'package:holo/service/impl/animation/senfen.dart';

void main() {
  var senfen = Senfen();
  group("service.senfen", () {
    test("fetchSearchSync", () async {
      var res = await senfen.fetchSearch("间谍过家家第三季", 1, 10, (e) {
        log(e);
      });
      print(json.encode(res));
    });
    test("fetchDetail", () async {
      var res = await senfen.fetchDetail("/voddetail/2025702564.html", (e) {
        log(e);
      });
      print(json.encode(res));
    });
    test("fetchView", () async {
      var res = await senfen.fetchPlaybackUrl("/vodwatch/2025702564/ep1.html", (
        e,
      ) {
        log(e);
      });
      print(json.encode(res));
    });
  });
}
