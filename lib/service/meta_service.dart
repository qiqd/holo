import 'package:holo/entity/calendar.dart';
import 'package:holo/entity/character.dart';
import 'package:holo/entity/episode.dart';
import 'package:holo/entity/person.dart';
import 'package:holo/entity/subject.dart' show Data, Subject;

import 'package:holo/entity/subject_relation.dart';

/// 元数据服务抽象类
/// 定义了所有元数据服务必须实现的方法
abstract class MetaService {
  /// 获取服务名称
  String get name;

  /// 获取网站logo地址
  String get logoUrl;

  /// 获取网站基础地址
  String get baseUrl;

  /// 搜索媒体
  /// [keyword] 搜索关键词
  /// [exception] 异常处理器
  /// 返回搜索结果
  Future<Subject?> fetchSearch(
    String keyword,
    void Function(dynamic) exception,
  );

  /// 获取推荐媒体
  /// [page] 页码
  /// [size] 每页数量
  /// [year] 年份
  /// [month] 月份
  /// [sort] 排序方式
  /// [exception] 异常处理器
  /// 返回推荐结果
  Future<Subject?> fetchRecommend({
    int page = 1,
    int size = 10,
    int year = 2019,
    int month = 1,
    String sort = "date",
    void Function(Exception)? exception,
  });

  /// 获取日历信息
  /// [exception] 异常处理器
  /// 返回日历列表
  Future<List<Calendar>> fetchCalendar(void Function(dynamic) exception);

  /// 获取媒体详情
  /// [subjectId] 媒体ID
  /// [exception] 异常处理器
  /// 返回媒体详情
  Future<Data?> fetchSubjectSync(
    int subjectId,
    void Function(dynamic) exception,
  );

  /// 获取人物信息
  /// [subjectId] 媒体ID
  /// [exception] 异常处理器
  /// 返回人物列表
  Future<List<Person>> fetchPerson(
    int subjectId,
    void Function(dynamic) exception,
  );

  /// 获取角色信息
  /// [subjectId] 媒体ID
  /// [exception] 异常处理器
  /// 返回角色列表
  Future<List<Character>> fetchCharacter(
    int subjectId,
    void Function(dynamic) exception,
  );

  /// 获取媒体关联信息
  /// [subjectId] 媒体ID
  /// [exception] 异常处理器
  /// 返回关联媒体列表
  Future<List<SubjectRelation>> fetchSubjectRelation(
    int subjectId,
    void Function(dynamic) exception,
  );

  /// 获取剧集信息
  /// [subjectId] 媒体ID
  /// [exception] 异常处理器
  /// 返回剧集信息
  Future<Episode?> fethcEpisode(
    int subjectId,
    void Function(dynamic) exception,
  );
}
