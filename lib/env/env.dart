import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied(path: '.env', obfuscate: true, allowOptionalFields: true)
abstract class Env {
  @EnviedField(varName: 'DAMMAKU_SERVER_URL')
  static final String? dammakuServerUrl = _Env.dammakuServerUrl;

  @EnviedField(varName: 'META_SERVER_URL')
  static final String? metaServerUrl = _Env.metaServerUrl;

  @EnviedField(varName: 'IMG_SERVER_URL')
  static final String? imgServerUrl = _Env.imgServerUrl;
}
