import 'dart:core';

import 'package:holo/entity/media.dart';

/// 动画源服务抽象类
/// 定义了所有动画源服务必须实现的方法
abstract class SourceService {
  /// 获取服务名称
  /// 返回服务名称字符串
  String getName();

  /// 获取网站logo地址
  /// 返回logo URL字符串
  String getLogoUrl();

  /// 获取网站基础地址
  /// 返回基础URL字符串
  String getBaseUrl();

  /// 获取服务延迟时间
  /// 返回延迟时间（毫秒）
  int get delay;

  /// 设置服务延迟时间
  /// [value] 延迟时间（毫秒）
  set delay(int value);

  /// 搜索媒体
  /// [keyword] 搜索关键词
  /// [page] 页码
  /// [size] 每页数量
  /// [exceptionHandler] 异常处理器
  /// 返回媒体列表
  Future<List<Media>> fetchSearch(
    String keyword,
    int page,
    int size,
    Function(dynamic) exceptionHandler,
  );

  /// 解析媒体详情信息
  /// [mediaId] 媒体ID
  /// [exceptionHandler] 异常处理器
  /// 返回详情信息对象
  Future<Detail?> fetchDetail(
    String mediaId,
    Function(dynamic) exceptionHandler,
  );

  /// 解析播放地址
  /// [episodeId] 剧集ID
  /// [exceptionHandler] 异常处理器
  /// 返回播放地址字符串
  Future<String?> fetchPlaybackUrl(
    String episodeId,
    Function(dynamic) exceptionHandler,
  );
}
