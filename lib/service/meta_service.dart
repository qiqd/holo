import 'package:holo/entity/calendar.dart';
import 'package:holo/entity/character.dart';
import 'package:holo/entity/episode.dart';
import 'package:holo/entity/person.dart';
import 'package:holo/entity/subject.dart' show Data, Subject;

import 'package:holo/entity/subject_relation.dart';

abstract class MetaService {
  String get name;

  String get logoUrl;

  String get baseUrl;

  Future<Subject?> fetchSearch(
    String keyword,
    void Function(dynamic) exception,
  );

  Future<Subject?> fetchRecommend({
    int page = 1,
    int size = 10,
    int year = 2019,
    int month = 1,
    String sort = "date",
    void Function(Exception)? exception,
  });

  Future<List<Calendar>> fetchCalendar(void Function(dynamic) exception);

  Future<Data?> fetchSubjectSync(
    int subjectId,
    void Function(dynamic) exception,
  );

  Future<List<Person>> fetchPerson(
    int subjectId,
    void Function(dynamic) exception,
  );

  Future<List<Character>> fetchCharacter(
    int subjectId,
    void Function(dynamic) exception,
  );

  Future<List<SubjectRelation>> fetchSubjectRelation(
    int subjectId,
    void Function(dynamic) exception,
  );
  Future<Episode?> fethcEpisode(
    int subjectId,
    void Function(dynamic) exception,
  );
}
