import 'dart:io';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';
import 'package:miru_app/utils/i18n.dart';
import 'package:miru_app/utils/miru_storage.dart';
import 'package:miru_app/utils/request.dart';
import 'package:miru_app/views/widgets/settings/settings_expander_tile.dart';
import 'package:miru_app/views/widgets/settings/settings_input_tile.dart';
import 'package:miru_app/views/widgets/settings/settings_radios_tile.dart';

class NetworkSettingPage extends StatelessWidget {
  const NetworkSettingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsExpanderTile(
      content: Column(
        children: [
          SettingsIntpuTile(
            title: 'settings.network-ua'.i18n,
            buildSubtitle: () {
              if (!Platform.isAndroid) {
                return 'settings.network-ua-subtitle'.i18n;
              }
              return MiruStorage.getUASetting();
            },
            onChanged: (value) {
              MiruStorage.setUASetting(value);
            },
            buildText: () {
              return MiruStorage.getUASetting();
            },
          ),
          SettingsRadiosTile(
            title: 'settings.proxy-type'.i18n,
            itemNameValue: {
              'settings.proxy-type-direct'.i18n: 'DIRECT',
              'settings.proxy-type-socks5'.i18n: 'SOCKS5',
              'settings.proxy-type-socks4'.i18n: 'SOCKS4',
              'settings.proxy-type-http'.i18n: 'PROXY',
            },
            buildSubtitle: () => 'settings.proxy-type-subtitle'.i18n,
            applyValue: (value) {
              MiruStorage.setSetting(SettingKey.proxyType, value);
              MiruRequest.refreshProxy();
            },
            buildGroupValue: () {
              return MiruStorage.getSetting(SettingKey.proxyType);
            },
          ),
          const SizedBox(height: 10),
          SettingsIntpuTile(
            title: 'settings.proxy'.i18n,
            buildSubtitle: () => 'settings.proxy-subtitle'.i18n,
            onChanged: (value) {
              MiruStorage.setSetting(SettingKey.proxy, value);
              MiruRequest.refreshProxy();
            },
            buildText: () {
              return MiruStorage.getSetting(SettingKey.proxy);
            },
          ),
        ],
      ),
      title: "settings.network".i18n,
      subTitle: "settings.network-subtitle".i18n,
      icon: fluent.FluentIcons.globe,
      androidIcon: Icons.network_wifi,
    );
  }
}
