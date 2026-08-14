import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied(path: '.env', obfuscate: true, allowOptionalFields: true)
abstract class Env {
  static const String defaultMetaServerUrl = "https://api.bgm.tv";
  static const String defaultImgServerHost = "https://lain.bgm.tv";

  @EnviedField(varName: 'DAMMAKU_SERVER_URL')
  static final String dammakuServerUrl = _Env.dammakuServerUrl ?? '';

  @EnviedField(varName: 'META_SERVER_URL')
  static final String metaServerUrl =
      _Env.metaServerUrl ?? defaultMetaServerUrl;

  @EnviedField(varName: 'IMG_SERVER_URL')
  static final String imgServerUrl = _Env.imgServerUrl ?? defaultImgServerHost;
}
