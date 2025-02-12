import 'dart:convert';

import 'package:isar/isar.dart';

part 'miru_detail.g.dart';

@collection
class MiruDetail {
  Id id = Isar.autoIncrement;
  @Index(name: 'package&url', composite: [CompositeIndex('url')])
  late String package;
  late String url;
  late String data;
  int? tmdbID;
  DateTime updateTime = DateTime.now();
  String? aniListID;
  String offlineResourceJson = '{}';

  @ignore
  Map<String, Map<String, String>> get offlineResource {
    return deserializeOfflineResource(offlineResourceJson);
  }

  set offlineResource(Map<String, Map<String, String>> value) {
    offlineResourceJson = serializeOfflineResource(value);
  }

  String serializeOfflineResource(
      Map<String, Map<String, String>> offlineResource) {
    return jsonEncode(offlineResource);
  }

  Map<String, Map<String, String>> deserializeOfflineResource(
      String jsonString) {
    return Map<String, Map<String, String>>.from(
      jsonDecode(jsonString).map(
        (key, value) => MapEntry(key, Map<String, String>.from(value)),
      ),
    );
  }
}
