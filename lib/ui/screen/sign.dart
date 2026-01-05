import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:holo/api/account_api.dart';
import 'package:url_launcher/url_launcher.dart';

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
        ).showSnackBar(SnackBar(content: Text('两次输入密码不一致')));
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
            content: Text(_authMode == AuthMode.register ? "注册成功" : "登录成功"),
          ),
        );
        setState(() {
          _authMode = AuthMode.login;
          _isLoading = false;
        });
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
        title: const Text("如何使用"),
        content: const Text(
          "由于App不会存储任何有关用户的信息，如果想要保存自己的账号信息，在使用前请部署自己的服务器,点击查看如何部署",
        ),
        actions: [
          TextButton(
            onPressed: () {
              launchUrl(Uri.parse('https://github.com/qiqd/holo_backend'));
            },
            child: const Text("如何部署"),
          ),
          TextButton(onPressed: () => context.pop(), child: const Text("关闭")),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("欢迎回来"),
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
                                borderRadius: BorderRadius.circular(50),
                                child: Image.asset(
                                  'lib/images/launcher.png',
                                  width: 100,
                                ),
                              ),
                            ),
                            // Server Url
                            TextFormField(
                              controller: _serverUrlController,
                              decoration: const InputDecoration(
                                labelText: "Server Url",
                                hintText: "example: https://api.example.com",
                                prefixIcon: Icon(Icons.link_rounded),
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.url,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return '请输入Server Url';
                                }
                                if (!value.contains('://')) {
                                  return '请输入有效的Server Url';
                                }
                                return null;
                              },
                            ),
                            // 邮箱输入框
                            TextFormField(
                              controller: _emailController,
                              decoration: const InputDecoration(
                                labelText: '邮箱',
                                prefixIcon: Icon(Icons.email_outlined),
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return '请输入邮箱';
                                }
                                if (!value.contains('@')) {
                                  return '请输入有效的邮箱地址';
                                }
                                return null;
                              },
                            ),

                            // 密码输入框
                            TextFormField(
                              controller: _passwordController,
                              decoration: InputDecoration(
                                labelText: '密码',
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
                                  return '请输入密码';
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
                                        labelText: '确认密码',
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
                                          return '请输入确认密码';
                                        }
                                        if (value != _passwordController.text) {
                                          return '两次输入密码不一致';
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
                                  _authMode == AuthMode.login ? "登录" : "注册",
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
                                  "切换至${_authMode == AuthMode.login ? '注册' : '登录'}",
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
