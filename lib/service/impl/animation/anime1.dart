import 'package:holo/entity/media.dart';
import 'package:holo/service/source_service.dart';

class Anime1 implements SourceService {
  @override
  String getBaseUrl() {
    return "https://www.anime1.me";
  }

  @override
  String getLogoUrl() {
    return "https://anime1.me/apple-touch-icon.png";
  }

  @override
  String getName() {
    return "Anime1";
  }

  @override
  int delay = 9999;

  @override
  Future<Detail?> fetchDetail(
    String mediaId,
    Function(dynamic) exceptionHandler,
  ) {
    // TODO: implement fetchDetail
    throw UnimplementedError();
  }

  @override
  Future<String?> fetchPlaybackUrl(
    String episodeId,
    Function(dynamic) exceptionHandler,
  ) {
    // TODO: implement fetchPlaybackUrl
    throw UnimplementedError();
  }

  @override
  Future<List<Media>> fetchSearch(
    String keyword,
    int page,
    int size,
    Function(dynamic) exceptionHandler,
  ) async {
    // var searchUrl = "${getBaseUrl()}/?s=$keyword";
    // var res = await HttpUtil.createDio(referer: getBaseUrl()).get(searchUrl);
    throw UnimplementedError();
  }
}
