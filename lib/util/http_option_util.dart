import 'package:dio/dio.dart';

const defaultUserAgent = {
  "User-Agent":
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36 Edg/145.0.0.0',
};

Options getDefaultOptions({required String host, required String referer}) =>
    Options(headers: {"Host": host, "Referer": referer, ...defaultUserAgent});
