import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:holo/api/web_dav.dart';
import 'package:holo/entity/user_setting.dart';
import 'package:holo/main.dart';
import 'package:holo/util/hive_util.dart';

class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({super.key});

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  // 主题颜色相关状态
  Color _selectedPrimaryColor = Color(
    MyApp.userSettingNotifier.value.colorSeed,
  );

  // 预设颜色列表
  final List<Color> _presetColors = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.purple,
    Colors.orange,
    Colors.teal,
    Colors.indigo,
    Colors.cyan,
    Colors.amber,
    Colors.deepPurple,
    Colors.lightBlue,
    Colors.deepOrange,
  ];

  // 自定义颜色样本
  final Map<ColorSwatch<Object>, String> _customSwatches =
      <ColorSwatch<Object>, String>{
        ColorTools.createPrimarySwatch(const Color(0xFF6200EE)): 'Purple',
        ColorTools.createPrimarySwatch(const Color(0xFF03DAC6)): 'Teal',
        ColorTools.createPrimarySwatch(const Color(0xFF018786)): 'Dark Teal',
        ColorTools.createPrimarySwatch(const Color(0xFF005457)):
            'Very Dark Teal',
        ColorTools.createPrimarySwatch(const Color(0xFFBB86FC)): 'Light Purple',
        ColorTools.createPrimarySwatch(const Color(0xFF3700B3)): 'Dark Purple',
        ColorTools.createPrimarySwatch(const Color(0xFF03DAC5)): 'Accent Teal',
        ColorTools.createPrimarySwatch(const Color(0xFF00E5FF)): 'Cyan Accent',
        ColorTools.createPrimarySwatch(const Color(0xFF6200EA)): 'Deep Purple',
        ColorTools.createPrimarySwatch(const Color(0xFF64FFDA)): 'Aqua Green',
      };
  String _getThemeModeText() {
    final themeMode = MyApp.userSettingNotifier.value.themeMode;
    switch (themeMode) {
      case 0:
        return 'preference.theme_mode_system'.tr();

      case 1:
        return 'preference.theme_mode_light'.tr();
      case 2:
        return 'preference.theme_mode_dark'.tr();
      default:
        return 'preference.theme_mode_system'.tr();
    }
  }

  Future<void> _showThemeModeDialog() async {
    UserSetting userSetting = MyApp.userSettingNotifier.value;
    ThemeMode? currentTheme = ThemeMode.values[userSetting.themeMode];
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('preference.theme_dialog_title'.tr()),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<ThemeMode>(
                  title: Text('preference.theme_mode_system'.tr()),
                  value: ThemeMode.system,
                  groupValue: currentTheme,
                  onChanged: (ThemeMode? value) {
                    if (value != null) {
                      setState(() {
                        currentTheme = value;
                      });
                    }
                  },
                ),
                RadioListTile<ThemeMode>(
                  title: Text('preference.theme_mode_light'.tr()),
                  value: ThemeMode.light,
                  groupValue: currentTheme,
                  onChanged: (ThemeMode? value) {
                    if (value != null) {
                      setState(() {
                        currentTheme = value;
                      });
                    }
                  },
                ),
                RadioListTile<ThemeMode>(
                  title: Text('preference.theme_mode_dark'.tr()),
                  value: ThemeMode.dark,
                  groupValue: currentTheme,
                  onChanged: (ThemeMode? value) {
                    if (value != null) {
                      setState(() {
                        currentTheme = value;
                      });
                    }
                  },
                ),
              ],
            );
          },
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: Text('preference.theme_dialog_cancel'.tr()),
          ),
          FilledButton(
            onPressed: () {
              MyApp.userSettingNotifier.value = userSetting.copyWith(
                themeMode: currentTheme?.index,
              );

              Navigator.pop(context);
            },
            child: Text('preference.theme_dialog_confirm'.tr()),
          ),
        ],
      ),
    );
  }

  /// 显示FlexColorPicker颜色选择器
  Future<void> _showFlexColorPicker() async {
    Color selectedColor = _selectedPrimaryColor;
    final Color newColor = await showColorPickerDialog(
      context,
      selectedColor,
      title: Text(
        'preference.custom_color'.tr(),
        style: Theme.of(context).textTheme.titleLarge,
      ),
      width: 44,
      height: 44,
      spacing: 8,
      runSpacing: 8,
      borderRadius: 12,
      wheelDiameter: 220,
      enableOpacity: true,
      showColorCode: true,
      colorCodeHasColor: true,
      pickersEnabled: <ColorPickerType, bool>{
        ColorPickerType.wheel: true,
        ColorPickerType.primary: true,
        ColorPickerType.accent: true,
        ColorPickerType.bw: false,
        ColorPickerType.custom: true,
      },
      copyPasteBehavior: const ColorPickerCopyPasteBehavior(
        copyButton: true,
        pasteButton: true,
        longPressMenu: true,
        editFieldCopyButton: true,
      ),
      actionButtons: ColorPickerActionButtons(
        okButton: true,
        closeButton: true,
        dialogActionButtons: false,
      ),
      constraints: const BoxConstraints(
        minHeight: 520,
        maxHeight: 640,
        minWidth: 360,
        maxWidth: 480,
      ),
      showRecentColors: true,
      customColorSwatchesAndNames: _customSwatches,
    );
    setState(() {
      _selectedPrimaryColor = newColor;
      _updatePrimaryColor(newColor);
    });
  }

  /// 更新主题颜色
  Future<void> _updatePrimaryColor(Color color) async {
    var appSetting = MyApp.userSettingNotifier.value;
    var newSetting = appSetting.copyWith(colorSeed: color.value);
    MyApp.userSettingNotifier.value = newSetting;
    await HiveUtil.setUserSetting(newSetting);
    await WebDAV.syncUserSetting(newSetting);
  }

  List<Widget> _buildThemeModeTile() {
    return [
      ListTile(
        leading: const Icon(Icons.palette),
        title: Text('preference.theme_mode'.tr()),
        subtitle: Text(_getThemeModeText()),
        onTap: () => _showThemeModeDialog(),
      ),
      if (Platform.isAndroid || Platform.isIOS)
        ValueListenableBuilder(
          valueListenable: MyApp.userSettingNotifier,
          builder: (context, setting, child) {
            return SwitchListTile(
              secondary: Icon(Icons.colorize_rounded),
              value: setting.useSystemColor,
              title: Text('preference.use_system_color'.tr()),
              subtitle: Text('preference.use_system_color_description'.tr()),
              onChanged: (v) {
                setting = setting.copyWith(useSystemColor: v);
                MyApp.userSettingNotifier.value = setting;
                HiveUtil.setUserSetting(setting);
              },
            );
          },
        ),
      // ListTile(
      //   leading: const Icon(Icons.image_outlined),
      //   title: Text('图片选择'),
      //   subtitle: Text('选择图片作为App的背景'),
      //   onTap: () => _showImagePicker(),
      // ),
    ];
  }

  ///颜色主题选择器，包括取色盘
  List<Widget> _buildPrimaryColorTile() {
    return [
      // 预设颜色网格
      Padding(
        padding: .symmetric(horizontal: 12),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline,
                        width: 1,
                      ),
                    ),
                  ),
                  title: Text('preference.custom_color'.tr()),
                  subtitle: Text(
                    '#${Theme.of(context).colorScheme.primary.value.toRadixString(16)}',
                  ),
                  trailing: Icon(
                    Icons.colorize,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  onTap: _showFlexColorPicker,
                ),
                Text(
                  'preference.preset_colors'.tr(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 1,
                  ),
                  itemCount: _presetColors.length,
                  itemBuilder: (context, index) {
                    final color = _presetColors[index];
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedPrimaryColor = color;
                          _updatePrimaryColor(color);
                        });
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child:
                              _selectedPrimaryColor.value32bit ==
                                  color.value32bit
                              ? Icon(
                                  Icons.check,
                                  color: color.computeLuminance() > 0.5
                                      ? Colors.black
                                      : Colors.white,
                                  size: 20,
                                )
                              : null,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    ];
  }

  //自动更新,资源匹配选项
  Widget _buildOptionTile() {
    return ValueListenableBuilder(
      valueListenable: MyApp.userSettingNotifier,
      builder: (context, value, child) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              value: value.useLastSource,
              title: Text('preference.match_strategy'.tr()),
              subtitle: Text('preference.match_strategy_description'.tr()),
              secondary: Icon(Icons.route_rounded),
              onChanged: (value) {
                var newSetting = MyApp.userSettingNotifier.value.copyWith(
                  useLastSource: value,
                );
                MyApp.userSettingNotifier.value = newSetting;
                HiveUtil.setUserSetting(newSetting);
              },
            ),
            SwitchListTile(
              value: value.enableSplash,
              title: Text('preference.enable_splash'.tr()),
              subtitle: Text('preference.enable_splash_description'.tr()),
              secondary: Icon(Icons.launch_rounded),
              onChanged: (value) {
                var newSetting = MyApp.userSettingNotifier.value.copyWith(
                  enableSplash: value,
                );
                MyApp.userSettingNotifier.value = newSetting;
                HiveUtil.setUserSetting(newSetting);
              },
            ),
            if (value.email.isNotEmpty)
              ListTile(
                title: Text('preference.data_sync_interval'.tr()),
                subtitle: Text(
                  'preference.data_sync_interval_description'.tr(),
                ),
                leading: Icon(Icons.timer_outlined),
                onTap: () {
                  _showDataSyncIntervalDialog(value.dataSyncInterval).then((
                    interval,
                  ) {
                    if (interval != null) {
                      MyApp.userSettingNotifier.value = value.copyWith(
                        dataSyncInterval: interval,
                      );
                      HiveUtil.setUserSetting(MyApp.userSettingNotifier.value);
                    }
                  });
                },
                trailing: Text(
                  '${value.dataSyncInterval.toString()}s',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),

            SwitchListTile(
              value: value.autoUpdate,
              title: Text('preference.auto_check_update'.tr()),
              secondary: Icon(Icons.update_rounded),
              onChanged: (value) {
                var newSetting = MyApp.userSettingNotifier.value.copyWith(
                  autoUpdate: value,
                );
                MyApp.userSettingNotifier.value = newSetting;
                HiveUtil.setUserSetting(newSetting);
              },
            ),
          ],
        );
      },
    );
  }

  Future<int?> _showDataSyncIntervalDialog(int initialValue) {
    var value = initialValue.toDouble();
    return showDialog<int?>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('preference.data_sync_interval'.tr()),
          content: StatefulBuilder(
            builder: (context, setState) {
              return SizedBox(
                height: 40,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${value.toInt()}s'),
                    SizedBox(width: 10),
                    SizedBox(
                      width: 150,
                      child: Slider(
                        value: value,
                        min: 1,
                        max: 60,
                        onChanged: (v) {
                          setState(() {
                            value = v;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            OutlinedButton(
              onPressed: () {
                Navigator.pop(context, null);
              },
              child: Text('common.dialog.cancel'.tr()),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context, value.toInt());
              },
              child: Text('common.dialog.confirm'.tr()),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    WebDAV.syncUserSetting(MyApp.userSettingNotifier.value);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            ..._buildThemeModeTile(),
            _buildOptionTile(),
            ..._buildPrimaryColorTile(),
          ],
        ),
      ),
    );
  }
}
