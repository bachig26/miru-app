import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:miru_app/controllers/settings_controller.dart';
import 'package:miru_app/views/pages/settings/about_settings/check_update_tile.dart';
import 'package:miru_app/views/pages/settings/about_settings/show_info_tile.dart';
import 'package:miru_app/views/pages/settings/advanced_settings/debug_setting.dart';
import 'package:miru_app/views/pages/settings/advanced_settings/network_setting.dart';
import 'package:miru_app/views/pages/settings/basic_settings/comic_reader_setting.dart';
import 'package:miru_app/views/pages/settings/basic_settings/download_setting.dart';
import 'package:miru_app/views/pages/settings/basic_settings/extensions_setting.dart';
import 'package:miru_app/views/pages/settings/basic_settings/general_setting.dart';
import 'package:miru_app/views/pages/settings/basic_settings/tracking_setting.dart';
import 'package:miru_app/views/pages/settings/basic_settings/video_player_setting.dart';
import 'package:miru_app/views/widgets/settings/android_setting_list.dart';
import 'package:miru_app/views/widgets/settings/settings_switch_tile.dart';
import 'package:miru_app/utils/i18n.dart';
import 'package:miru_app/views/widgets/list_title.dart';
import 'package:miru_app/views/widgets/platform_widget.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late SettingsController c;

  @override
  void initState() {
    c = Get.put(SettingsController());
    super.initState();
  }

  List<Widget> _buildContent() {
    return [
      if (!Platform.isAndroid) ...[
        Text(
          'common.settings'.i18n,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
      ],
      const GenearlSettingPage(),
      const SizedBox(height: 10),

      const ExtensionsSettingPage(),
      const SizedBox(height: 10),

      const VideoPlayerSettingPage(),
      const SizedBox(height: 10),

      const ComicReaderSettingPage(),
      const SizedBox(height: 10),

      const TrackingSettingPage(),
      const SizedBox(height: 10),

      const DownloadSettingPage(),
      const SizedBox(height: 20),
      // 高级
      ListTitle(title: 'settings.advanced'.i18n),
      const SizedBox(height: 20),

      const NetworkSettingPage(),
      const SizedBox(height: 10),

      const DebugSettingPage(),
      if (!Platform.isAndroid) ...[
        const SizedBox(height: 10),
        Obx(
          () {
            final value = c.extensionLogWindowId.value != -1;
            return SettingsSwitchTile(
              icon: const Icon(
                fluent.FluentIcons.bug,
                size: 24,
              ),
              title: 'settings.extension-log'.i18n,
              buildSubtitle: () => 'settings.extension-log-subtitle'.i18n,
              buildValue: () => value,
              onChanged: (value) {
                c.toggleExtensionLogWindow(value);
              },
              isCard: true,
            );
          },
        )
      ],
      // 关于
      const SizedBox(height: 20),
      ListTitle(title: 'settings.about'.i18n),
      const SizedBox(height: 20),

      const CheckUpdateTile(),
      const SizedBox(height: 10),
      const ShowInfoTile(),
    ];
  }

  Widget _buildAndroidContent(BuildContext context) {
    return Column(children: [
      AndroidSettingList(
          icon: const Icon(Icons.settings),
          mainTitle: 'Basic',
          children: [
            const GenearlSettingPage(),
            const ExtensionsSettingPage(),
            const VideoPlayerSettingPage(),
            const ComicReaderSettingPage(),
            const TrackingSettingPage(),
            const DownloadSettingPage(),
          ]),
      const SizedBox(height: 20),
      AndroidSettingList(
          icon: const Icon(Icons.code),
          mainTitle: 'Advanced',
          children: [
            const NetworkSettingPage(),
            const DebugSettingPage(),
          ]),
      const SizedBox(height: 20),
      AndroidSettingList(
          icon: const Icon(Icons.info),
          mainTitle: 'About',
          children: [
            const CheckUpdateTile(),
            const ShowInfoTile(),
          ]),
    ]);
  }

  Widget _buildAndroid(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('common.settings'.i18n),
      ),
      body: SingleChildScrollView(child: _buildAndroidContent(context)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PlatformBuildWidget(
      androidBuilder: _buildAndroid,
      desktopBuilder: (context) => ListView(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
        children: _buildContent(),
      ),
    );
  }
}
