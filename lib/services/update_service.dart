import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class UpdateInfo {
  final String version;
  final int versionCode;
  final String url;
  final String notes;

  const UpdateInfo({
    required this.version,
    required this.versionCode,
    required this.url,
    required this.notes,
  });

  factory UpdateInfo.fromJson(Map<String, dynamic> json) {
    return UpdateInfo(
      version: json['version'] as String,
      versionCode: json['versionCode'] as int,
      url: json['url'] as String,
      notes: (json['notes'] as String?) ?? '',
    );
  }
}

typedef ProgressCallback = void Function(double progress);

class UpdateService {
  static const _key = 'jianyan_update_url';

  /// 保存自定义服务器地址。
  static Future<void> saveBaseUrl(String url) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$_key.json');
    await file.writeAsString(jsonEncode({'url': url}));
  }

  /// 读取自定义服务器地址。
  static Future<String> getBaseUrl() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$_key.json');
      if (await file.exists()) {
        final m = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
        return m['url'] as String;
      }
    } catch (_) {}
    return '';
  }

  /// 检查是否有新版本。
  /// 返回 `(UpdateInfo?, String?)` — info 有值就表示有新版本，error 有值表示失败原因。
  static Future<(UpdateInfo?, String?)> checkUpdate() async {
    try {
      final baseUrl = await getBaseUrl();
      if (baseUrl.isEmpty) {
        return (null, '尚未配置更新服务器地址');
      }

      final info = await PackageInfo.fromPlatform();
      final currentCode = int.tryParse(info.buildNumber) ?? 1;

      final uri = Uri.parse('$baseUrl/version.json');
      final res = await http.get(uri).timeout(const Duration(seconds: 8));

      if (res.statusCode != 200) {
        return (null, '服务器返回错误: ${res.statusCode}');
      }

      final data = json.decode(res.body) as Map<String, dynamic>;
      final update = UpdateInfo.fromJson(data);

      if (update.versionCode > currentCode) {
        return (update, null);
      }
      return (null, null); // 无新版本
    } catch (e) {
      debugPrint('检查更新失败: $e');
      return (null, '网络连接失败，请检查服务器地址和网络');
    }
  }

  static Future<String> downloadApk(String url, ProgressCallback onProgress) async {
    final dir = await getApplicationDocumentsDirectory();
    final filePath = p.join(dir.path, 'update.apk');

    final client = http.Client();
    try {
      final request = http.Request('GET', Uri.parse(url));
      final response = await client.send(request);

      final total = response.contentLength ?? 0;
      var received = 0;
      final file = File(filePath);
      final sink = file.openWrite();

      await for (final chunk in response.stream) {
        sink.add(chunk);
        received += chunk.length;
        if (total > 0) onProgress(received / total);
      }

      await sink.close();
      return filePath;
    } finally {
      client.close();
    }
  }

  static Future<void> installApk(String filePath) async {
    await OpenFilex.open(filePath, type: 'application/vnd.android.package-archive');
  }

  static Future<String> currentVersion() async {
    final info = await PackageInfo.fromPlatform();
    return '${info.version} (${info.buildNumber})';
  }
}
