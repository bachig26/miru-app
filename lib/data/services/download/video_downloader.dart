import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_hls_parser/flutter_hls_parser.dart';
import 'package:miru_app/data/services/database_service.dart';
import 'package:miru_app/data/services/download/download_interface.dart';
import 'package:miru_app/data/services/extension_service.dart';
import 'package:miru_app/models/download_job.dart';
import 'package:miru_app/models/index.dart';
import 'package:miru_app/utils/extension.dart';
import 'package:miru_app/utils/log.dart';
import 'package:miru_app/utils/path_utils.dart';

class VideoDownloader extends DownloadInterface {
  // 配置最大并发数
  static const int maxConcurrentDownloads = 3;

  late int _id;
  var _progress = 0.0;
  var _status = DownloadStatus.queued;
  // 跟踪每个分片的下载进度
  // final _downloadProgress = <String, double>{};
  // 跟踪活动的下载任务
  final _activeDownloads = <String, CancelToken>{};
  late String _name;
  late String _url;
  late DownloadJob _job;
  late MiruDetail? _detail;
  late String? detailPackage;
  late String? detailUrl;

  VideoDownloader(DownloadJob job, int id) {
    _job = job;
    _name = job.resource!.title;
    _url = job.resource!.url!;
    _id = id;
    detailPackage = job.resource?.package;
    detailUrl = job.resource?.url;
    if (detailPackage != null && detailUrl != null) {
      DatabaseService.getMiruDetail(detailPackage!, detailUrl!).then((value) {
        _detail = value;
      });
    } else {
      logger.warning('Video downloader: Resource package or url is null');
    }
  }

  bool deadStatus() {
    return _status == DownloadStatus.canceled ||
        _status == DownloadStatus.failed ||
        _status == DownloadStatus.completed;
  }

  @override
  int get id => _id;

  @override
  String? get detail => _job.resource?.package;

  @override
  DownloadStatus get status => _status;

  @override
  double get progress => _progress;

  @override
  DownloaderType getDownloaderType() {
    return DownloaderType.vedioDownloader;
  }

  Future<(String url, List<Segment> segments)> _getM3U8Segments(
      String url, Map<String, String> headers) async {
    logger.info('get_m3u8_segments_url: $url, headers: $headers');
    final response = await Dio().get(
      url,
      options: Options(
        headers: headers,
        responseType: ResponseType.stream,
      ),
    );

    // 检查content-type是否为m3u8
    final contentType = response.headers.value('content-type')?.toLowerCase();
    if (contentType == null ||
        !contentType.contains('mpegurl') &&
            !contentType.contains('m3u8') &&
            !contentType.contains('mp2t')) {
      throw Exception('Invalid content type: $contentType');
    }

    // 接收数据到变量
    final stream = response.data.stream;
    final buffer = StringBuffer();

    await for (final data in stream) {
      buffer.write(utf8.decode(data));
    }
    final m3u8Content = buffer.toString();
    if (m3u8Content.isEmpty) {
      throw Exception('Empty m3u8 content');
    }

    late HlsPlaylist playlist;
    try {
      playlist = await HlsPlaylistParser.create().parseString(
        response.realUri,
        m3u8Content,
      );
    } on ParserException catch (e) {
      logger.severe(e);
      throw Exception('Failed to parse m3u8: $e');
    }

    if (playlist is HlsMasterPlaylist) {
      // Master playlist contains multiple quality variants
      // Get the first variant (usually highest quality)
      final variant = playlist.variants.first;
      final variantUrl = variant.url.toString();

      // Recursively get segments from the variant playlist
      return await _getM3U8Segments(variantUrl, headers);
    } else if (playlist is HlsMediaPlaylist) {
      // Media playlist contains the actual segments
      return (url, playlist.segments);
    } else {
      throw Exception('Unknown playlist type');
    }
  }

  Future<DownloadStatus> downloadInternal(
      int total, ExtensionService runtime, OfflineResource resource) async {
    var count = 0;
    for (var eps in resource.eps) {
      for (var item in eps.items) {
        if (_status == DownloadStatus.canceled) {
          return DownloadStatus.canceled;
        }
        while (status == DownloadStatus.paused ||
            status == DownloadStatus.queued) {
          await Future.delayed(Duration(seconds: 1));
        }
        _progress = count / total;

        final watchData =
            await runtime.watch(item.url) as ExtensionBangumiWatch;
        final curPath = await miruCreateFolderInTree(
            resource.path, [eps.subPath, item.subPath]);
        if (curPath == null) {
          logger.warning(
              'Failed to create directory: ${[eps.subPath, item.subPath]}');
          return DownloadStatus.failed;
        }
        String? mediaPath;
        try {
          final (playlistUrl, segments) =
              await _getM3U8Segments(watchData.url, watchData.headers ?? {});
          final segmentCount = segments.length;
          var maxDuration = Duration.zero;

          // 使用并发下载方法
          try {
            await _downloadSegments(
              playlistUrl: playlistUrl,
              segments: segments,
              curPath: curPath,
              headers: watchData.headers ?? {},
              onProgress: (downloadedCount) {
                // 当前分片组的进度 = 已完成分片数 / 总分片数
                final currentProgress = downloadedCount / segmentCount;
                // 总进度 = (已完成的分片组数 + 当前分片组进度) / 总分片组数
                _progress = (count + currentProgress) / total;
              },
              onSegmentDuration: (duration) {
                if (duration > maxDuration) {
                  maxDuration = duration;
                }
              },
            );
          } catch (e) {
            logger.warning('Failed to download segments', e);
            return DownloadStatus.failed;
          }

          // 生成m3u8文件
          final buffer = StringBuffer();
          buffer.writeln('#EXTM3U');
          buffer.writeln('#EXT-X-VERSION:3');
          buffer.writeln('#EXT-X-TARGETDURATION:${maxDuration.inSeconds}');
          buffer.writeln('#EXT-X-MEDIA-SEQUENCE:0');
          final existFiles = await miruListFolderFilesName(curPath);

          for (var (index, segment) in segments.indexed) {
            if (existFiles.contains('$index.ts')) {
              final segmentDuration =
                  Duration(microseconds: segment.durationUs ?? 0);
              buffer.writeln(
                  '#EXTINF:${segmentDuration.inSeconds.toStringAsFixed(3)},');
              buffer.writeln('$index.ts');
            }
          }

          buffer.writeln('#EXT-X-ENDLIST');
          mediaPath = await miruWriteFileBytes(curPath, '${item.title}.m3u8',
              Uint8List.fromList(buffer.toString().codeUnits), overwrite: true);
          if (mediaPath != null) {
            mediaPath = await miruGetActualPath(mediaPath);
          }
        } catch (e) {
          logger.warning('Failed to process playlist: ${watchData.url}', e);
          return DownloadStatus.failed;
        }

        final epTitle = eps.title;
        final itemTitle = item.title;
        final offlineResource = _detail?.offlineResource ?? {};
        offlineResource[epTitle] ??= {};
        offlineResource[epTitle]![itemTitle] = mediaPath ?? '';
        logger.info('Downloaded: $epTitle - $itemTitle, path: $mediaPath');
        if (_detail != null && mediaPath != null) {
          _detail!.offlineResource = offlineResource;
          await DatabaseService.updateMiruDetail(
              detailPackage!, detailUrl!, _detail!);
        }
        count++;
      }
    }

    while (status == DownloadStatus.paused || status == DownloadStatus.queued) {
      await Future.delayed(Duration(seconds: 1));
    }
    _progress = 1.0;
    return DownloadStatus.completed;
  }

  @override
  Future<DownloadStatus> download() async {
    try {
      var resource = _job.resource!;

      var total = 0;
      for (var ep in resource.eps) {
        total += ep.items.length;
      }
      if (total == 0) {
        _status = DownloadStatus.failed;
        return DownloadStatus.failed;
      }

      _status = DownloadStatus.downloading;
      _job.status = _status;

      final runtime = ExtensionUtils.runtimes[resource.package]!;
      _status = await downloadInternal(total, runtime, resource);
      _job.status = _status;
    } catch (e) {
      _status = DownloadStatus.failed;
      _job.status = _status;
      logger.warning('Download failed', e);
    }
    return _status;
  }

  @override
  Future<void> pause() async {
    if (deadStatus()) {
      return;
    }
    _status = DownloadStatus.paused;
    _job.status = _status;
  }

  @override
  Future<void> resume() async {
    if (deadStatus()) {
      return;
    }
    _status = DownloadStatus.downloading;
    _job.status = _status;
  }

  Future<void> _downloadSegment({
    required int index,
    required Segment segment,
    required String playlistUrl,
    required String curPath,
    required Map<String, String> headers,
  }) async {
    final fileName = '$index.ts';
    final segmentUri = segment.url;
    if (segmentUri == null) {
      logger.warning('Segment URL is null');
      return;
    }

    var retryCount = 0;
    final cancelToken = CancelToken();
    _activeDownloads['$index'] = cancelToken;

    while (retryCount < 5) {
      try {
        final parsedSegmentUri = Uri.parse(segmentUri);
        final url = parsedSegmentUri.hasScheme
            ? segmentUri
            : Uri.parse(playlistUrl).resolve(segmentUri).toString();

        logger.info('Downloading segment URL: $url');

        final response = await Dio().get(
          url,
          options: Options(
            responseType: ResponseType.bytes,
            headers: headers,
          ),
          cancelToken: cancelToken,
        );

        await miruWriteFileBytes(curPath, fileName, response.data);
        break;
      } catch (e) {
        if (e is DioException && e.type == DioExceptionType.cancel) {
          _activeDownloads.remove('$index');
          rethrow;
        }

        retryCount++;
        if (retryCount >= 5) {
          logger.warning(
              'Failed to download segment after 5 retries: $segmentUri', e);
          break;
        }
        logger.info('Retry $retryCount for segment: $segmentUri');
        await Future.delayed(Duration(seconds: 1));
      }
    }

    _activeDownloads.remove('$index');
  }

  Future<void> _downloadSegments({
    required String playlistUrl,
    required List<Segment> segments,
    required String curPath,
    required Map<String, String> headers,
    required Function(int) onProgress,
    required Function(Duration) onSegmentDuration,
  }) async {
    var downloadedCount = 0;
    final existFiles = await miruListFolderFilesName(curPath);

    for (var i = 0; i < segments.length; i += maxConcurrentDownloads) {
      // 检查是否取消
      if (_status == DownloadStatus.canceled) {
        // 取消所有活动下载
        for (final cancelToken in _activeDownloads.values) {
          cancelToken.cancel('Download canceled');
        }
        _activeDownloads.clear();
        return;
      }

      // 暂停时等待
      while (_status == DownloadStatus.paused) {
        await Future.delayed(Duration(seconds: 1));
      }

      final batch = segments.skip(i).take(maxConcurrentDownloads);
      final futures = <Future<void>>[];

      for (var (index, segment) in batch.indexed) {
        final segmentIndex = i + index;
        final fileName = '$segmentIndex.ts';

        // 检查文件是否已存在
        if (existFiles.contains(fileName)) {
          logger.info('Segment already exists: $fileName');
          downloadedCount++;
          onProgress(downloadedCount);
          onSegmentDuration(Duration(microseconds: segment.durationUs ?? 0));
          continue;
        }

        futures.add(_downloadSegment(
          index: segmentIndex,
          segment: segment,
          playlistUrl: playlistUrl,
          curPath: curPath,
          headers: headers,
        ).then((_) {
          downloadedCount++;
          onProgress(downloadedCount);
          onSegmentDuration(Duration(microseconds: segment.durationUs ?? 0));
        }));
      }

      if (futures.isNotEmpty) {
        await Future.wait(futures);
      }
    }
  }

  @override
  Future<void> cancel() async {
    if (deadStatus()) {
      return;
    }
    _status = DownloadStatus.canceled;
    _job.status = _status;

    // 取消所有活动的下载
    for (final cancelToken in _activeDownloads.values) {
      cancelToken.cancel('Download canceled');
    }
    _activeDownloads.clear();
  }

  @override
  DownloadJob get downloadJob => _job;

  @override
  void releaseResource() {
    _job.setResourceToNull();
  }

  @override
  String get name => _name;

  @override
  String get url => _url;

  @override
  bool get isPaused => _status == DownloadStatus.paused;

  @override
  bool get isDownloading => _status == DownloadStatus.downloading;

  @override
  bool get isQueued => _status == DownloadStatus.queued;

  @override
  bool get isComplete => _status == DownloadStatus.completed;

  @override
  bool get isCanceled => _status == DownloadStatus.canceled;

  @override
  bool get isFailed => _status == DownloadStatus.failed;
}
