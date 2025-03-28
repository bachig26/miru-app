import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';
import 'package:miru_app/utils/i18n.dart';
import 'package:miru_app/utils/miru_storage.dart';
import 'package:miru_app/views/widgets/settings/settings_expander_tile.dart';
import 'package:miru_app/views/widgets/settings/settings_radios_tile.dart';

class ComicReaderSettingPage extends StatelessWidget {
  const ComicReaderSettingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsExpanderTile(
      icon: fluent.FluentIcons.reading_mode,
      androidIcon: Icons.image,
      title: 'settings.comic-reader'.i18n,
      subTitle: 'settings.comic-reader-subtitle'.i18n,
      content: Column(
        children: [
          SettingsRadiosTile(
            title: 'settings.default-reader-mode'.i18n,
            itemNameValue: () {
              final map = {
                'comic-settings.standard'.i18n: 'standard',
                'comic-settings.right-to-left'.i18n: 'rightToLeft',
                'comic-settings.web-tonn'.i18n: 'webTonn',
              };
              return map;
            }(),
            buildSubtitle: () =>
                '${MiruStorage.getSetting(SettingKey.readingMode)}'.i18n,
            applyValue: (value) {
              MiruStorage.setSetting(SettingKey.readingMode, value);
            },
            buildGroupValue: () {
              return MiruStorage.getSetting(SettingKey.readingMode);
            },
          ),
        ],
      ),
    );
  }
}
