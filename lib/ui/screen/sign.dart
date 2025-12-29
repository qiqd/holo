import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_holo/api/account_api.dart';

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

  final AuthMode _authMode = AuthMode.login;
  String _email = '';
  String _password = '';
  String _serverUrl = '';
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  @override
  void dispose() {
    _serverUrlController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _login(BuildContext context) {
    if (_isLoading) {
      return;
    }
    setState(() {
      _isLoading = true;
    });
    AccountApi.login(
      serverUrl: _serverUrl,
      email: _email,
      password: _password,
      successHandler: () {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("登录成功")));
        setState(() {
          _isLoading = false;
        });
        context.go('/home');
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
      body: Column(
        children: [
          if (_isLoading) LinearProgressIndicator(),
          Padding(
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
                        child: Image.asset(
                          'lib/images/launcher.png',
                          width: 100,
                        ),
                      ),
                    ),
                    // Server Url
                    TextFormField(
                      onChanged: (value) => _serverUrl = value,
                      controller: _serverUrlController,
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
                      onChanged: (value) => _password = value,
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
                      child: ElevatedButton(
                        onPressed: () => _login(context),
                        child: Text("验证"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
