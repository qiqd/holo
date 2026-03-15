import 'package:holo/auth_config/auth_config.dart';
import 'package:holo/util/http_util.dart';

class AuthUtil {
  final AuthConfig authConfig;

  AuthUtil(this.authConfig);

  /// 构建授权URL
  String buildAuthUrl() {
    final Uri uri = Uri.parse(authConfig.authUrl);
    return uri
        .replace(
          queryParameters: {
            'client_id': authConfig.appId,
            'redirect_uri': authConfig.redirectUrl,
            'response_type': 'code',
          },
        )
        .toString();
  }

  /// 使用授权码交换访问令牌
  Future<AuthResponse?> exchangeCodeForToken({
    required String code,
    void Function(String)? onError,
  }) async {
    try {
      final response = await HttpUtil.createDio().post(
        authConfig.tokenUrl,
        data: {
          'client_id': authConfig.appId,
          'client_secret': authConfig.appSecret,
          'code': code,
          'redirect_uri': authConfig.redirectUrl,
          'grant_type': 'authorization_code',
        },
      );
      if (response.statusCode == 200) {
        return AuthResponse.fromJson(response.data);
      } else {
        onError?.call('获取token失败: ${response.data}');
        return null;
      }
    } catch (e) {
      onError?.call('获取token失败: $e');
      return null;
    }
  }

  /// 使用刷新令牌交换访问令牌
  Future<AuthResponse?> exchangeRefreshTokenForToken({
    required String refreshToken,
    void Function(String)? onError,
  }) async {
    try {
      final response = await HttpUtil.createDio().post(
        authConfig.tokenUrl,
        data: {
          'client_id': authConfig.appId,
          'client_secret': authConfig.appSecret,
          'grant_type': 'refresh_token',
          'refresh_token': refreshToken,
        },
      );
      if (response.statusCode == 200) {
        return AuthResponse.fromJson(response.data);
      } else {
        onError?.call('获取token失败: ${response.data}');
        return null;
      }
    } catch (e) {
      onError?.call('获取token失败: $e');
      return null;
    }
  }
}

class AuthResponse {
  final String accessToken;
  final int expiresIn;
  final String refreshToken;
  final String? scope;
  final String tokenType;

  AuthResponse({
    required this.accessToken,
    required this.expiresIn,
    required this.refreshToken,
    required this.scope,
    required this.tokenType,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['access_token'],
      expiresIn: json['expires_in'],
      refreshToken: json['refresh_token'],
      scope: json['scope'],
      tokenType: json['token_type'],
    );
  }
}
