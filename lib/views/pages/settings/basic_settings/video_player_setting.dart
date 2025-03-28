import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:miru_app/utils/i18n.dart';
import 'package:miru_app/utils/miru_storage.dart';
import 'package:miru_app/views/dialogs/bt_dialog.dart';
import 'package:miru_app/views/widgets/platform_widget.dart';
import 'package:miru_app/views/widgets/settings/settings_expander_tile.dart';
import 'package:miru_app/views/widgets/settings/settings_numberbox_button.dart';
import 'package:miru_app/views/widgets/settings/settings_radios_tile.dart';
import 'package:miru_app/views/widgets/settings/settings_tile.dart';

class VideoPlayerSettingPage extends StatefulWidget {
  const VideoPlayerSettingPage({super.key});

  @override
  State<VideoPlayerSettingPage> createState() => _VideoPlayerSettingPageState();
}

class _VideoPlayerSettingPageState extends State<VideoPlayerSettingPage> {
  @override
  Widget build(BuildContext context) {
    // 视频播放器
    return SettingsExpanderTile(
      icon: fluent.FluentIcons.play,
      androidIcon: Icons.play_arrow,
      title: 'settings.video-player'.i18n,
      subTitle: 'settings.video-player-subtitle'.i18n,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SettingsTile(
            title: 'settings.bt-server'.i18n,
            buildSubtitle: () => "settings.bt-server-subtitle".i18n,
            trailing: PlatformWidget(
              androidWidget: TextButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => const BTDialog(),
                  );
                },
                child: Text('settings.bt-server-manager'.i18n),
              ),
              desktopWidget: fluent.FilledButton(
                onPressed: () {
                  fluent.showDialog(
                    context: context,
                    builder: (context) => const BTDialog(),
                  );
                },
                child: Text('settings.bt-server-manager'.i18n),
              ),
            ),
          ),
          SettingsRadiosTile(
            title: 'settings.external-player'.i18n,
            itemNameValue: () {
              if (Platform.isAndroid) {
                return {
                  "settings.external-player-builtin".i18n: "built-in",
                  "VLC": "vlc",
                  "Other": "other",
                };
              }
              if (Platform.isLinux) {
                return {
                  "settings.external-player-builtin".i18n: "built-in",
                  "VLC": "vlc",
                  "mpv": "mpv",
                };
              }
              return {
                "settings.external-player-builtin".i18n: "built-in",
                "VLC": "vlc",
                "PotPlayer": "potplayer",
              };
            }(),
            buildSubtitle: () => FlutterI18n.translate(
              context,
              'settings.external-player-subtitle',
              translationParams: {
                'player': MiruStorage.getSetting(SettingKey.videoPlayer),
              },
            ),
            applyValue: (value) {
              MiruStorage.setSetting(SettingKey.videoPlayer, value);
            },
            buildGroupValue: () {
              return MiruStorage.getSetting(SettingKey.videoPlayer);
            },
          ),
          const SizedBox(height: 10),
          if (!Platform.isAndroid) ...[
            Text("settings.skip-interval".i18n),
            const SizedBox(height: 2),
            Text(
              "settings.skip-interval-subtitle".i18n,
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 15),
            Column(
              children: [
                Row(children: [
                  Expanded(
                      child: SettingNumboxButton(
                    title: "key I",
                    button1text: "1s",
                    button2text: "0.1s",
                    onChanged: (value) {
                      MiruStorage.setSetting(SettingKey.keyI, value ??= -10.0);
                    },
                    numberBoxvalue:
                        MiruStorage.getSetting(SettingKey.keyI) ?? -10.0,
                  )),
                  const SizedBox(width: 30),
                  Expanded(
                      child: SettingNumboxButton(
                    title: "key J",
                    button1text: "1s",
                    button2text: "0.1s",
                    onChanged: (value) {
                      MiruStorage.setSetting(SettingKey.keyJ, value ??= 10.0);
                    },
                    numberBoxvalue:
                        MiruStorage.getSetting(SettingKey.keyJ) ?? 10.0,
                  ))
                ]),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                        child: SettingNumboxButton(
                      title: "arrow left",
                      icon: const Icon(fluent.FluentIcons.chevron_left_med),
                      button1text: "1s",
                      button2text: "0.1s",
                      numberBoxvalue:
                          MiruStorage.getSetting(SettingKey.arrowLeft) ?? 10.0,
                      onChanged: (value) {
                        MiruStorage.setSetting(
                            SettingKey.arrowLeft, value ??= -2.0);
                      },
                    )),
                    const SizedBox(width: 30),
                    Expanded(
                        child: SettingNumboxButton(
                      title: "arrow right",
                      icon: const Icon(fluent.FluentIcons.chevron_right_med),
                      button1text: "1s",
                      button2text: "0.1s",
                      onChanged: (value) {
                        MiruStorage.setSetting(
                            SettingKey.arrowRight, value ??= 2);
                      },
                      numberBoxvalue:
                          MiruStorage.getSetting(SettingKey.arrowRight) ?? 10.0,
                    ))
                  ],
                )
              ],
            ),
          ]
        ],
      ),
    );
  }
}
