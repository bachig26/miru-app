import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:miru_app/data/services/database_service.dart';
import 'package:miru_app/data/services/download/download_manager.dart';
import 'package:miru_app/data/services/download/mobile_foreground_service.dart';
import 'package:miru_app/utils/android_permission.dart';
import 'package:miru_app/utils/log.dart';
import 'package:miru_app/utils/miru_storage.dart';
import 'package:miru_app/utils/path_utils.dart';

class AndroidWelcomePage extends StatefulWidget {
  const AndroidWelcomePage({super.key});

  @override
  State<AndroidWelcomePage> createState() => _AndroidWelcomePage();
}

class _AndroidWelcomePage extends State<AndroidWelcomePage> {
  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    bool isDark =
        Theme.of(context).brightness == Brightness.dark ? true : false;
    final textColor = !isDark ? context.theme.primaryColor : Colors.grey;
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(
              children: [
                SizedBox(height: height * 0.2), // 间距
                const Image(
                  image: AssetImage('assets/icon/logo.png'),
                  width: 100,
                  height: 100,
                ),
              ],
            ),
            const SizedBox(height: 20), // 间距
            Column(
              children: [
                Text(
                  "Welcome!",
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 20), // 间距
                Text(
                  "Please complete the initial setup to get started.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: textColor,
                  ),
                ),
              ],
            ),
            Spacer(), // 空间填充，让按钮靠底部
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                  ),
                  onPressed: () {
                    Get.to(() => const WelcomeSettingPage(),
                        transition: Transition.rightToLeft,
                        duration: Duration(milliseconds: 300));
                  },
                  child: Text(
                    "Next",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WelcomeSettingPage extends StatefulWidget {
  const WelcomeSettingPage({super.key});

  @override
  State<WelcomeSettingPage> createState() => _WelcomeSettingPage();
}

class _WelcomeSettingPage extends State<WelcomeSettingPage> {
  var isNotiGranted = MiruStorage.getSetting('IsNotificationGranted');
  var downloadPath = MiruStorage.getSetting('DownloadPath');
  var selectedPath = '';

  Future<void> loadSelectedPath() async {
    final path = await miruGetActualPath(downloadPath) ?? '';
    setState(() {
      selectedPath = path;
    });
  }

  @override
  void initState() {
    super.initState();
    loadSelectedPath();
  }

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    bool isDark =
        Theme.of(context).brightness == Brightness.dark ? true : false;
    final textColor = !isDark ? context.theme.primaryColor : Colors.grey;
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          constraints: BoxConstraints(minHeight: 800 > height ? 800 : height),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                children: [
                  SizedBox(height: height * 0.2), // 间距
                  const Image(
                    image: AssetImage('assets/icon/logo.png'),
                    width: 105,
                    height: 105,
                  ),
                ],
              ),
              Transform.translate(
                offset: Offset(0, -35),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      color: !isDark ? Colors.grey[200] : Colors.grey[500],
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Select a directory to store Miru\'s offline content (manga, anime, etc.)',
                              style: TextStyle(
                                  fontSize: 16, color: Colors.black),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'A dedicated folder is recommended.',
                              style: TextStyle(
                                  fontSize: 14, color: Colors.black54),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Selected folder: ${selectedPath == '' ? 'Not selected' : selectedPath}',
                              style: TextStyle(
                                  fontSize: 14, color: Colors.black54),
                            ),
                            SizedBox(height: 16),
    
                            // 按钮1: Select a folder
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () async {
                                  var newPath = await miruPickDir(
                                      writePermission: true);
                                  if (newPath == null ||
                                      newPath == downloadPath) {
                                    return;
                                  }
                                  final folderUri =
                                      await miruCreateFolderInTree(
                                          newPath, ['Miru']);
                                  if (folderUri == null) {
                                    return;
                                  }
                                  logger.info(
                                      'persistent: ${await miruCheckUriPersisted(folderUri)}');
                                  final folderPath =
                                      await miruGetActualPath(folderUri);
                                  if (folderPath == null) {
                                    logger.warning(
                                        'Welcome Page: Failed to get folder path');
                                    return;
                                  }
                                  await miruCreateEmptyFile(
                                      folderUri, '.nomedia');
                                  selectedPath = folderPath;
                                  // 更新一下内部数据库
                                  DownloadManager().cancelAll();
                                  DatabaseService
                                      .clearAllMiruDetailOfflineResourceJson();
                                  MiruStorage.setSetting(
                                      'DownloadPath', folderUri);
                                  setState(() {
                                    downloadPath = folderPath;
                                  });
                                },
                                child: Text('Select a folder',
                                    style: TextStyle(color: textColor)),
                              ),
                            ),
                            Divider(color: Colors.black26, height: 32),
    
                            // 文字2
                            Text('Turn on notifications for download updates',
                                style: TextStyle(
                                    fontSize: 16, color: Colors.black)),
                            SizedBox(height: 8),
                            Text(
                              'Miru requires notification permissions to enable background downloads.',
                              style: TextStyle(
                                  fontSize: 14, color: Colors.black54),
                            ),
                            SizedBox(height: 16),
    
                            // 按钮2: Notification guide
                            SizedBox(
                              width: double.infinity,
                              child: !isNotiGranted
                                  ? ElevatedButton(
                                      onPressed: () async {
                                        final temp =
                                            await requestNotificationPermissions();
                                        if (temp) {
                                          initForegroundService();
                                        }
                                        setState(() {
                                          isNotiGranted = temp;
                                        });
                                        MiruStorage.setSetting(
                                            'IsNotificationGranted',
                                            isNotiGranted);
                                      },
                                      child: Text('Notification Permission',
                                          style: TextStyle(color: textColor)),
                                    )
                                  : ElevatedButton(
                                      onPressed: () {},
                                      child: Icon(
                                        Icons.check,
                                        color: textColor,
                                      )),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                    ),
                    onPressed: isNotiGranted && downloadPath != ''
                        ? () {
                            Get.close(2);
                          }
                        : null,
                    child: Text(
                      "Finish",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: !isNotiGranted || downloadPath == ''
                            ? Colors.grey
                            : !isDark
                                ? context.theme.primaryColor
                                : Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
