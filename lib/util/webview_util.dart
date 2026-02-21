import 'dart:developer';
import 'dart:async';

import 'package:holo/entity/rule.dart';
import 'package:html/parser.dart' as html_parser;

/// WebView 工具抽象类
/// 提供网页内容获取和处理的通用方法
abstract class WebviewUtil {
  /// 检查字符串是否包含 Unicode 字符
  /// [str]: 要检查的字符串
  /// 返回是否包含 Unicode 字符
  bool containsUnicode(String str) {
    return !RegExp(r'^[\x00-\x7F]*$').hasMatch(str);
  }

  /// 处理 Unicode 转义序列
  /// 支持 \uXXXX 和 \uXXXX 格式
  /// [input]: 包含转义序列的字符串
  /// 返回解码后的字符串
  String unescapeUnicodeString(String input) {
    String result = input;

    result = result.replaceAllMapped(RegExp(r'\\{1,2}u([0-9a-fA-F]{4})'), (
      Match match,
    ) {
      int charCode = int.parse(match.group(1)!, radix: 16);
      return String.fromCharCode(charCode);
    });

    // 处理常见转义
    result = result
        .replaceAll(r'\"', '"')
        .replaceAll(r"\'", "'")
        .replaceAll(r'\n', '\n')
        .replaceAll(r'\t', '\t')
        .replaceAll(r'\r', '\r');

    return result;
  }

  /// 检查 HTML 内容是否包含有效媒体元素（iframe 或 video）
  /// [htmlContent]: HTML 内容字符串
  /// 返回是否包含有效媒体元素
  bool hasValidMediaElements(String htmlContent) {
    try {
      final doc = html_parser.parse(htmlContent);
      final iframes = doc.querySelectorAll('iframe');
      final videos = doc.querySelectorAll('video');

      for (var iframe in iframes) {
        final src = iframe.attributes['src'];
        if (src != null && src.contains('http')) return true;
      }

      for (var video in videos) {
        final src = video.attributes['src'];
        if (src != null && src.contains('http')) return true;
      }

      return false;
    } catch (e) {
      log('HTML解析失败: $e');
      return false;
    }
  }

  /// 获取网页 HTML 内容
  /// [url]: 要访问的 URL
  /// [requestMethod]: 请求方法，默认为 GET
  /// [isPlayerPage]: 是否为播放器页面
  /// [waitForMediaElement]: 是否等待媒体元素加载
  /// [timeout]: 超时时间，默认为 15 秒
  /// [headers]: 请求头
  /// [requestBody]: 请求体，仅用于 POST 请求
  /// [onError]: 错误回调
  /// 返回获取的 HTML 内容
  Future<String> fetchHtml(
    String url, {
    RequestMethod requestMethod = RequestMethod.get,
    bool isPlayerPage = false,
    bool waitForMediaElement = false,
    Duration timeout = const Duration(seconds: 15),
    Map<String, String> headers = const {},
    Map<String, String> requestBody = const {},
    Function(String error)? onError,
  });
}