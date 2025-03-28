import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:miru_app/animations/navigation_animation.dart';
import 'package:miru_app/router/router.dart';
import 'package:miru_app/data/services/database_service.dart';
import 'package:miru_app/data/services/download/download_manager.dart';
import 'package:miru_app/utils/i18n.dart';
import 'package:miru_app/utils/log.dart';
import 'package:miru_app/utils/miru_storage.dart';
import 'package:miru_app/utils/path_utils.dart';
import 'package:miru_app/views/pages/download_manager_page.dart';
import 'package:miru_app/views/widgets/platform_widget.dart';
import 'package:miru_app/views/widgets/settings/settings_expander_tile.dart';
import 'package:miru_app/views/widgets/settings/settings_radios_tile.dart';
import 'package:miru_app/views/widgets/settings/settings_tile.dart';

class DownloadSettingPage extends StatefulWidget {
  const DownloadSettingPage({super.key});

  @override
  State<DownloadSettingPage> createState() => _DownloadSettingPageState();
}

class _DownloadSettingPageState extends State<DownloadSettingPage> {
  String downloadPath = MiruStorage.getSetting(SettingKey.downloadPath);
  final downloadPathController = TextEditingController(
      text: MiruStorage.getSetting(SettingKey.downloadPath));

  Future<void> _updateDownloadPath(String treePath) async {
    final newPath = await miruCreateFolderInTree(treePath, ['Miru']);
    if (newPath == null) {
      logger.warning('SettingsPage: Failed to create Miru folder in $treePath');
      return;
    }
    if (newPath == downloadPath) {
      return;
    }
    setState(() {
      downloadPath = newPath;
    });
    MiruStorage.setSetting(SettingKey.downloadPath, newPath);
    downloadPathController.text = await miruGetActualPath(newPath) ?? newPath;
    if (Platform.isAndroid) {
      await miruCreateEmptyFile(newPath, '.nomedia');
    }
    // 更新一下内部的数据库
    DownloadManager().cancelAll();
    DatabaseService.clearAllMiruDetailOfflineResourceJson();
  }

  @override
  Widget build(BuildContext context) {
    return SettingsExpanderTile(
      icon: fluent.FluentIcons.download,
      androidIcon: Icons.download,
      content: Column(
        children: [
          SettingsTile(
            title: 'settings.download-path'.i18n,
            buildSubtitle: () => 'settings.download-path-subtitle'.i18n,
            trailing: PlatformWidget(
              androidWidget: TextButton(
                onPressed: () async {
                  var path = await miruPickDir();
                  if (path != null) {
                    await _updateDownloadPath(path);
                  }
                },
                child: Text('settings.download-path-select'.i18n),
              ),
              desktopWidget: fluent.Row(
                children: [
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.5,
                    child: fluent.TextBox(
                      placeholder: downloadPath,
                      readOnly: true,
                      scrollPhysics: const BouncingScrollPhysics(),
                      controller: downloadPathController,
                    ),
                  ),
                  const SizedBox(width: 10),
                  fluent.FilledButton(
                    onPressed: () async {
                      var path = await FilePicker.platform.getDirectoryPath();
                      if (path != null) {
                        _updateDownloadPath(path);
                      }
                    },
                    child: Text('settings.download-path-select'.i18n),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          SettingsRadiosTile(
            title: 'settings.download-max-task'.i18n,
            buildSubtitle: () => 'settings.download-max-task-subtitle'.i18n,
            itemNameValue: {
              '1': 1,
              '2': 2,
              '3': 3,
              '4': 4,
              '5': 5,
              '6': 6,
              '7': 7,
              '8': 8,
              '9': 9,
              '10': 10,
            },
            applyValue: (value) {
              MiruStorage.setSetting(SettingKey.downloadMaxTasks, value);
            },
            buildGroupValue: () {
              return MiruStorage.getSetting(SettingKey.downloadMaxTasks);
            },
          ),
          const SizedBox(height: 8),
          SettingsTile(
            isCard: false,
            title: 'settings.download-manager'.i18n,
            icon: !Platform.isAndroid
                ? const Icon(fluent.FluentIcons.hard_drive, size: 36)
                : null,
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              if (!Platform.isAndroid) {
                router.push('/settings/download/download_manager');
              } else {
                NavigationAnimation.roundedGetTo(
                  page: const DownloadManagerPage(),
                  transition: Transition.rightToLeft,
                );
              }
            },
          ),
        ],
      ),
      title: 'settings.download'.i18n,
      subTitle: 'settings.download-subtitle'.i18n,
    );
  }
}
