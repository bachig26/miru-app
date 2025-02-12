import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:miru_app/controllers/detail_controller.dart';
import 'package:miru_app/models/extension.dart';
import 'package:miru_app/utils/i18n.dart';
import 'package:miru_app/views/widgets/platform_widget.dart';

class DownloadPickerDialog extends StatefulWidget {
  const DownloadPickerDialog({
    super.key,
    required this.tag,
  });

  final String? tag;

  @override
  State<DownloadPickerDialog> createState() => _DownloadPickerDialogState();
}

class _DownloadPickerDialogState extends State<DownloadPickerDialog> {
  late DetailPageController c = Get.find<DetailPageController>(tag: widget.tag);
  List<fluent.ComboBoxItem<int>>? comboBoxItems;
  late List<ExtensionEpisodeGroup> episodes = [];
  late List<List<bool>> isSelected = c.isSelected;
  bool isSelectAll = false;

  Widget _buildDesktop(BuildContext context) {
    return Obx(() {
      final _ = c.aniListID.value;
      return fluent.ContentDialog(
          constraints: const BoxConstraints(maxWidth: 2600),
          content: fluent.LayoutBuilder(builder: (context, constraints) {
            double width = constraints.maxWidth;
            double height = constraints.maxHeight;
            return fluent.ConstrainedBox(
              constraints: BoxConstraints(
                  minWidth: width * 0.5,
                  minHeight: height * 0.8,
                  maxWidth: width * 0.8,
                  maxHeight: height * 0.9),
              child: fluent.Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  fluent.Padding(
                      padding:
                          const EdgeInsets.only(left: 16, right: 16, top: 16)),
                  fluent.Row(
                    children: [
                      fluent.IconButton(
                        icon: const Icon(fluent.FluentIcons.back),
                        onPressed: () {
                          context.pop();
                        },
                      ),
                      const SizedBox(width: 8),
                      fluent.Text(
                        'detail.download'.i18n,
                        style:
                            fluent.FluentTheme.of(context).typography.subtitle,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  fluent.Expanded(
                    // 使用 Expanded 包裹 GridView.builder
                    child: fluent.GridView.builder(
                      gridDelegate:
                          fluent.SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: width ~/ 230,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: 4,
                      ),
                      itemCount: episodes.isEmpty
                          ? 0
                          : episodes[c.selectEpGroup.value].urls.length,
                      itemBuilder: (context, index) {
                        if (isSelected[c.selectEpGroup.value][index]) {
                          return fluent.FilledButton(
                            onPressed: () {
                              setState(() {
                                isSelected[c.selectEpGroup.value][index] = !isSelected[c.selectEpGroup.value][index];
                              });
                            },
                            child: Center(
                              child: Text(episodes[c.selectEpGroup.value]
                                  .urls[index]
                                  .name),
                            ),
                          );
                        }
                        return fluent.Button(
                          onPressed: () {
                            setState(() {
                              isSelected[c.selectEpGroup.value][index] = !isSelected[c.selectEpGroup.value][index];
                            });
                          },
                          child: Center(
                            child: Text(episodes[c.selectEpGroup.value]
                                .urls[index]
                                .name),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  fluent.Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween, // 在两端分布子组件
                    children: [
                      fluent.Row(
                        children: [
                          fluent.Checkbox(
                              checked: isSelectAll,
                              onChanged: (value) {
                                setState(() {
                                  isSelectAll = !isSelectAll;
                                  isSelected[c.selectEpGroup.value] = List.filled(
                                      episodes[c.selectEpGroup.value]
                                          .urls
                                          .length,
                                      isSelectAll);
                                });
                              }),
                          SizedBox(width: 8),
                          fluent.Text(
                            'detail.selectAll'.i18n,
                            style: fluent.FluentTheme.of(context)
                                .typography
                                .bodyStrong,
                          ),
                        ],
                      ),
                      fluent.Row(
                        children: [
                          fluent.ComboBox<int>(
                              items: comboBoxItems,
                              value: c.selectEpGroup.value,
                              onChanged: (value) {
                                setState(() {
                                  c.selectEpGroup.value = value!;
                                });
                              }),
                          const SizedBox(width: 8),
                          fluent.Button(
                              child: Text('detail.download'.i18n),
                              onPressed: () {
                                final toDownload = <int>[];
                                for (var i = 0; i < isSelected[c.selectEpGroup.value].length; i++) {
                                  if (isSelected[c.selectEpGroup.value][i]) {
                                    toDownload.add(i);
                                    isSelected[c.selectEpGroup.value][i] = false;
                                  }
                                }
                                c.download(toDownload);
                                context.pop();
                              }),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            );
          }));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      episodes = c.detail!.episodes ?? [];
      comboBoxItems = [
        for (var i = 0; i < episodes.length; i++)
          fluent.ComboBoxItem<int>(
            value: i,
            child: Text(episodes[i].title),
          )
      ];
      return PlatformBuildWidget(
        androidBuilder: (ctx) => Text('This is not supported on Android'),
        desktopBuilder: _buildDesktop,
      );
    });
  }
}
