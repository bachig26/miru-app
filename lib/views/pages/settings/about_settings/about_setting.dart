import 'package:flutter/material.dart';
import 'package:miru_app/views/pages/settings/about_settings/check_update_tile.dart';
import 'package:miru_app/views/pages/settings/about_settings/show_info_tile.dart';

class AboutSettingPage extends StatelessWidget {
  const AboutSettingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        CheckUpdateTile(),
        SizedBox(height: 10),
        ShowInfoTile(),
      ],
    );
  }
}
