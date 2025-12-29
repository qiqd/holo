import 'dart:core';

import 'package:mobile_holo/entity/media.dart';

// HtmlParser 抽象类定义
abstract class SourceService {
  /// 名称
  String getName();

  /// 网站logo地址
  String getLogoUrl();

  /// 网站地址
  String getBaseUrl();
  int get delay;
  set delay(int value);

  /// 解析搜索结果
  ///
  /// @param keyword 搜索关键词
  /// @param page 页码
  /// @param size 每页数量
  /// @param exceptionHandler 异常处理器
  /// @return List @gt;Media@lt
  Future<List<Media>> fetchSearch(
    String keyword,
    int page,
    int size,
    Function(dynamic) exceptionHandler,
  );

  /// 解析详情信息
  ///
  /// @param mediaId 媒体ID
  /// @param exceptionHandler 异常处理器
  /// @return Detail
  Future<Detail?> fetchDetail(
    String mediaId,
    Function(dynamic) exceptionHandler,
  );

  /// 解析播放信息
  ///
  /// @param episodeId 剧集id
  /// @param exceptionHandler 异常处理器
  /// @return ViewInfo
  Future<String?> fetchView(
    String episodeId,
    Function(dynamic) exceptionHandler,
  );
}
