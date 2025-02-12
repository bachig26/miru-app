import 'dart:async';

import 'package:get/get.dart';
import 'package:miru_app/models/extension.dart';
import 'package:miru_app/models/history.dart';
import 'package:miru_app/controllers/home_controller.dart';
import 'package:miru_app/data/services/database_service.dart';
import 'package:miru_app/data/services/extension_service.dart';
import 'package:miru_app/models/miru_detail.dart';
import 'package:miru_app/utils/log.dart';
import 'package:miru_app/utils/path_utils.dart';

class ReaderController<T> extends GetxController {
  final String title; // 这个应该是漫画标题（吧）
  final List<ExtensionEpisode> playList;
  final String detailUrl;
  final int playIndex;
  final int episodeGroupId;
  final ExtensionService runtime;
  final String? cover;
  final String anilistID;
  final MiruDetail miruDetail; // 里面存储了离线资源的信息
  final ExtensionDetail extensionDetail; // 里面存储了漫画章节信息

  ReaderController({
    required this.title,
    required this.playList,
    required this.detailUrl,
    required this.playIndex,
    required this.episodeGroupId,
    required this.runtime,
    required this.anilistID,
    required this.miruDetail,
    required this.extensionDetail,
    this.cover,
  });

  late Rx<T?> watchData = Rx(null);
  late Rx<List<String>> offlineWatchData = Rx([]);
  final useOfflineData = false.obs;
  final error = ''.obs;
  final isShowControlPanel = false.obs;
  late final index = playIndex.obs;
  get cuurentPlayUrl => playList[index.value].url;
  Timer? _timer;

  @override
  void onInit() {
    getContent();
    ever(index, (callback) => getContent());
    super.onInit();
  }

  getContent() async {
    try {
      // 首先获取最新的MiruDetail
      final newMiruDetail = await DatabaseService.getMiruDetailByInstance(miruDetail);
      final epTitle = extensionDetail.episodes?[episodeGroupId].title;
      final itemTitle =
          extensionDetail.episodes?[episodeGroupId].urls[index.value].name;
      logger.info('ReaderController: getContent: $epTitle - $itemTitle, offline: ${newMiruDetail!.offlineResource}');
      error.value = '';
      watchData.value = null;
      if (newMiruDetail.offlineResource[epTitle]?[itemTitle] != null) {
        final itemPath = newMiruDetail.offlineResource[epTitle]![itemTitle]!;
        offlineWatchData.value = await getSortedFiles(itemPath);
        useOfflineData.value = true;
      } else {
        watchData.value = await runtime.watch(cuurentPlayUrl) as T;
        useOfflineData.value = false;
      }
    } catch (e) {
      error.value = e.toString();
    }
  }

  void previousPage() {}

  void nextPage() {}

  showControlPanel() {
    isShowControlPanel.value = true;
    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 3), () {
      isShowControlPanel.value = false;
    });
  }

  addHistory(String progress, String totalProgress) async {
    await DatabaseService.putHistory(
      History()
        ..url = detailUrl
        ..episodeId = index.value
        ..type = runtime.extension.type
        ..episodeGroupId = episodeGroupId
        ..package = runtime.extension.package
        ..episodeTitle = playList[index.value].name
        ..title = title
        ..progress = progress
        ..totalProgress = totalProgress
        ..cover = cover,
    );
    await Get.find<HomePageController>().onRefresh();
  }
}
