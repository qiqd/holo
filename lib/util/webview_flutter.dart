import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';

import 'package:holo/entity/rule.dart';
import 'package:holo/util/webview_util.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebviewFlutter extends WebviewUtil {
  final WebViewController _webViewController = WebViewController();
  @override
  Future<String> fetchHtml(
    String url, {
    RequestMethod requestMethod = RequestMethod.get,
    bool isPlayerPage = false,
    bool waitForMediaElement = false,
    Duration timeout = const Duration(seconds: 10),
    Map<String, String> headers = const {},
    Map<String, String> requestBody = const {},
    Function(String error)? onError,
  }) async {
    Completer<String> completer = Completer<String>();

    try {
      // 设置导航代理
      await _webViewController.setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) async {
            log(
              '页面加载完成,请求方法: $requestMethod,参数: ${requestBody.toString()},头部: ${headers.toString()},url: $url',
            );
            try {
              final Object html = await _webViewController
                  .runJavaScriptReturningResult(
                    'document.documentElement.outerHTML',
                  );

              String htmlContent = html.toString();
              if (containsUnicode(htmlContent)) {
                htmlContent = unescapeUnicodeString(htmlContent);
              }
              int count = 0;
              if (isPlayerPage && waitForMediaElement) {
                // 等待直到HTML内容中包含有效媒体元素或超时结束
                while (!hasValidMediaElements(htmlContent) &&
                    !completer.isCompleted) {
                  count++;
                  log('HTML内容中不包含有效媒体元素，继续等待...');

                  htmlContent =
                      (await _webViewController.runJavaScriptReturningResult(
                        'document.documentElement.outerHTML',
                      )).toString();
                  if (containsUnicode(htmlContent)) {
                    htmlContent = unescapeUnicodeString(htmlContent);
                  }
                  await Future.delayed(Duration(seconds: 1));
                  if (count == 50) {
                    log('html content:$htmlContent');
                  }
                }
              }
              htmlContent =
                  (await _webViewController.runJavaScriptReturningResult(
                    'document.documentElement.outerHTML',
                  )).toString();
              if (containsUnicode(htmlContent)) {
                htmlContent = unescapeUnicodeString(htmlContent);
              }
              // log('final html content:$htmlContent');
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
            // String errorMsg = 'WebView资源错误: ${error.description}';
            // if (onError != null) {
            //   onError(errorMsg);
            // }
            // if (!completer.isCompleted) {
            //   completer.completeError(errorMsg);
            // }
          },
        ),
      );
      log("loadRequest url:https://$url");

      Uint8List? bodyBytes;
      // 将 Map<String, String> 转换为表单格式的字符串
      String formBody = requestBody.entries
          .map(
            (entry) =>
                '${Uri.encodeComponent(entry.key)}=${Uri.encodeComponent(entry.value)}',
          )
          .join('&');
      bodyBytes = utf8.encode(formBody);
      await _webViewController.setUserAgent(headers['User-Agent']);
      await _webViewController.setJavaScriptMode(JavaScriptMode.unrestricted);
      log("loadRequest url:https://$url");

      await _webViewController.loadRequest(
        Uri.parse(url.contains("http") ? url : "https://$url"),
        method: requestMethod == RequestMethod.get
            ? LoadRequestMethod.get
            : LoadRequestMethod.post,
        body: bodyBytes,
        headers: headers,
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
