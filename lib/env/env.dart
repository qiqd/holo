import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied(path: '.env', obfuscate: true)
abstract class Env {
  static const String defaultMetaServerUrl = "https://api.bgm.tv";
  static const String defaultImgServerUrl = "https://lain.bgm.tv";
  static const String defaultDammakuServerUrl = "";

  @EnviedField(
    varName: 'DAMMAKU_SERVER_URL',
    obfuscate: true,
    defaultValue: defaultDammakuServerUrl,
  )
  static final String dammakuServerUrl = _Env.dammakuServerUrl;

  @EnviedField(
    varName: 'META_SERVER_URL',
    obfuscate: true,
    defaultValue: defaultMetaServerUrl,
  )
  static final String metaServerUrl = _Env.metaServerUrl;

  @EnviedField(
    varName: 'IMG_SERVER_URL',
    obfuscate: true,
    defaultValue: defaultImgServerUrl,
  )
  static final String imgServerUrl = _Env.imgServerUrl;
}
