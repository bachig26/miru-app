import 'package:miru_app/models/download_job.dart';
import 'package:miru_app/models/extension.dart';
import 'package:miru_app/utils/miru_storage.dart';
import 'package:miru_app/utils/path_utils.dart';
// import 'package:path/path.dart' as p;
import 'package:miru_app/data/services/download/download_manager.dart';

final DownloadManager downloadManager = DownloadManager();

class OfflineResourceService {
  static Future<String> newDirectory(String name, ResourceType type) async {
    // 创建文件夹
    String sanitizedName = sanitizeFileName(name);
    String rootPath = MiruStorage.getSetting(SettingKey.downloadPath);
    final path = await miruCreateFolderInTree(
        rootPath, [type.toString().split('.').last, sanitizedName]);
    return path!;
  }

  static void startMangaDownloadJob(String package, String url,
      ExtensionDetail details, int ep, List<int> chaptersToDownload) async {
    // 下载漫画
    OfflineResource resource = OfflineResource();
    resource.source = ResourceSource.fromExtension;
    resource.type = ResourceType.manga;
    resource.package = package;
    resource.url = url;
    resource.title = details.title;
    resource.cover = details.cover;
    resource.path =
        await newDirectory('$package ${details.title}', ResourceType.manga);
    final episodes = details.episodes ?? [];
    final curEp = episodes[ep];
    final epInstance = Ep()
      ..title = curEp.title
      ..items = []
      ..subPath = sanitizeFileName(curEp.title);
    epInstance.items = chaptersToDownload.map((index) {
      final episode = episodes[ep].urls[index];
      final item = Item();
      item.title = episode.name;
      item.subPath = sanitizeFileName(episode.name);
      item.url = episode.url;
      return item;
    }).toList();
    resource.eps = [epInstance];
    downloadManager.addDownload(resource);
  }

  static void startAnimeDownloadJob(String package, String url,
      ExtensionDetail details, int ep, List<int> chaptersToDownload) async {
        OfflineResource resource = OfflineResource();
        resource.source = ResourceSource.fromExtension;
        resource.type = ResourceType.video;
        resource.package = package;
        resource.url = url;
        resource.title = details.title;
        resource.cover = details.cover;
        resource.path = await newDirectory('$package-${details.title}', ResourceType.video);
        final episodes = details.episodes ?? [];
        final curEp = episodes[ep];
        final epInstance = Ep()
          ..title = curEp.title
          ..items = []
          ..subPath = sanitizeFileName(curEp.title);
        epInstance.items = chaptersToDownload.map((index) {
          final episode = episodes[ep].urls[index];
          final item = Item();
          item.title = episode.name;
          item.subPath = sanitizeFileName(episode.name);
          item.url = episode.url;
          return item;
        }).toList();
        resource.eps = [epInstance];
        downloadManager.addDownload(resource);
      }
}
