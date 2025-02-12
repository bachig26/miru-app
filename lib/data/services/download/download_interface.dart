import 'package:miru_app/models/download_job.dart';

enum DownloaderType {
  mangaDownloader,
  vedioDownloader,
}

abstract class DownloadInterface {
  double get progress;

  int get id;

  DownloaderType getDownloaderType();

  DownloadStatus get status;

  String get name;

  String get url;

  String? get detail;

  Future<DownloadStatus> download();

  Future<void> pause();

  Future<void> resume();

  Future<void> cancel();

  // 用于给download_manager获取downloadJob, 以便于更新数据库
  DownloadJob get downloadJob;

  // 由于downloadJob中的resource会占用较大空间，所以在下载完成后需要释放资源
  // 释放资源后，downloadJob中的resource将会被置空
  // 由download_manager统一释放资源
  void releaseResource();

  bool get isPaused;
  bool get isDownloading;
  bool get isQueued;
  bool get isComplete;
  bool get isCanceled;
  bool get isFailed;
}
