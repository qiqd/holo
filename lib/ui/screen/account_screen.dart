import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:holo/api/web_dav.dart';
import 'package:holo/extension/safe_set_state_extension.dart';
import 'package:holo/main.dart';
import 'package:holo/util/hive_util.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../entity/user.dart' show User;

enum AuthMode { login, register, reset }

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _serverUrlController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late ScaffoldMessengerState _scaffoldMessage;
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  Future<void> _verifyWebDAV() async {
    if (_isLoading) {
      return;
    }

    // 验证表单
    if (!_formKey.currentState!.validate()) {
      return;
    }
    safeSetState(() {
      _isLoading = true;
    });
    final success = await WebDAV.login(
      url: _serverUrlController.text,
      email: _emailController.text,
      secret: _passwordController.text,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("sign.login_success".tr())));
      await HiveUtil.setUser(
        User(
          serverUrl: _serverUrlController.text,
          email: _emailController.text,
          secret: _passwordController.text,
          isLogin: true,
        ),
      );
      await HiveUtil.initHive();
      var userSetting = HiveUtil.getUserSetting().copyWith(
        email: _emailController.text,
      );
      WebDAV.init(HiveUtil.user);
      var s = await WebDAV.fetchUserSetting();
      if (s == null) {
        await WebDAV.syncUserSetting(userSetting);
        await MyApp.initAppSetting();
      } else {
        userSetting = s;
        HiveUtil.setUserSetting(userSetting);
      }
      MyApp.userSettingNotifier.value = userSetting;
      HiveUtil.setUserPlaybacks((await WebDAV.fetchUserPlayback()));
      HiveUtil.setUserSubscribes((await WebDAV.fetchUserSubscribe()));
      if (mounted) {
        TextInput.finishAutofillContext(shouldSave: true);
        context.go('/home');
      }
    } else if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("sign.verify_failed".tr())));
    }
    safeSetState(() {
      _isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _scaffoldMessage.hideCurrentSnackBar();
    _serverUrlController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _scaffoldMessage = ScaffoldMessenger.of(context);
    return Scaffold(
      appBar: AppBar(title: Text("sign.app_bar_title".tr()), centerTitle: true),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: AutofillGroup(
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
                                  'lib/images/launcher_round.webp',
                                  width: 100,
                                ),
                              ),
                            ),
                            //WebDav Server Url
                            TextFormField(
                              controller: _serverUrlController,
                              autofillHints: [AutofillHints.url],
                              textInputAction: TextInputAction.next,
                              decoration: InputDecoration(
                                labelText: "sign.server_url".tr(),
                                prefixIcon: Icon(Icons.link_rounded),
                                suffixIcon: ValueListenableBuilder(
                                  valueListenable: _serverUrlController,
                                  builder: (context, value, child) {
                                    return value.text.isNotEmpty
                                        ? IconButton(
                                            onPressed: () =>
                                                _serverUrlController.clear(),
                                            icon: Icon(Icons.clear_rounded),
                                          )
                                        : SizedBox.shrink();
                                  },
                                ),
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
                              autofillHints: [AutofillHints.email],
                              textInputAction: TextInputAction.next,
                              decoration: InputDecoration(
                                labelText: 'sign.email'.tr(),
                                prefixIcon: Icon(Icons.email_outlined),
                                suffixIcon: ValueListenableBuilder(
                                  valueListenable: _emailController,
                                  builder: (context, value, child) {
                                    return value.text.isNotEmpty
                                        ? IconButton(
                                            onPressed: () =>
                                                _emailController.clear(),
                                            icon: Icon(Icons.clear_rounded),
                                          )
                                        : SizedBox.shrink();
                                  },
                                ),
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
                              autofillHints: [AutofillHints.password],
                              textInputAction: TextInputAction.done,
                              decoration: InputDecoration(
                                labelText: 'sign.password'.tr(),
                                prefixIcon: Icon(Icons.lock_outlined),
                                border: OutlineInputBorder(),
                                suffixIcon: ValueListenableBuilder(
                                  valueListenable: _passwordController,
                                  builder: (context, value, child) {
                                    return value.text.isNotEmpty
                                        ? IconButton(
                                            onPressed: () => setState(() {
                                              _isPasswordVisible =
                                                  !_isPasswordVisible;
                                            }),
                                            icon: Icon(
                                              !_isPasswordVisible
                                                  ? Icons.visibility_off_rounded
                                                  : Icons.visibility_rounded,
                                            ),
                                          )
                                        : SizedBox.shrink();
                                  },
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
                            // 验证按钮
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton(
                                onPressed: _isLoading
                                    ? null
                                    : () => _verifyWebDAV(),
                                child: Text("sign.verify".tr()),
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
