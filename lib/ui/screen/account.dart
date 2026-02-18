import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:holo/api/account_api.dart';
import 'package:holo/main.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:easy_localization/easy_localization.dart';

enum AuthMode { login, register, reset }

class SignScreen extends StatefulWidget {
  const SignScreen({super.key});

  @override
  State<SignScreen> createState() => _SignScreenState();
}

class _SignScreenState extends State<SignScreen> {
  final _formKey = GlobalKey<FormState>();
  final _serverUrlController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  AuthMode _authMode = AuthMode.login;
  // final String _email = '';
  // final String _password = '';
  // final String _serverUrl = '';
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _serverUrlController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _loginOrRegister() {
    if (_isLoading) {
      return;
    }

    // 验证表单
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // 如果是注册模式，额外验证密码一致性
    if (_authMode == AuthMode.register) {
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('sign.password_not_match'.tr())));
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    AccountApi.loginOrRegister(
      isRegister: _authMode == AuthMode.register,
      serverUrl: _serverUrlController.text,
      email: _emailController.text,
      password: _passwordController.text,
      successHandler: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _authMode == AuthMode.register
                  ? "sign.register_success".tr()
                  : "sign.login_success".tr(),
            ),
          ),
        );
        setState(() {
          _authMode = AuthMode.login;
          _isLoading = false;
        });
        MyApp.initAppSetting();
        if (_authMode == AuthMode.login) {
          context.go('/home');
        }
      },
      exceptionHandler: (e) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      },
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("sign.help".tr()),
        content: Text("sign.help_content".tr()),
        actions: [
          TextButton(
            onPressed: () {
              launchUrl(Uri.parse('https://github.com/qiqd/holo_service'));
            },
            child: Text("sign.how_to_deploy".tr()),
          ),
          TextButton(
            onPressed: () => context.pop(),
            child: Text("sign.close".tr()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("sign.app_bar_title".tr()),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.help_outline_rounded),
            onPressed: () {
              _showHelpDialog();
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    if (_isLoading) LinearProgressIndicator(),
                    Padding(
                      padding: const EdgeInsets.all(16.0).copyWith(top: 10),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          spacing: 20,
                          children: [
                            Center(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: Image.asset(
                                  'lib/images/launcher_round.png',
                                  width: 100,
                                ),
                              ),
                            ),
                            // Server Url
                            TextFormField(
                              controller: _serverUrlController,
                              decoration: InputDecoration(
                                labelText: "sign.server_url".tr(),
                                hintText: "sign.server_url_hint".tr(),
                                prefixIcon: Icon(Icons.link_rounded),
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.url,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'sign.please_enter_server_url'.tr();
                                }
                                if (!value.contains('://')) {
                                  return 'sign.please_enter_valid_server_url'
                                      .tr();
                                }
                                return null;
                              },
                            ),
                            // 邮箱输入框
                            TextFormField(
                              controller: _emailController,
                              decoration: InputDecoration(
                                labelText: 'sign.email'.tr(),
                                prefixIcon: Icon(Icons.email_outlined),
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'sign.please_enter_email'.tr();
                                }
                                if (!value.contains('@')) {
                                  return 'sign.please_enter_valid_email'.tr();
                                }
                                return null;
                              },
                            ),

                            // 密码输入框
                            TextFormField(
                              controller: _passwordController,
                              decoration: InputDecoration(
                                labelText: 'sign.password'.tr(),
                                prefixIcon: Icon(Icons.lock_outlined),
                                border: OutlineInputBorder(),
                                suffixIcon: InkWell(
                                  splashColor: Colors.transparent,
                                  child: Icon(
                                    _isPasswordVisible
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                  ),
                                  onTap: () => setState(
                                    () => _isPasswordVisible =
                                        !_isPasswordVisible,
                                  ),
                                ),
                              ),
                              obscureText: !_isPasswordVisible,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'sign.please_enter_password'.tr();
                                }
                                return null;
                              },
                            ),
                            // 确认密码输入框 - 使用 AnimatedOpacity 添加动画效果
                            AnimatedOpacity(
                              opacity: _authMode == AuthMode.register
                                  ? 1.0
                                  : 0.0,
                              duration: Duration(milliseconds: 300),
                              child: _authMode == AuthMode.register
                                  ? TextFormField(
                                      controller: _confirmPasswordController,
                                      decoration: InputDecoration(
                                        labelText: 'sign.confirm_password'.tr(),
                                        prefixIcon: Icon(Icons.lock),
                                        border: OutlineInputBorder(),
                                        suffixIcon: InkWell(
                                          splashColor: Colors.transparent,
                                          child: Icon(
                                            _isConfirmPasswordVisible
                                                ? Icons.visibility
                                                : Icons.visibility_off,
                                          ),
                                          onTap: () => setState(
                                            () => _isConfirmPasswordVisible =
                                                !_isConfirmPasswordVisible,
                                          ),
                                        ),
                                      ),
                                      obscureText: !_isConfirmPasswordVisible,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'sign.please_enter_confirm_password'
                                              .tr();
                                        }
                                        if (value != _passwordController.text) {
                                          return 'sign.password_not_match'.tr();
                                        }
                                        return null;
                                      },
                                    )
                                  : SizedBox.shrink(),
                            ),
                            // 登录/注册按钮
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton(
                                onPressed: _isLoading
                                    ? null
                                    : () => _loginOrRegister(),
                                child: Text(
                                  _authMode == AuthMode.login
                                      ? "sign.login".tr()
                                      : "sign.register".tr(),
                                ),
                              ),
                            ),

                            Center(
                              child: TextButton(
                                onPressed: () => setState(() {
                                  _authMode = _authMode == AuthMode.login
                                      ? AuthMode.register
                                      : AuthMode.login;
                                  // 切换模式时清空确认密码字段
                                  _confirmPasswordController.clear();
                                }),
                                child: Text(
                                  (_authMode == AuthMode.login
                                      ? 'sign.switch_to_register'.tr()
                                      : 'sign.switch_to_login'.tr()),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
