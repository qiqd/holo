import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:holo/entity/rule.dart';
import 'package:html/parser.dart' as html_parser;

/// Flutter InAppWebView 工具类
/// 用于抓取网页内容，支持 JavaScript 执行和媒体元素检测
class FlutterInappwebview {
  /// 无头 WebView 实例
  HeadlessInAppWebView? _headlessWebView;
  /// WebView 控制器
  InAppWebViewController? _webViewController;
  /// 当前请求的完成器
  Completer<String>? _currentCompleter;

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
  }) async {
    final completer = Completer<String>();
    _currentCompleter = completer;

    try {
      final webUri = WebUri(url.startsWith('http') ? url : 'https://$url');

      final urlRequest = URLRequest(
        url: webUri,
        method: requestMethod == RequestMethod.get ? 'GET' : 'POST',
        headers: headers,
        body: requestBody.isNotEmpty
            ? Uint8List.fromList(
                utf8.encode(
                  requestBody.entries
                      .map(
                        (e) =>
                            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}',
                      )
                      .join('&'),
                ),
              )
            : null,
      );

      // 首次初始化
      if (_headlessWebView == null) {
        log('初始化 HeadlessInAppWebView...');

        _headlessWebView = HeadlessInAppWebView(
          initialSettings: InAppWebViewSettings(
            javaScriptEnabled: true,
            transparentBackground: true,
            clearCache: false, // 保持会话状态
            // 如果需要全局 UA，可在此设置；否则每次 headers 带
          ),
          onWebViewCreated: (controller) {
            _webViewController = controller;
            log('WebViewController 已创建');
          },
          onLoadStop: (controller, loadedUrl) async {
            log('页面加载完成: $loadedUrl');

            if (_currentCompleter == null || _currentCompleter!.isCompleted) {
              return;
            }

            try {
              String? html =
                  await controller.evaluateJavascript(
                        source: 'document.documentElement.outerHTML',
                      )
                      as String?;

              if (html == null || html.isEmpty) {
                _currentCompleter?.completeError('HTML 内容为空');
                return;
              }

              String htmlContent = html;
              if (containsUnicode(htmlContent)) {
                htmlContent = unescapeUnicodeString(htmlContent);
              }

              // 如果需要等待媒体元素
              if (isPlayerPage && waitForMediaElement) {
                int count = 0;
                const maxWait = 30; // 最多等待 30 秒

                while (!hasValidMediaElements(htmlContent) && count < maxWait) {
                  log('等待媒体元素... ($count/$maxWait)');
                  await Future.delayed(const Duration(seconds: 1));
                  html =
                      await controller.evaluateJavascript(
                            source: 'document.documentElement.outerHTML',
                          )
                          as String?;
                  htmlContent = html ?? '';
                  if (containsUnicode(htmlContent)) {
                    htmlContent = unescapeUnicodeString(htmlContent);
                  }
                  count++;
                }

                if (count >= maxWait) {
                  log('等待媒体元素超时');
                }
              }

              _currentCompleter?.complete(htmlContent);
            } catch (e) {
              final errMsg = '获取 HTML 失败: $e';
              log(errMsg);
              _currentCompleter?.completeError(errMsg);
            } finally {
              _currentCompleter = null;
            }
          },
          onLoadError: (controller, request, code, message) {
            final err = '加载错误 [$code]: $message';
            log(err);
            _currentCompleter?.completeError(err);
            _currentCompleter = null;
          },
          onConsoleMessage: (controller, consoleMessage) {
            log('JS Console: ${consoleMessage.message}');
          },
        );

        await _headlessWebView!.run();
        log('HeadlessInAppWebView 已启动');
      }

      // 执行加载（初次或复用）
      if (_webViewController != null) {
        log('加载 URL: $url');
        await _webViewController!.loadUrl(urlRequest: urlRequest);
      } else {
        throw Exception('WebViewController 未就绪');
      }

      // 等待结果
      String htmlContent = await completer.future.timeout(
        timeout,
        onTimeout: () {
          final msg = '加载超时 (${timeout.inSeconds}s)';
          onError?.call(msg);
          throw TimeoutException(msg);
        },
      );

      // 最终 unicode 处理
      if (containsUnicode(htmlContent)) {
        htmlContent = unescapeUnicodeString(htmlContent);
      }

      return htmlContent;
    } catch (e) {
      final errMsg = 'fetchHtml 异常: $e';
      log(errMsg);
      onError?.call(errMsg);
      return '';
    }
  }

  /// 清理资源
  /// 释放 WebView 实例和相关资源
  void dispose() {
    log('释放 WebviewUtilFlutter 资源');
    _currentCompleter?.completeError('实例已释放');
    _currentCompleter = null;
    _headlessWebView?.dispose();
    _headlessWebView = null;
    _webViewController = null;
  }
}