import 'package:flutter/material.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:get/get.dart';
import 'package:miru_app/controllers/application_controller.dart';
import 'package:miru_app/data/services/download/download_manager.dart';
import 'package:miru_app/models/download_job.dart';
import 'package:miru_app/utils/i18n.dart';
import 'package:miru_app/views/widgets/platform_widget.dart';

class BottomBorderButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget child;
  final bool hasBorder;

  const BottomBorderButton({
    super.key,
    required this.onPressed,
    required this.child,
    required this.hasBorder,
  });

  @override
  Widget build(BuildContext context) {
    return fluent.IconButton(
      onPressed: onPressed,
      icon: Container(
        padding: EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
        decoration: hasBorder
            ? BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: fluent.FluentTheme.of(context).accentColor,
                    width: 3.0,
                  ),
                ),
              )
            : null,
        child: child,
      ),
    );
  }
}

class DownloadManagerPage extends StatefulWidget {
  const DownloadManagerPage({super.key, this.tag});

  final String? tag;

  @override
  State<DownloadManagerPage> createState() => _DownloadManagerPageState();
}

typedef Task = TaskInternal;

class _DownloadManagerPageState extends State<DownloadManagerPage> {
  final c = Get.find<ApplicationController>();
  final Set<int> _selectedTasks = {}; // 选中的任务
  int curTab = 0;

  Widget listUtils(List<Task> listToDisplay) {
    return Expanded(
      child: Center(
        child: ListView.builder(
          itemCount: listToDisplay.length,
          itemBuilder: (context, index) {
            final task = listToDisplay[index];
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: fluent.FluentTheme.of(context).micaBackgroundColor,
                borderRadius: BorderRadius.circular(4),
              ),
              child: fluent.ListTile.selectable(
                tileColor: WidgetStateProperty.resolveWith((states) {
                  if (states.isHovered || states.isFocused) {
                    return fluent.FluentTheme.of(context)
                        .accentColor
                        .withOpacity(1);
                  }
                  return fluent.FluentTheme.of(context).micaBackgroundColor;
                }),
                selected: task.status.isActive
                    ? _selectedTasks.contains(task.id)
                    : false,
                onSelectionChange: task.status.isActive
                    ? (selected) {
                        setState(() {
                          if (selected) {
                            _selectedTasks.add(task.id);
                          } else {
                            _selectedTasks.remove(task.id);
                          }
                        });
                      }
                    : null,
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            if (task.status.isActive)
                              fluent.Checkbox(
                                checked: _selectedTasks.contains(task.id),
                                onChanged: (value) {
                                  setState(() {
                                    if (value!) {
                                      _selectedTasks.add(task.id);
                                    } else {
                                      _selectedTasks.remove(task.id);
                                    }
                                  });
                                },
                              ),
                            const SizedBox(width: 16),
                            Text(task.name),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (task.status.isActive) ...[
                              IconButton(
                                  icon: Icon(fluent.FluentIcons.cancel),
                                  onPressed: () {
                                    setState(() {
                                      task.cancel();
                                      listToDisplay.remove(task);
                                    });
                                  }),
                              IconButton(
                                icon: Icon(task.status.isPaused
                                    ? fluent.FluentIcons.play
                                    : fluent.FluentIcons.pause),
                                onPressed: () {
                                  setState(() {
                                    if (task.status.isPaused) {
                                      task.resume();
                                    } else {
                                      task.pause();
                                    }
                                  });
                                },
                              ),
                            ],
                            if (task.status.isDead) ...[
                              IconButton(
                                icon: Icon(fluent.FluentIcons.refresh),
                                onPressed: () {
                                  setState(() {
                                    // TODO: 重新下载任务
                                  });
                                },
                              ),
                            ]
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      // mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const SizedBox(width: 16),
                        Expanded(
                          child: fluent.ProgressBar(
                            value: task.progress * 100,
                            backgroundColor: Colors.grey[200],
                            strokeWidth: 6,
                          ),
                        ),
                        const SizedBox(width: 16),
                      ],
                    ),
                  ],
                ),
                subtitle: Column(
                  children: [
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const SizedBox(width: 16),
                        Text('download.download-status.${task.status.status}'
                            .i18n),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const SizedBox(width: 16),
                        if (task.detail != null) Text(task.detail!),
                        const SizedBox(width: 8),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  bool get _isAnySelected => _selectedTasks.isNotEmpty;

  Widget _buildAndroid(BuildContext context) {
    return Obx(() {
      final activeTasks = c.activeTasks.toList();
      final othersTasks = c.othersTasks.toList();
      final tasks = activeTasks + othersTasks;
      return Scaffold(
        appBar: AppBar(
          title: Text('Download Manager'),
          actions: [
            IconButton(
              icon: Icon(Icons.play_arrow),
              onPressed: _isAnySelected ? _resumeSelectedTasks : null,
            ),
            IconButton(
              icon: Icon(Icons.pause),
              onPressed: _isAnySelected ? _pauseSelectedTasks : null,
            ),
            IconButton(
              icon: Icon(Icons.cancel),
              onPressed: _isAnySelected ? _cancelSelectedTasks : null,
            ),
          ],
        ),
        body: ListView.builder(
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final task = tasks[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  ListTile(
                    leading: task.status.isActive
                        ? Checkbox(
                            value: _selectedTasks.contains(task.id),
                            onChanged: (value) {
                              setState(() {
                                if (value!) {
                                  _selectedTasks.add(task.id);
                                } else {
                                  _selectedTasks.remove(task.id);
                                }
                              });
                            },
                          )
                        : null,
                    title: Text(task.name),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      if (task.status.isActive) ...[
                        IconButton(
                          icon: Icon(Icons.cancel),
                          onPressed: () {
                            setState(() {
                              tasks.remove(task);
                              task.cancel();
                            });
                          },
                        ),
                        IconButton(
                          icon: Icon(task.status.isPaused
                              ? Icons.play_arrow
                              : Icons.pause),
                          onPressed: () {
                            setState(() {
                              if (task.status.isPaused) {
                                task.resume();
                              } else {
                                task.pause();
                              }
                            });
                          },
                        ),
                      ],
                    ]),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: LinearProgressIndicator(
                      value: task.progress,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('download.download-status.${task.status.status}'
                            .i18n),
                        if (task.detail != null) Text('${task.detail}'),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    });
  }

  Widget _buildDesktop(BuildContext context) {
    return Obx(() {
      final activeTasks = c.activeTasks.toList();
      final othersTasks = c.othersTasks.toList();
      return LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          return Center(
            child: ConstrainedBox(
                constraints: BoxConstraints(
                    maxWidth: width * 0.8 < 1600 ? width * 0.8 : 1600,
                    maxHeight: height * 0.8 < 1200 ? height * 0.8 : 1200),
                child: Stack(
                  children: [
                    Container(
                        decoration: BoxDecoration(
                      color: fluent.FluentTheme.of(context).menuColor,
                      borderRadius: BorderRadius.circular(12),
                    )),
                    Padding(
                      padding: const EdgeInsets.all(64),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'download.download-manager'.i18n,
                                style: fluent.FluentTheme.of(context)
                                    .typography
                                    .title,
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  fluent.Button(
                                    onPressed: _isAnySelected
                                        ? _resumeSelectedTasks
                                        : null,
                                    child: Text('download.resume'.i18n),
                                  ),
                                  const SizedBox(width: 8),
                                  fluent.Button(
                                    onPressed: _isAnySelected
                                        ? _pauseSelectedTasks
                                        : null,
                                    child: Text('download.pause'.i18n),
                                  ),
                                  const SizedBox(width: 8),
                                  fluent.Button(
                                    onPressed: _isAnySelected
                                        ? _cancelSelectedTasks
                                        : null,
                                    child: Text('download.cancel'.i18n),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              BottomBorderButton(
                                onPressed: () {
                                  setState(() {
                                    curTab = 0;
                                  });
                                },
                                hasBorder: curTab == 0,
                                child: Text('download.downloading'.i18n),
                              ),
                              BottomBorderButton(
                                onPressed: () {
                                  setState(() {
                                    curTab = 1;
                                  });
                                },
                                hasBorder: curTab == 1,
                                child: Text('download.others'.i18n),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          if (curTab == 0)
                            listUtils(activeTasks)
                          else
                            listUtils(othersTasks),
                        ],
                      ),
                    ),
                  ],
                )),
          );
        },
      );
    });
  }

  void _resumeSelectedTasks() {
    // 恢复选中任务的逻辑
    DownloadManager().resumeByIds(_selectedTasks.toList());
    _selectedTasks.clear();
  }

  void _pauseSelectedTasks() {
    // 暂停选中任务的逻辑
    DownloadManager().pauseByIds(_selectedTasks.toList());
    _selectedTasks.clear();
  }

  void _cancelSelectedTasks() {
    // 取消选中任务的逻辑
    DownloadManager().cancelByIds(_selectedTasks.toList());
    _selectedTasks.clear();
  }

  @override
  Widget build(BuildContext context) {
    return PlatformBuildWidget(
      androidBuilder: _buildAndroid,
      desktopBuilder: _buildDesktop,
    );
  }
}
