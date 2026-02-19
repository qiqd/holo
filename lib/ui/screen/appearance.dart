import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:holo/entity/app_setting.dart';
import 'package:holo/main.dart';
import 'package:holo/util/local_store.dart';
import 'package:image_picker/image_picker.dart';

class Appearance extends StatefulWidget {
  const Appearance({super.key});

  @override
  State<Appearance> createState() => _AppearanceState();
}

class _AppearanceState extends State<Appearance> {
  // 主题颜色相关状态
  Color _selectedPrimaryColor = Color(MyApp.appSettingNotifier.value.colorSeed);

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
    final themeMode = MyApp.appSettingNotifier.value.themeMode;
    switch (themeMode) {
      case 0:
        return 'appearance.theme_mode_system'.tr();

      case 1:
        return 'appearance.theme_mode_light'.tr();
      case 2:
        return 'appearance.theme_mode_dark'.tr();
      default:
        return 'appearance.theme_mode_system'.tr();
    }
  }

  void _showThemeModeDialog() {
    AppSetting appSetting = MyApp.appSettingNotifier.value;
    ThemeMode? currentTheme = ThemeMode.values[appSetting.themeMode];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('appearance.theme_dialog_title'.tr()),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<ThemeMode>(
                  title: Text('appearance.theme_mode_system'.tr()),
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
                  title: Text('appearance.theme_mode_light'.tr()),
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
                  title: Text('appearance.theme_mode_dark'.tr()),
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
            child: Text('appearance.theme_dialog_cancel'.tr()),
          ),
          FilledButton(
            onPressed: () {
              MyApp.appSettingNotifier.value = appSetting.copyWith(
                themeMode: currentTheme?.index,
              );
              LocalStore.saveAppSetting(MyApp.appSettingNotifier.value);
              Navigator.pop(context);
            },
            child: Text('appearance.theme_dialog_confirm'.tr()),
          ),
        ],
      ),
    );
  }

  /// 显示FlexColorPicker颜色选择器
  void _showFlexColorPicker() async {
    Color selectedColor = _selectedPrimaryColor;
    final Color newColor = await showColorPickerDialog(
      context,
      selectedColor,
      title: Text(
        'appearance.custom_color'.tr(),
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
  void _updatePrimaryColor(Color color) {
    var appSetting = MyApp.appSettingNotifier.value;
    MyApp.appSettingNotifier.value = appSetting.copyWith(
      colorSeed: color.value,
    );
    LocalStore.saveAppSetting(MyApp.appSettingNotifier.value);
  }

  /// 显示图片选择器
  Future<void> _showImagePicker() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {}
  }

  List<Widget> _buildThemeModeTile() {
    var appSetting = MyApp.appSettingNotifier.value;
    return [
      ListTile(
        leading: const Icon(Icons.palette),
        title: Text('appearance.theme_mode'.tr()),
        subtitle: Text(_getThemeModeText()),
        onTap: () => _showThemeModeDialog(),
      ),
      if (Platform.isAndroid || Platform.isIOS)
        SwitchListTile(
          secondary: Icon(Icons.colorize_rounded),
          value: MyApp.appSettingNotifier.value.useSystemColor,
          title: Text('appearance.use_system_color'.tr()),
          subtitle: Text('appearance.use_system_color_description'.tr()),
          onChanged: (v) => setState(() {
            MyApp.appSettingNotifier.value = appSetting.copyWith(
              useSystemColor: v,
            );
            LocalStore.saveAppSetting(MyApp.appSettingNotifier.value);
          }),
        ),
      ListTile(
        leading: const Icon(Icons.image_outlined),
        title: Text('图片选择'),
        subtitle: Text('选择图片作为App的背景'),
        onTap: () => _showImagePicker(),
      ),
    ];
  }

  ///颜色主题选择器，包括取色盘
  List<Widget> _buildPrimaryColorTile() {
    var color = Theme.of(context).colorScheme.primary;

    return [
      // 预设颜色网格
      Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
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
                title: Text('appearance.custom_color'.tr()),
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
                'appearance.preset_colors'.tr(),
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
                            _selectedPrimaryColor.value32bit == color.value32bit
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
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('appearance.appbar_title'.tr()),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        children: [..._buildThemeModeTile(), ..._buildPrimaryColorTile()],
      ),
    );
  }
}
