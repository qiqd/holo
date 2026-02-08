import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:holo/service/impl/meta/bangumi.dart';

void main() {
  var bangumi = Bangumi();
  group("service.bangumi", () {
    test("fetchSearchSync", () async {
      var res = await bangumi.fetchSearch("未来日记", (e) {
        print(e);
      });
      print(json.encode(res));
    });
    test("fetchSubjectSync", () async {
      var res = await bangumi.fetchSubjectSync(16235, (e) {
        print(e);
      });
      print(json.encode(res));
    });
    test("fetchCharacterSync", () async {
      var res = await bangumi.fetchCharacter(16235, (e) {
        print(e);
      });
      print(json.encode(res));
    });
    test("fetchPersonSync", () async {
      var res = await bangumi.fetchPerson(16235, (e) {
        print(e);
      });
      print(json.encode(res));
    });
    test("fetchSubjectRelationSync", () async {
      var res = await bangumi.fetchSubjectRelation(16235, (e) {
        print(e);
      });
      print(json.encode(res));
    });
  });
}
