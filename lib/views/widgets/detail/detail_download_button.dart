import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:miru_app/controllers/detail_controller.dart';
import 'package:miru_app/router/router.dart';
import 'package:miru_app/utils/i18n.dart';
import 'package:miru_app/views/dialogs/download_picker_dialog.dart';
import 'package:miru_app/views/widgets/platform_widget.dart';

class DetailDownloadButton extends StatefulWidget {
  const DetailDownloadButton({
    super.key,
    this.tag,
  });

  final String? tag;

  @override
  State<DetailDownloadButton> createState() => _DetailDownloadButtonState();
}

class _DetailDownloadButtonState extends State<DetailDownloadButton> {
  late DetailPageController c = Get.find<DetailPageController>(tag: widget.tag);
  late var isSelected = c.isSelected;

  Widget _buildAndroid(BuildContext context) {
    return Obx(() {
      final isDownloadSelectorState = c.isDownloadSelectorState.value;
      if (!isDownloadSelectorState) {
        return IconButton(
          onPressed: () {
            c.changeDownloadSelectorState();
          },
          icon: const Icon(fluent.FluentIcons.download),
        );
      } else {
        return IconButton(
          onPressed: () async {
            c.changeDownloadSelectorState();
            // if (await requestBasicStoragePermissions()) {
              final toDownload = <int>[];
              for (var i = 0;
                  i < isSelected[c.selectEpGroup.value].length;
                  i++) {
                if (isSelected[c.selectEpGroup.value][i]) {
                  toDownload.add(i);
                  isSelected[c.selectEpGroup.value][i] = false;
                }
              }
              c.download(toDownload);
            // }
          },
          icon: const Icon(fluent.FluentIcons.check_mark),
        );
      }
    });
  }

  Widget _buildDesktop(BuildContext context) {
    return fluent.FilledButton(
      onPressed: () {
        fluent.showDialog(
            context: currentContext,
            builder: (context) => DownloadPickerDialog(tag: widget.tag));
      },
      child: Row(
        children: [
          const Icon(fluent.FluentIcons.download),
          const SizedBox(width: 10),
          Text('detail.download'.i18n),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PlatformBuildWidget(
      androidBuilder: _buildAndroid,
      desktopBuilder: _buildDesktop,
    );
  }
}
