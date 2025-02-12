import 'dart:io';
import 'package:miru_app/utils/log.dart';
import 'package:path/path.dart' as p;
import 'package:saf_stream/saf_stream.dart';
import 'package:saf_util/saf_util.dart';
import 'package:uri_to_file/uri_to_file.dart';
import 'package:flutter/services.dart';

final _saf = SafStream();
final _safUtils = SafUtil();

String sanitizeFileName(String fileName) {
  // 移除或替换不允许的字符
  return fileName
      .replaceAll(RegExp(r'[<>:"/\\|?*]'), '') // Windows非法字符
      .replaceAll(RegExp(r'[\x00-\x1F]'), '') // 控制字符
      .replaceAll(RegExp(r'\s+'), ' ') // 多个空格替换为单个
      .trim(); // 移除首尾空格
}

/// 获取文件夹中所有文件的路径，并按文件名中的《数字部分》排序
/// 注意这是数字部分，而不是文件名中的数字字符
/// [directoryPath] 文件夹路径
/// [ascending] 是否按升序排序（默认为 true，升序；false 为降序）
Future<List<String>> getSortedFiles(String directoryPath,
    {bool ascending = true}) async {
  /// 从文件名中提取数字部分
  int extractNumber(String fileName) {
    // 使用正则表达式匹配文件名开头的数字部分
    RegExp regExp = RegExp(r'^(\d+)');
    Match? match = regExp.firstMatch(fileName);

    if (match != null) {
      // 提取匹配的数字部分并转换为整数
      return int.parse(match.group(1)!);
    }

    // 如果文件名中没有数字部分，返回 0（或其他默认值）
    return 0;
  }

  if (!Platform.isAndroid) {
    // 获取文件夹
    Directory directory = Directory(directoryPath);

    // 检查文件夹是否存在
    if (!await directory.exists()) {
      throw Exception('文件夹不存在: $directoryPath');
    }

    // 列出文件夹中的所有内容
    List<FileSystemEntity> entities = directory.listSync();

    // 过滤出文件（排除文件夹）
    List<File> files = entities.whereType<File>().toList();

    // 按文件名中的数字部分排序
    files.sort((a, b) {
      // 提取文件名中的数字部分
      int numA = extractNumber(a.uri.pathSegments.last);
      int numB = extractNumber(b.uri.pathSegments.last);

      // 根据 ascending 参数决定排序顺序
      return ascending ? numA.compareTo(numB) : numB.compareTo(numA);
    });

    // 返回文件的路径列表
    return files.map((file) => file.path).toList();
  } else {
    final childDocs = await _safUtils.list(directoryPath);
    // 过滤出文件（排除文件夹）
    final files = childDocs.where((doc) => !doc.isDir).toList();
    files.sort((a, b) {
      final numA = extractNumber(a.name);
      final numB = extractNumber(b.name);
      return ascending ? numA.compareTo(numB) : numB.compareTo(numA);
    });
    final temp = childDocs.map((doc) => doc.uri.toString()).toList();
    logger.info('getSortedFiles: len: ${temp.length} $temp');
    return temp;
  }
}

Future<String?> miruPickDir(
    {bool writePermission = true, bool persistablePermission = true}) async {
  assert(Platform.isAndroid);
  final res = await _safUtils.pickDirectory(
      writePermission: writePermission,
      persistablePermission: persistablePermission);
  return res?.uri.toString();
}

// 需要在ui界面显示后调用
Future<String?> miruCreateFolder(String folder, {bool recursive = true}) async {
  try {
    if (Directory(folder).existsSync()) {
      return folder;
    }
    Directory(folder).createSync(recursive: recursive);
    return folder;
  } catch (e) {
    logger.warning('miruCreateFolder error: $e');
    return null;
  }
}

Future<String?> miruCreateFolderInTree(
    String treePath, List<String> folder) async {
  // 默认递归的创建文件夹
  // folder参数：['Miru', 'temp']，则会递归创建treePath/Miru/temp文件夹
  try {
    final subPath = folder.join('/');
    final path = p.join(treePath, subPath);
    logger.info('miruCreateFolderInTree path: $path');
    if (!Platform.isAndroid) {
      if (Directory(path).existsSync()) {
        return path;
      }
      Directory(path).createSync(recursive: true);
      return path;
    } else {
      // 使用SAF对安卓文件进行读写
      // 在安卓中使用uri
      final res = await _safUtils.mkdirp(treePath, folder);
      logger.info('uri: ${res.uri}');
      return res.uri.toString();
    }
  } catch (e) {
    logger.warning('miruCreateFolderInTree error: $e');
    return null;
  }
}

// 需要在ui界面显示后调用
Future<String?> miruCreateEmptyFile(String treePath, String fileName,
    {bool overwrite = false}) async {
  try {
    final path = p.join(treePath, fileName);
    if (!Platform.isAndroid) {
      if (File(path).existsSync()) {
        return path;
      }
      File(path).createSync(recursive: true);
      return path;
    } else {
      // 使用SAF对安卓文件进行读写
      // 在安卓中使用uri
      final isExist = await miruFileExist(treePath, fileName);
      if (isExist && !overwrite) {
        final file = await _safUtils.child(treePath, [fileName]);
        if (file != null && !file.isDir) {
          return file.uri.toString();
        } else {
          logger.warning('miruCreateEmptyFile: file is null');
          return null;
        }
      }
      final res = await _saf.writeFileBytes(
          treePath, fileName, 'application/octet-stream', Uint8List(0),
          overwrite: overwrite);
      logger.info('uri: ${res.uri}');
      return res.uri.toString();
    }
  } catch (e) {
    logger.warning('miruCreateFile error: $e');
    return null;
  }
}

Future<Uint8List> miruReadFileBytes(String path) async {
  // 用于读取外部文件（特指安卓/苹果）
  // 返回字节流
  if (!Platform.isAndroid) {
    return File(path).readAsBytesSync();
  } else {
    return _saf.readFileBytes(path);
  }
}

Future<File> miruGetFile(String path) async {
  if (!Platform.isAndroid) {
    return File(path);
  } else {
    return await toFile(path);
  }
}

Future<bool> miruFileExist(String treePath, String fileName) async {
  final path = p.join(treePath, fileName);
  try {
    if (!Platform.isAndroid) {
      return File(path).existsSync();
    } else {
      final fileList = await _safUtils.child(treePath, [fileName]);
      if (fileList != null) {
        return true;
      }
      return false;
    }
  } catch (e) {
    logger.warning('miruFileExist: $e');
    return false;
  }
}

Future<String?> miruWriteFileBytes(
    String treePath, String fileName, Uint8List bytes,
    {bool overwrite = false}) async {
  final path = p.join(treePath, fileName);
  // 用于写入外部文件（特指安卓/苹果）
  if (!Platform.isAndroid) {
    File(path).writeAsBytesSync(bytes);
    return path;
  } else {
    try {
      final fileList = await _safUtils.child(treePath, [fileName]);
      if (fileList != null && !overwrite) {
        final file = await _safUtils.child(treePath, [fileName]);
        if (file != null && !file.isDir) {
          return file.uri.toString();
        } else {
          logger.warning('miruWriteFileBytes: file is null');
          return null;
        }
      }
      final res = await _saf.writeFileBytes(
          treePath, fileName, 'application/octet-stream', bytes,
          overwrite: overwrite);
      return res.uri.toString();
    } catch (e) {
      logger.warning('miruWriteFileBytes error: $e');
      return null;
    }
  }
}

(String, String) miruSplitPath(String path) {
  final split = p.split(path);
  return (p.joinAll(split.sublist(0, split.length - 1)), split.last);
}

Future<String?> getPathFromUri(String uri) async {
  const platform = MethodChannel('UTILS'); // 定义一个唯一的通道名称
  final String? path =
      await platform.invokeMethod('getPathFromUri', {'uri': uri});
  return path;
}

Future<bool> miruCheckUriPersisted(String uri) async {
  assert(Platform.isAndroid);
  try {
    const platform = MethodChannel('UTILS');
    return await platform.invokeMethod('checkUriPersisted', {'uri': uri});
  } catch (e) {
    logger.warning('miruCheckPersisted error: $e');
    return false;
  }
}

Future<String?> miruGetActualPath(String path) async {
  if (Platform.isAndroid) {
    // 如果传入的uri不是一个有效的uri（运行中创建或者持久的），会造成难以理解的问题
    try {
      return await getPathFromUri(path);
    } catch (e) {
      logger.warning('getActualFolderPath error: $e');
      return null;
    }
  } else {
    return path;
  }
}

Future<List<String>> miruListFolderFilesName(String treePath) async {
  try {
    if (!Platform.isAndroid) {
      return Directory(treePath)
          .listSync()
          .whereType<File>()
          .map((f) => p.basename(f.path))
          .toList();
    } else {
      return (await _safUtils.list(treePath))
          .where((elem) => !elem.isDir)
          .map((f) => f.name)
          .toList();
    }
  } catch (e) {
    logger.info('miruListFolderFilesName error: $e');
    return [];
  }
}
