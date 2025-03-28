import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';
import 'package:miru_app/utils/i18n.dart';
import 'package:miru_app/utils/log.dart';
import 'package:miru_app/utils/miru_storage.dart';
import 'package:miru_app/views/widgets/platform_widget.dart';
import 'package:miru_app/views/widgets/settings/settings_expander_tile.dart';
import 'package:miru_app/views/widgets/settings/settings_switch_tile.dart';
import 'package:miru_app/views/widgets/settings/settings_tile.dart';
import 'package:share_plus/share_plus.dart';

class DebugSettingPage extends StatelessWidget {
  const DebugSettingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SettingsExpanderTile(
          title: "settings.log".i18n,
          subTitle: 'settings.log-subtitle'.i18n,
          androidIcon: Icons.report,
          icon: fluent.FluentIcons.report_alert,
          content: Column(
            children: [
              SettingsSwitchTile(
                title: 'settings.save-log'.i18n,
                buildSubtitle: () => 'settings.save-log-subtitle'.i18n,
                buildValue: () {
                  return MiruStorage.getSetting(SettingKey.saveLog);
                },
                onChanged: (value) {
                  MiruStorage.setSetting(SettingKey.saveLog, value);
                },
              ),
              const SizedBox(height: 10),
              SettingsTile(
                title: 'settings.export-log'.i18n,
                buildSubtitle: () => 'settings.export-log-subtitle'.i18n,
                trailing: PlatformWidget(
                  androidWidget: TextButton(
                    onPressed: () {
                      Share.shareXFiles([XFile(MiruLog.logFilePath)]);
                    },
                    child: Text('common.export'.i18n),
                  ),
                  desktopWidget: fluent.FilledButton(
                    onPressed: () async {
                      final path = await FilePicker.platform.saveFile(
                        type: FileType.custom,
                        allowedExtensions: ['log'],
                        fileName: 'miru.log',
                      );
                      if (path != null) {
                        File(MiruLog.logFilePath).copy(path);
                      }
                    },
                    child: Text('common.export'.i18n),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
