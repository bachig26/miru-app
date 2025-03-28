import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:miru_app/controllers/settings_controller.dart';
import 'package:miru_app/utils/i18n.dart';
import 'package:miru_app/views/widgets/settings/settings_expander_tile.dart';
import 'package:url_launcher/url_launcher.dart';

class ShowInfoTile extends StatelessWidget {
  const ShowInfoTile({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SettingsController>();

    return SettingsExpanderTile(
      leading: const Image(
        image: AssetImage('assets/icon/logo.png'),
        width: 24,
        height: 24,
      ),
      title: "Miru",
      subTitle: "AGPL-3.0 License",
      open: true,
      noPage: true,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SelectableText(
            "🎉 A versatile application that is free, open-source, and supports extension sources for videos, comics, and novels, available on Android, Windows, and Web platforms.",
          ),
          const SizedBox(height: 20),
          Text(
            'settings.links'.i18n,
          ),
          const SizedBox(height: 8),
          Wrap(
            children: [
              for (final link in controller.links.entries)
                fluent.Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () async {
                        await launchUrl(
                          Uri.parse(link.value),
                          mode: LaunchMode.externalApplication,
                        );
                      },
                      child: Text(
                        link.key,
                        style: const TextStyle(
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ),
                )
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'settings.contributors'.i18n,
          ),
          const SizedBox(height: 8),
          Obx(
            () => Wrap(
              children: [
                if (controller.contributors.isNotEmpty)
                  for (final contributor in controller.contributors)
                    fluent.Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () async {
                            await launchUrl(
                              Uri.parse(contributor['html_url']),
                              mode: LaunchMode.externalApplication,
                            );
                          },
                          child: Text(
                            contributor['login'],
                            style: const TextStyle(
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      ),
                    )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
