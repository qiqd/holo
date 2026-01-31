import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';

import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:holo/entity/rule.dart';
import 'package:holo/util/webview_util.dart';

class FlutterInappwebview extends WebviewUtil {
  HeadlessInAppWebView? _headlessWebView;
  InAppWebViewController? _webViewController;
  Completer<String>? _currentCompleter;

  @override
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
      rethrow;
    }
  }

  /// 清理资源（建议在 App 退出或不再需要时调用）
  void dispose() {
    log('释放 WebviewUtilFlutter 资源');
    _currentCompleter?.completeError('实例已释放');
    _currentCompleter = null;
    _headlessWebView?.dispose();
    _headlessWebView = null;
    _webViewController = null;
  }
}
