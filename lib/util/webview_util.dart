import 'dart:async';
import 'dart:developer';

import 'package:webview_flutter/webview_flutter.dart';

class WebviewUtil {
  static final WebViewController _webViewController = WebViewController();
  static bool containsUnicode(String str) {
    return !RegExp(r'^[\x00-\x7F]*$').hasMatch(str);
  }

  static String unescapeUnicodeString(String input) {
    // 处理 \\uXXXX 双转义（先变成 \uXXXX）
    String result = input.replaceAllMapped(RegExp(r'\\u([0-9a-fA-F]{4})'), (
      Match match,
    ) {
      int charCode = int.parse(match.group(1)!, radix: 16);
      return String.fromCharCode(charCode);
    });

    // 处理 \uXXXX 单转义
    result = result.replaceAllMapped(RegExp(r'\\u([0-9a-fA-F]{4})'), (
      Match match,
    ) {
      int charCode = int.parse(match.group(1)!, radix: 16);
      return String.fromCharCode(charCode);
    });

    // 处理其他常见的转义字符
    result = result
        .replaceAll(r'\"', '"')
        .replaceAll(r"\'", "'")
        .replaceAll(r'\n', '\n')
        .replaceAll(r'\t', '\t')
        .replaceAll(r'\r', '\r');

    return result;
  }

  static Future<String> fetchHtml(
    String url, {
    Duration timeout = const Duration(seconds: 10),
    Map<String, String>? headers,
    Function(String error)? onError,
  }) async {
    Completer<String> completer = Completer<String>();

    try {
      // 设置导航代理
      await _webViewController.setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) async {
            log('页面加载完成: $url');
            try {
              final Object html = await _webViewController
                  .runJavaScriptReturningResult(
                    'document.documentElement.outerHTML',
                  );
              String htmlContent = html.toString();

              if (!completer.isCompleted) {
                completer.complete(htmlContent);
              }
            } catch (jsError) {
              String error = 'JavaScript执行错误: ${jsError.toString()}';
              log(error);
              if (onError != null) {
                onError(error);
              }
              if (!completer.isCompleted) {
                completer.completeError(error);
              }
            }
          },
          onWebResourceError: (WebResourceError error) {
            log('error code ${error.errorCode}');
            log('WebView加载错误: ${error.description}');
            String errorMsg = 'WebView资源错误: ${error.description}';
            if (onError != null) {
              onError(errorMsg);
            }
            if (!completer.isCompleted) {
              completer.completeError(errorMsg);
            }
          },
        ),
      );

      await _webViewController.setJavaScriptMode(JavaScriptMode.unrestricted);

      await _webViewController.loadRequest(
        Uri.parse(url),
        headers: headers ?? {},
      );

      // 等待HTML获取完成并返回结果
      String htmlContent = await completer.future.timeout(
        timeout,
        onTimeout: () {
          String timeoutError = '页面加载超时';
          if (onError != null) {
            onError(timeoutError);
          }
          throw TimeoutException(timeoutError);
        },
      );
      if (containsUnicode(htmlContent)) {
        htmlContent = unescapeUnicodeString(htmlContent);
      }
      return htmlContent;
    } catch (e) {
      log('解析HTML错误: ${e.toString()}');
      String error = '解析HTML错误: ${e.toString()}';
      if (onError != null) {
        onError(error);
      }
      if (!completer.isCompleted) {
        completer.completeError(error);
      }
      // 如果completer没有完成，抛出异常
      if (!completer.isCompleted) {
        throw Exception(error);
      }
      // 返回completer的结果（这行实际上不会被执行，因为上面会抛出异常）
      return await completer.future;
    }
  }
}
