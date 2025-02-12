import 'dart:io';

import 'package:flutter/material.dart';
import 'package:re_editor/re_editor.dart';
import 'package:miru_app/models/extension.dart';
import 'package:miru_app/utils/extension.dart';
import 'package:miru_app/views/widgets/messenger.dart';
import 'package:re_highlight/languages/javascript.dart';
import 'package:re_highlight/styles/atom-one-light.dart';

class CodeEditPage extends StatefulWidget {
  const CodeEditPage({
    required this.extension,
    super.key,
  });
  final Extension extension;
  @override
  State<CodeEditPage> createState() => _CodeEditPageState();
}

class _CodeEditPageState extends State<CodeEditPage> {
  CodeLineEditingController controller = CodeLineEditingController();

  @override
  void initState() {
    _init();
    super.initState();
  }

  _init() async {
    final dir = ExtensionUtils.extensionsDir;
    final file = File('$dir/${widget.extension.package}.js');
    if (await file.exists()) {
      final content = await file.readAsString();
      controller.text = content;
    }
  }

  _save() async {
    final dir = ExtensionUtils.extensionsDir;
    final file = File('$dir/${widget.extension.package}.js');
    await file.writeAsString(controller.text);
    // ignore: use_build_context_synchronously
    showPlatformSnackbar(context: context, title: '保存代码', content: '保存成功');
  }

  @override
  Widget build(BuildContext context) {
    Color primaryColor = Theme.of(context).primaryColor;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.extension.name),
        actions: [
          IconButton(
            onPressed: () async {
              _save();
            },
            icon: const Icon(Icons.save),
          ),
        ],
      ),
      body: CodeEditor(
        style: CodeEditorStyle(
          codeTheme: CodeHighlightTheme(languages: {
            'javascript': CodeHighlightThemeMode(mode: langJavascript)
          }, theme: atomOneLightTheme),
        ),
        controller: controller,
        wordWrap: false,
        indicatorBuilder:
            (context, editingController, chunkController, notifier) {
          return Row(
            children: [
              DefaultCodeLineNumber(
                controller: editingController,
                notifier: notifier,
              ),
              DefaultCodeChunkIndicator(
                width: 20,
                controller: chunkController,
                notifier: notifier,
              )
            ],
          );
        },
        //findBuilder: (context, controller, readOnly) => CodeFindPanelView(controller: controller, readOnly: readOnly),
        //toolbarController: const ContextMenuControllerImpl(),
        sperator: Container(width: 1, color: primaryColor),
      ),
    );
  }
}
