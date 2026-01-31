import 'dart:developer';

import 'package:holo/entity/rule.dart';
import 'package:html/parser.dart' as html_parser;

abstract class WebviewUtil {
  bool containsUnicode(String str) {
    return !RegExp(r'^[\x00-\x7F]*$').hasMatch(str);
  }

  // 处理 \\uXXXX 和 \uXXXX
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

  /// 检查HTML内容是否包含有效媒体元素（iframe或video）
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
