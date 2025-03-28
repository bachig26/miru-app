import 'dart:io';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:miru_app/animations/navigation_animation.dart';
import 'package:miru_app/router/router.dart';
import 'package:miru_app/utils/i18n.dart';
import 'package:miru_app/utils/miru_storage.dart';
import 'package:miru_app/views/pages/tracking/anilist_tracking_page.dart';
import 'package:miru_app/views/widgets/settings/settings_expander_tile.dart';
import 'package:miru_app/views/widgets/settings/settings_switch_tile.dart';
import 'package:miru_app/views/widgets/settings/settings_tile.dart';

class TrackingSettingPage extends StatelessWidget {
  const TrackingSettingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsExpanderTile(
      icon: fluent.FluentIcons.sync,
      androidIcon: Icons.sync,
      content: Column(
        children: [
          SettingsSwitchTile(
            title: 'settings.auto-tracking'.i18n,
            buildSubtitle: () => 'settings.auto-tracking-subtitle'.i18n,
            buildValue: () {
              return MiruStorage.getSetting(SettingKey.autoTracking);
            },
            onChanged: (value) {
              MiruStorage.setSetting(SettingKey.autoTracking, value);
            },
          ),
          const SizedBox(height: 10),
          SettingsTile(
            isCard: false,
            icon: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                image: const DecorationImage(
                  image: AssetImage('assets/icon/anilist.jpg'),
                ),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            title: 'Anilist',
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              if (!Platform.isAndroid) {
                router.push('/settings/anilist');
              } else {
                NavigationAnimation.roundedGetTo(
                  page: const AniListTrackingPage(),
                  transition: Transition.rightToLeft,
                );
              }
            },
          ),
        ],
      ),
      title: 'settings.tracking'.i18n,
      subTitle: 'settings.tracking-subtitle'.i18n,
    );
  }
}
