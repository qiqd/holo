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

  Future<Subject?> fetchSearchSync(
    String keyword,
    void Function(dynamic) exception,
  );

  Future<Subject?> fetchRecommendSync(
    int page,
    int size,
    int year,
    int month,
    void Function(dynamic) exception,
  );

  Future<List<Calendar>> fetchCalendarSync(void Function(dynamic) exception);

  Future<Data?> fetchSubjectSync(
    int subjectId,
    void Function(dynamic) exception,
  );

  Future<List<Person>> fetchPersonSync(
    int subjectId,
    void Function(dynamic) exception,
  );

  Future<List<Character>> fetchCharacterSync(
    int subjectId,
    void Function(dynamic) exception,
  );

  Future<List<SubjectRelation>> fetchSubjectRelationSync(
    int subjectId,
    void Function(dynamic) exception,
  );
  Future<Episode?> fethcEpisodeSync(
    int subjectId,
    void Function(dynamic) exception,
  );
}
