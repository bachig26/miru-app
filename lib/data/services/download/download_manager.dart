// This is implementation is inspired by flutter_download_manager
// See https://github.com/nabil6391/flutter_download_manager
import 'dart:io';

import 'package:get/get.dart';
import 'package:miru_app/controllers/application_controller.dart';
import 'package:miru_app/data/services/download/download_interface.dart';
import 'package:miru_app/data/services/download/manga_downloader.dart';
import 'package:miru_app/data/services/download/mobile_foreground_service.dart';
import 'package:miru_app/data/services/download/video_downloader.dart';
import 'package:miru_app/models/download_job.dart';
import 'package:miru_app/utils/log.dart';
import 'package:miru_app/utils/miru_storage.dart';
import 'package:miru_app/data/services/database_service.dart';

class IdPool {
  final Set<int> _usedIds = {};
  int _nextId = 1;

  // 获取一个新的 ID
  int getNewId() {
    while (_usedIds.contains(_nextId)) {
      _nextId++;
    }
    _usedIds.add(_nextId);
    return _nextId;
  }

  // 释放一个已使用的 ID
  void releaseId(int id) {
    _usedIds.remove(id);
    if (_usedIds.isEmpty) {
      _nextId = 1;
    }
  }

  void getSpecNewIdStrict(int id) {
    if (_usedIds.contains(id)) {
      assert(false, 'ID $id is already used');
    } else {
      _usedIds.add(id);
      if (id >= _nextId) {
        _nextId = id + 1;
      }
    }
  }
}

// Task类，用于提供一个封装过的DownloadInterface
// 用于外部类获取下载任务的信息
// 避免对下载任务的直接操作
// 由于无法避免的原因
// 它需要与UI层耦合
class TaskInternal {
  late DownloadInterface _download;

  TaskInternal({required DownloadInterface download}) {
    _download = download;
  }

  double get progress => _download.progress;

  DownloadStatus get status => _download.status;

  String get name => _download.name;

  String get url => _download.url;

  String? get detail => _download.detail;

  int get id => _download.id;

  void pause() {
    DownloadManager().pauseById(_download.id);
  }

  void resume() {
    DownloadManager().resumeById(_download.id);
  }

  void cancel() {
    DownloadManager().cancelById(_download.id);
  }
}

class DownloadManager {
  final _queue = List<DownloadInterface>.empty(growable: true);
  final _downloading = List<DownloadInterface>.empty(growable: true);
  final _paused = List<DownloadInterface>.empty(growable: true);
  final _others = List<DownloadInterface>.empty(growable: true);
  final _idPool = IdPool();
  final c = Get.find<ApplicationController>();

  bool get isDownloading => _downloading.isNotEmpty && _queue.isNotEmpty;

  static final DownloadManager _instance = DownloadManager._internal();

  factory DownloadManager() {
    return _instance;
  }

  static Future<void> init() async {
    var cnt = 0;
    // 从数据库中加载下载任务
    DatabaseService.getDownloadJobs().then((jobs) {
      logger.info('Load download jobs from database');
      for (final job in jobs) {
        switch (job.status) {
          case DownloadStatus.queued:
          case DownloadStatus.downloading:
          case DownloadStatus.paused:
            // 获取id
            final id = job.jobId;
            // 为id分配一个新的id
            _instance._idPool.getSpecNewIdStrict(id);
            logger.info('id: $id,Job id: ${job.jobId}, status: ${job.status}');
            cnt++;
            final newIns = MangaDownloader(job, id);
            newIns.pause();
            // 更新数据库
            assert(newIns.downloadJob.jobId == newIns.id);
            DatabaseService.putDownloadJobsById(newIns.id, newIns.downloadJob);
            _instance._paused.add(newIns);
            break;
          case DownloadStatus.canceled:
          case DownloadStatus.failed:
          case DownloadStatus.completed:
            // 删除数据库中的任务
            DatabaseService.deleteDownloadJobById(job.jobId);
            break;
        }
      }
    });
    if (cnt == 0) {
      DatabaseService.deleteAllDownloadJobs();
    }
    _instance._execution();
  }

  DownloadManager._internal();

  double get progress {
    if (!isDownloading) {
      return 0.0;
    }
    final total = _downloading.length;
    var count = 0;
    for (final download in _downloading) {
      count += download.progress.toInt();
    }
    return count / total;
  }

  void addDownload(OfflineResource resource) async {
    final downloadType = resource.type;
    final id = _idPool.getNewId();

    // 确保Job的id与Downloader的id一致
    final downloadJob = DownloadJob(jobId: id, resource: resource);
    await DatabaseService.putDownloadJobsById(id, downloadJob);
    switch (downloadType) {
      case ResourceType.manga:
        _queue.add(MangaDownloader(downloadJob, id));
        break;
      case ResourceType.video:
        _queue.add(VideoDownloader(downloadJob, id));
        break;
      case ResourceType.novel:
        assert(false, 'Not implemented');
        break;
    }
  }

  void _execution() async {
    final activeTasks = c.activeTasks;
    final othersTasks = c.othersTasks;
    while (true) {
      final maxTasks = MiruStorage.getSetting(SettingKey.downloadMaxTasks);

      if (Platform.isAndroid) {
        // 检查前台任务
        if (activeTasks.isNotEmpty && !await isRunningService()) {
          // 启动前台任务
          await startService();
        }
        if (activeTasks.isEmpty && await isRunningService()) {
          // 停止前台任务
          await stopService();
        }
      }

      // clear not active download
      _downloading.removeWhere((download) {
        if (download.status.isComplete ||
            download.status.isCanceled ||
            download.status.isFailed) {
          if (download.status.isComplete) {
            download.releaseResource();
            // 更新数据库
            assert(download.downloadJob.jobId == download.id);
            DatabaseService.putDownloadJobsById(
                download.id, download.downloadJob);
          }
          if (download.status.isCanceled || download.status.isFailed) {
            // 更新数据库
            assert(download.downloadJob.jobId == download.id);
            DatabaseService.putDownloadJobsById(
                download.id, download.downloadJob);
          }
          _others.add(download);
          return true;
        } else if (download.status.isPaused) {
          _paused.add(download);
          return true;
        }
        return false;
      });
      while (_downloading.length < maxTasks) {
        if (_queue.isEmpty) {
          break;
        }
        final download = _queue.removeAt(0);
        download.download();
        _downloading.add(download);
      }

      // 更新UI
      activeTasks.clear();
      for (final download in _downloading) {
        activeTasks.add(TaskInternal(download: download));
      }
      for (final download in _queue) {
        activeTasks.add(TaskInternal(download: download));
      }
      for (final download in _paused) {
        activeTasks.add(TaskInternal(download: download));
      }
      othersTasks.clear();
      for (final download in _others) {
        othersTasks.add(TaskInternal(download: download));
      }
      activeTasks.refresh();
      othersTasks.refresh();
      await Future.delayed(Duration(milliseconds: 500));
    }
  }

  void pauseAll() {
    for (int i = 0; i < _downloading.length; i++) {
      final download = _downloading.removeLast();
      download.pause();
      // 更新数据库
      assert(download.downloadJob.jobId == download.id);
      DatabaseService.putDownloadJobsById(download.id, download.downloadJob);
    }
  }

  void resumeAll() {
    final maxTasks = MiruStorage.getSetting(SettingKey.downloadMaxTasks);
    for (int i = _paused.length; i < maxTasks; i++) {
      if (_paused.isEmpty) {
        break;
      }
      final download = _paused.removeLast();
      download.resume();
      // 更新数据库
      assert(download.downloadJob.jobId == download.id);
      DatabaseService.putDownloadJobsById(download.id, download.downloadJob);
      _downloading.add(download);
    }
  }

  void cancelAll() {
    for (int i = 0; i < _downloading.length; i++) {
      final download = _downloading.removeLast();
      download.cancel();
      // 更新数据库
      assert(download.downloadJob.jobId == download.id);
      DatabaseService.putDownloadJobsById(download.id, download.downloadJob);
      _others.add(download);
    }
    for (int i = 0; i < _queue.length; i++) {
      final download = _queue.removeLast();
      download.cancel();
      // 更新数据库
      assert(download.downloadJob.jobId == download.id);
      DatabaseService.putDownloadJobsById(download.id, download.downloadJob);
      _others.add(download);
    }
    for (int i = 0; i < _paused.length; i++) {
      final download = _paused.removeLast();
      download.cancel();
      // 更新数据库
      assert(download.downloadJob.jobId == download.id);
      DatabaseService.putDownloadJobsById(download.id, download.downloadJob);
      _others.add(download);
    }
  }

  void pauseById(int id) {
    DownloadInterface? download;
    // 在 _downloading 列表中查找
    download = _downloading.firstWhereOrNull((download) => download.id == id);
    if (download != null) {
      _downloading.remove(download);
    } else {
      // 在 _queue 队列中查找
      download = _queue.firstWhereOrNull((download) => download.id == id);
      if (download != null) {
        _queue.remove(download);
      }
    }
    if (download != null) {
      download.pause();
      // 更新数据库
      assert(download.downloadJob.jobId == download.id);
      DatabaseService.putDownloadJobsById(download.id, download.downloadJob);
      _paused.add(download);
    }
  }

  void resumeById(int id) {
    final download = _paused.firstWhere((download) => download.id == id);
    download.resume();
    // 更新数据库
    assert(download.downloadJob.jobId == download.id);
    DatabaseService.putDownloadJobsById(download.id, download.downloadJob);
    _paused.remove(download);
    _queue.add(download);
  }

  void cancelById(int id) {
    DownloadInterface? download;
    // 在 _downloading 列表中查找
    download = _downloading.firstWhereOrNull((download) => download.id == id);
    if (download != null) {
      _downloading.remove(download);
    } else {
      // 在 _queue 队列中查找
      download = _queue.firstWhereOrNull((download) => download.id == id);
      if (download != null) {
        _queue.remove(download);
      } else {
        // 在 _paused 列表中查找
        download = _paused.firstWhereOrNull((download) => download.id == id);
        if (download != null) {
          _paused.remove(download);
        }
      }
    }
    if (download != null) {
      download.cancel();
      // 更新数据库
      assert(download.downloadJob.jobId == download.id);
      DatabaseService.putDownloadJobsById(download.id, download.downloadJob);
      _others.add(download);
    }
  }

  void pauseByIds(List<int> ids) {
    for (final id in ids) {
      pauseById(id);
    }
  }

  void resumeByIds(List<int> ids) {
    for (final id in ids) {
      resumeById(id);
    }
  }

  void cancelByIds(List<int> ids) {
    for (final id in ids) {
      cancelById(id);
    }
  }
}
