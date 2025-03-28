import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:miru_app/controllers/extension/extension_repo_controller.dart';
import 'package:miru_app/utils/i18n.dart';
import 'package:miru_app/utils/miru_storage.dart';
import 'package:miru_app/views/widgets/settings/settings_expander_tile.dart';
import 'package:miru_app/views/widgets/settings/settings_input_tile.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;

class ExtensionsSettingPage extends StatefulWidget {
  const ExtensionsSettingPage({super.key});

  @override
  State<ExtensionsSettingPage> createState() => _ExtensionsSettingPageState();
}

class _ExtensionsSettingPageState extends State<ExtensionsSettingPage> {
  @override
  Widget build(BuildContext context) {
    // 扩展仓库
    return SettingsExpanderTile(
      icon: fluent.FluentIcons.repo,
      androidIcon: Icons.extension,
      title: 'settings.extension'.i18n,
      subTitle: 'settings.extension-subtitle'.i18n,
      content: Column(
        children: [
          SettingsIntpuTile(
            title: 'settings.repo-url'.i18n,
            buildSubtitle: () {
              if (!Platform.isAndroid) {
                return 'settings.repo-url-subtitle'.i18n;
              }
              return MiruStorage.getSetting(SettingKey.miruRepoUrl);
            },
            onChanged: (value) {
              MiruStorage.setSetting(SettingKey.miruRepoUrl, value);
              Get.find<ExtensionRepoPageController>().onRefresh();
            },
            buildText: () {
              return MiruStorage.getSetting(SettingKey.miruRepoUrl);
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
