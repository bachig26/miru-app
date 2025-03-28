import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:miru_app/utils/application.dart';
import 'package:miru_app/utils/i18n.dart';
import 'package:miru_app/views/widgets/platform_widget.dart';
import 'package:miru_app/views/widgets/settings/settings_tile.dart';

class CheckUpdateTile extends StatelessWidget {
  const CheckUpdateTile({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsTile(
      isCard: true,
      icon: const PlatformWidget(
        androidWidget: Icon(Icons.update),
        desktopWidget: Icon(fluent.FluentIcons.update_restore, size: 24),
      ),
      title: 'settings.upgrade'.i18n,
      buildSubtitle: () => FlutterI18n.translate(
        context,
        'settings.upgrade-subtitle',
        translationParams: {
          'version': packageInfo.version,
        },
      ),
      trailing: PlatformWidget(
        androidWidget: TextButton(
          onPressed: () {
            ApplicationUtils.checkUpdate(
              context,
              showSnackbar: true,
            );
          },
          child: Text('settings.upgrade-training'.i18n),
        ),
        desktopWidget: fluent.FilledButton(
          onPressed: () {
            ApplicationUtils.checkUpdate(
              context,
              showSnackbar: true,
            );
          },
          child: Text('settings.upgrade-training'.i18n),
        ),
      ),
    );
  }
}
