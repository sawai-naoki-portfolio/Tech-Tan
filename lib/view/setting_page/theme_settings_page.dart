import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../provider/theme_provider.dart';
import '../../provider/use_material3_provider.dart';

class ThemeSettingsPage extends ConsumerWidget {
  const ThemeSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(themeProvider);
    // Material3 の状態は新しいプロバイダーから読み込む
    final useMaterial3 = ref.watch(useMaterial3Provider);

    return Scaffold(
      appBar: AppBar(title: const Text("テーマの変更")),
      body: ListView(
        children: [
          RadioGroup<ThemeMode>(
            groupValue: currentTheme,
            onChanged: (ThemeMode? value) {
              if (value != null) {
                ref.read(themeProvider.notifier).setTheme(value);
              }
            },
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<ThemeMode>(
                  title: Text("システム"),
                  value: ThemeMode.system,
                ),
                RadioListTile<ThemeMode>(
                  title: Text("ライト"),
                  value: ThemeMode.light,
                ),
                RadioListTile<ThemeMode>(
                  title: Text("ダーク"),
                  value: ThemeMode.dark,
                ),
              ],
            ),
          ),
          const Divider(),
          // Material 3 のON/OFFスイッチ
          SwitchListTile(
            title: const Text("Material 3 の利用"),
            value: useMaterial3,
            onChanged: (value) {
              ref.read(useMaterial3Provider.notifier).setMaterial3(value);
            },
          ),
        ],
      ),
    );
  }
}
