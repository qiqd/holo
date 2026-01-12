import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:holo/util/http_util.dart';
import 'package:image_picker/image_picker.dart';

class AnimeTrace {
  static final String baseUrl = 'https://api.animetrace.com';
  Future<List<Map<String, dynamic>>?> findAnimeFromImage({
    required XFile image,
    Function(String msg)? onError,
  }) async {
    try {
      final file = await MultipartFile.fromFile(image.path);
      final formData = FormData.fromMap({'file': file, 'ai_detect': true});
      final res = await HttpUtil.createDio().post(
        '$baseUrl/v1/search',
        data: formData,
      );
      if (res.statusCode == 200) {
        var data = res.data as Map<String, dynamic>;
        var list = data['data'] as List<dynamic>;
        var first = list.first as Map<String, dynamic>;
        return (first['character'] as List)
            .map((e) => e as Map<String, dynamic>)
            .toList();
      }
      return null;
    } catch (e) {
      log("AnimeTrace.findAnimeFromImage error: $e");
      onError?.call(e.toString());
      return null;
    }
  }
}
