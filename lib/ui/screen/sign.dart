import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_holo/api/account_api.dart';
import 'package:mobile_holo/util/local_store.dart';

enum AuthMode { login, register, reset }

class SignScreen extends StatefulWidget {
  const SignScreen({super.key});

  @override
  State<SignScreen> createState() => _SignScreenState();
}

class _SignScreenState extends State<SignScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final AuthMode _authMode = AuthMode.login;
  String _email = '';
  String _password = '';
  String _serverUrl = '';
  bool _isPasswordVisible = false;
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _login() {
    LocalStore.setServerUrl(_serverUrl);
    AccountApi.login(
      email: _email,
      password: _password,
      exceptionHandler: (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      },
    );
  }

  void _register() {
    AccountApi.register(
      email: _email,
      password: _password,
      exceptionHandler: (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      },
    );
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      switch (_authMode) {
        case AuthMode.login:
          _login();
          break;
        case AuthMode.register:
          _register();
          break;
        case AuthMode.reset:
          // 重置密码逻辑
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("欢迎回来"),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0).copyWith(top: 10),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              spacing: 20,
              children: [
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(50),
                    child: Image.asset('lib/images/launcher.png', width: 100),
                  ),
                ),
                // Server Url
                TextFormField(
                  onChanged: (value) => _serverUrl = value,
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: "Server Url",
                    hintText: "example: https://api.example.com",
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
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
                  onChanged: (value) => _email = value,
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: '邮箱',
                    prefixIcon: Icon(Icons.email),
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
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(),
                    suffixIcon: InkWell(
                      splashColor: Colors.transparent,
                      child: Icon(
                        _isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onTap: () => setState(
                        () => _isPasswordVisible = !_isPasswordVisible,
                      ),
                    ),
                  ),
                  obscureText: !_isPasswordVisible,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '请输入密码';
                    }

                    _password = value;
                    return null;
                  },
                ),

                // 登录按钮
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(onPressed: _submit, child: Text("验证")),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
