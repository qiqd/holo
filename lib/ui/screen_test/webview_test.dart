import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:webview_flutter/webview_flutter.dart' as webview_flutter;

void main(List<String> args) {
  runApp(const WebviewTestApp());
}

class WebviewTestApp extends StatelessWidget {
  const WebviewTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WebView测试',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const WebviewTest(),
    );
  }
}

class WebviewTest extends StatefulWidget {
  const WebviewTest({super.key});

  @override
  State<WebviewTest> createState() => _WebviewTestState();
}

class _WebviewTestState extends State<WebviewTest> {
  final TextEditingController _urlController = TextEditingController();
  final webview_flutter.WebViewController _webViewController =
      webview_flutter.WebViewController();
  InAppWebViewController? _inAppWebViewController;
  late final HeadlessInAppWebView _headlessWebViewController =
      HeadlessInAppWebView();
  bool _isLoading = false;
  String _currentUrl = '';
  @override
  void initState() {
    super.initState();
    // 设置WebView控制器
    _webViewController
      ..setJavaScriptMode(webview_flutter.JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        webview_flutter.NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
              _currentUrl = url;
            });
          },
          onPageFinished: (String url) async {
            setState(() {
              _isLoading = false;
            });
            // final Object html = await _webViewController
            //     .runJavaScriptReturningResult(
            //       'document.documentElement.outerHTML',
            //     );
            // String htmlContent = html.toString();
            // log(
            //   'htmlContent:${WebviewUtil.unescapeUnicodeString(htmlContent)}',
            // );
          },
          onWebResourceError: (webview_flutter.WebResourceError error) {
            setState(() {
              _isLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('加载错误: ${error.description}'),
                backgroundColor: Colors.red,
              ),
            );
          },
        ),
      );

    // 设置默认URL
    _urlController.text =
        'https://tv.yinghuadongman.info/yinghua_gb6222m-1-10.html';
    _loadUrl('https://tv.yinghuadongman.info/yinghua_gb6222m-1-10.html');
  }

  void _loadUrl(String url) {
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入网址'), backgroundColor: Colors.orange),
      );
      return;
    }

    // 如果URL没有协议，添加https://
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }

    setState(() {
      _isLoading = true;
    });

    _webViewController.loadRequest(Uri.parse(url));
  }

  void _onSubmit() {
    _loadUrl(_urlController.text);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WebView测试页面'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              if (_currentUrl.isNotEmpty) {
                _loadUrl(_currentUrl);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // URL输入区域
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _urlController,
                    decoration: InputDecoration(
                      hintText: '输入网址 (例如: www.baidu.com)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (_) => _onSubmit(),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _onSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('加载'),
                ),
              ],
            ),
          ),

          // 当前URL显示
          if (_currentUrl.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.grey[200],
              width: double.infinity,
              child: Text(
                '当前页面: $_currentUrl',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

          // WebView区域
          Expanded(
            child: Stack(
              children: [
                webview_flutter.WebViewWidget(controller: _webViewController),
                if (_isLoading)
                  Container(
                    color: Colors.white.withOpacity(0.8),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('正在加载页面...'),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
