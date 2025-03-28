import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:miru_app/controllers/application_controller.dart';
import 'package:miru_app/data/providers/tmdb_provider.dart';
import 'package:miru_app/utils/android_permission.dart';
import 'package:miru_app/utils/i18n.dart';
import 'package:miru_app/utils/miru_storage.dart';
import 'package:miru_app/views/widgets/settings/settings_expander_tile.dart';
import 'package:miru_app/views/widgets/settings/settings_input_tile.dart';
import 'package:miru_app/views/widgets/settings/settings_radios_tile.dart';
import 'package:miru_app/views/widgets/settings/settings_switch_tile.dart';
import 'package:miru_app/views/widgets/settings/settings_tile.dart';
import 'package:tmdb_api/tmdb_api.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;

class GenearlSettingPage extends StatefulWidget {
  const GenearlSettingPage({super.key});

  @override
  State<GenearlSettingPage> createState() => _GenearlSettingPageState();
}

class _GenearlSettingPageState extends State<GenearlSettingPage> {
  @override
  Widget build(BuildContext context) {
    // 常规设置
    return SettingsExpanderTile(
      icon: fluent.FluentIcons.developer_tools,
      androidIcon: Icons.construction,
      title: 'settings.general'.i18n,
      subTitle: 'settings.general-subtitle'.i18n,
      content: Column(
        children: [
          if (Platform.isAndroid) ...[
            SettingsTile(
              title: 'settings.file-access-permission'.i18n,
              onTap: () => openFullStorageSettings(),
              trailing: const Icon(Icons.chevron_right),
            )
          ],
          // TMDB KEY 设置
          SettingsIntpuTile(
            title: 'settings.tmdb-key'.i18n,
            buildSubtitle: () {
              if (!Platform.isAndroid) {
                return 'settings.tmdb-key-subtitle'.i18n;
              }
              final key = MiruStorage.getSetting(SettingKey.tmdbKey) as String;
              if (key.isEmpty) {
                return 'common.unset'.i18n;
              }
              // 替换为*号
              return key.replaceAll(RegExp(r"."), '*');
            },
            onChanged: (value) {
              MiruStorage.setSetting(SettingKey.tmdbKey, value);
              TmdbApi.tmdb = TMDB(
                ApiKeys(value, ''),
                defaultLanguage: MiruStorage.getSetting(SettingKey.language),
              );
            },
            buildText: () {
              return MiruStorage.getSetting(SettingKey.tmdbKey);
            },
          ),
          // 语言设置
          SettingsRadiosTile(
            title: 'settings.language'.i18n,
            itemNameValue: {
              'languages.be'.i18n: 'be',
              'languages.en'.i18n: 'en',
              'languages.es'.i18n: 'es',
              'languages.fr'.i18n: 'fr',
              'languages.hu'.i18n: 'hu',
              'languages.hi'.i18n: 'hi',
              'languages.id'.i18n: 'id',
              'languages.ja'.i18n: 'ja',
              'languages.pl'.i18n: 'pl',
              'languages.ru'.i18n: 'ru',
              'languages.ryu'.i18n: 'ryu',
              'languages.uk'.i18n: 'uk',
              'languages.zh'.i18n: 'zh',
              'languages.zhHant'.i18n: 'zhHant',
            },
            buildSubtitle: () => 'settings.language-subtitle'.i18n,
            applyValue: (value) {
              MiruStorage.setSetting(SettingKey.language, value);
              I18nUtils.changeLanguage(value);
            },
            buildGroupValue: () {
              return MiruStorage.getSetting(SettingKey.language);
            },
          ),
          // 主题设置
          SettingsRadiosTile(
            title: 'settings.theme'.i18n,
            itemNameValue: () {
              final map = {
                'settings.theme-system'.i18n: 'system',
                'settings.theme-light'.i18n: 'light',
                'settings.theme-dark'.i18n: 'dark',
              };
              if (Platform.isAndroid) {
                map['settings.theme-black'.i18n] = 'black';
              }
              return map;
            }(),
            buildSubtitle: () => 'settings.theme-subtitle'.i18n,
            applyValue: (value) {
              Get.find<ApplicationController>().changeTheme(value);
            },
            buildGroupValue: () {
              return Get.find<ApplicationController>().themeText.value;
            },
          ),
          // 启动检查更新
          SettingsSwitchTile(
            title: 'settings.auto-check-update'.i18n,
            buildSubtitle: () => 'settings.auto-check-update-subtitle'.i18n,
            buildValue: () =>
                MiruStorage.getSetting(SettingKey.autoCheckUpdate),
            onChanged: (value) {
              MiruStorage.setSetting(SettingKey.autoCheckUpdate, value);
            },
          ),
          // NSFW
          SettingsSwitchTile(
            title: 'settings.nsfw'.i18n,
            buildSubtitle: () => "settings.nsfw-subtitle".i18n,
            buildValue: () {
              return MiruStorage.getSetting(SettingKey.enableNSFW);
            },
            onChanged: (value) {
              MiruStorage.setSetting(SettingKey.enableNSFW, value);
            },
          ),
        ],
      ),
    );
  }
}
