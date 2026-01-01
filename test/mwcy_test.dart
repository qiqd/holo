import 'dart:convert';
import 'dart:developer';

import 'package:flutter_test/flutter_test.dart';
import 'package:holo/service/impl/animation/mwcy.dart';

void main() {
  var mwcy = Mwcy();
  group("service.mwcy", () {
    test("fetchSearchSync", () async {
      var res = await mwcy.fetchSearch("间谍过家家第三季", 1, 10, (e) {
        log(e);
      });
      print(json.encode(res));
    });
    test("fetchDetailSync", () async {
      var res = await mwcy.fetchDetail("/bangumi/YELCCS.html", (e) {
        log(e);
      });
      print(json.encode(res));
    });
    test("fetchViewSync", () async {
      var res = await mwcy.fetchView("/play/YELCCS-5-1.html", (e) {
        log(e);
      });
      print(json.encode(res));
    });
  });
}
