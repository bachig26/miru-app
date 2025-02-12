import 'package:isar/isar.dart';

part 'download_job.g.dart';

enum DownloadStatus {
  queued,
  downloading,
  completed,
  failed,
  paused,
  canceled,
}

extension DownloadStatusExtension on DownloadStatus {
  String get status {
    switch (this) {
      case DownloadStatus.queued:
        return 'queued';
      case DownloadStatus.downloading:
        return 'downloading';
      case DownloadStatus.completed:
        return 'completed';
      case DownloadStatus.failed:
        return 'failed';
      case DownloadStatus.paused:
        return 'paused';
      case DownloadStatus.canceled:
        return 'canceled';
    }
  }

  bool get isQueued {
    return this == DownloadStatus.queued;
  }

  bool get isDownloading {
    return this == DownloadStatus.downloading;
  }

  bool get isComplete {
    return this == DownloadStatus.completed;
  }

  bool get isFailed {
    return this == DownloadStatus.failed;
  }

  bool get isPaused {
    return this == DownloadStatus.paused;
  }

  bool get isCanceled {
    return this == DownloadStatus.canceled;
  }

  bool get isActive {
    return this == DownloadStatus.downloading || this == DownloadStatus.queued || this == DownloadStatus.paused;
  }

  bool get isDead {
    return this == DownloadStatus.failed || this == DownloadStatus.canceled || this == DownloadStatus.completed;
  }
}

enum ResourceType {
  video,
  manga,
  novel,
}

enum ResourceSource {
  userImport,
  // bitorrentDownload,
  fromExtension,
}


@embedded
class Item {
  late String title;
  late String subPath;
  late String url;
}

@embedded
class Ep {
  late String title;
  late List<Item> items;
  late String subPath;
}


@embedded
class OfflineResource {
  bool virtualResource = true;
  @Enumerated(EnumType.name)
  late ResourceSource source;

  @Enumerated(EnumType.name)
  late ResourceType type;

  late String? package;
  late String? url;
  late String title;
  late String? cover;
  late String path;

  late List<Ep> eps;
}

@Collection()
class DownloadJob {
  Id id = Isar.autoIncrement;
  @Enumerated(EnumType.name)
  DownloadStatus status = DownloadStatus.queued;

  @Index(name: 'jobId', unique: true)
  late int jobId;

  late OfflineResource? resource;

  DownloadJob({required this.jobId, OfflineResource? resource}) {
    assert(resource != null, 'Resource cannot be null');
    if (resource != null) {
      this.resource = resource;
    }
  }

  void setResourceToNull() {
    resource = null;
  }
}
